import os
import time
import math
import socket
import json
import msgpack
import struct
import subprocess
import psutil

from ctypes import *

from rlbot.agents.base_agent import BaseAgent, SimpleControllerState, BOT_CONFIG_AGENT_HEADER
from rlbot.botmanager.helper_process_request import HelperProcessRequest

from rlbot.agents.executable_with_socket_agent import ExecutableWithSocketAgent
from rlbot.utils.structures.game_data_struct import GameTickPacket, rotate_game_tick_packet_boost_omitted
from rlbot.utils.structures.ball_prediction_struct import BallPrediction

from util.orientation import Orientation
from util.vec import Vec3


current_dir = os.path.dirname(os.path.realpath(__file__))
Nim = CDLL(os.path.join(current_dir, "RLInterface.dll"))

class Returning(Structure):
    _fields_ = [("one", c_char_p),
                ("two", c_char_p)]

class GameInformation(Structure):
    _fields_ = [("packet", GameTickPacket),
                ("ballPrediction", BallPrediction)]

class NimStrPayload(Structure):
    _fields_ = [("cap", c_int),
                ("data", c_char_p)]

class NimString(Structure):
    _fields_ = [("len", c_int),
                ("p", POINTER(NimStrPayload))]
        
Nim.packPacket.argtypes = [POINTER(c_char * sizeof(GameInformation)), GameInformation]
Nim.packPacket.restype = None #c_char * sizeof(GameInformation)
ppacket = create_string_buffer(sizeof(GameInformation))

# EDITIED THE PYTHON EXAMPLE BOT SO THAT IT SENDS AND RECEIVES 
# INPUTS AND OUTPUTS THROUGH A SOCKET
# (Tarehart made automatically running your executable possible, 
# credits to him)
class GameBridge(BaseAgent):
    def __init__(self, name, team, index):
        super().__init__(name, team, index)
        print(index)
        self.is_retired = False

    def load_config(self, config_header):
        self.executable_path = config_header.getpath('executable_path')
        self.port = int(open(config_header.getpath('port_path'), "r").readline())
        self.logger.info("Bot executable is configured as {}".format(self.executable_path))

    @staticmethod
    def create_agent_configurations(config):
        params = config.get_header(BOT_CONFIG_AGENT_HEADER)
        params.add_value('executable_path', str, default=None,
                         description='Relative path to the executable that runs the bot.')
        params.add_value('port_path', str, default=None,
                         description='Relative path to the file that holds the port to conect.')

    def is_executable_configured(self):
        return self.executable_path is not None and os.path.isfile(self.executable_path)

    def get_helper_process_request(self):
        if self.is_executable_configured():
            return HelperProcessRequest(python_file_path=None, key=__file__ + str(self.get_port()),
                                        executable=self.executable_path, exe_args=[str(self.get_port())],
                                        current_working_directory=os.path.dirname(self.executable_path))
        return None

    def retire(self):
        self.is_retired = True

    def get_extra_pids(self):
        """
        Gets the list of process ids that should be marked as high priority.
        :return: A list of process ids that are used by this bot in addition to the ones inside the python process.
        """
        while not self.is_retired:
            for proc in psutil.process_iter():
                for conn in proc.connections():
                    if conn.laddr.port == self.get_port():
                        self.logger.debug(f'server for {self.name} appears to have pid {proc.pid}')
                        return [proc.pid]
            if self.is_executable_configured():
                # The helper process will start the exe and report the PID. Nothing to do here.
                return []
            time.sleep(1)
            if self.executable_path is None:
                self.logger.info(
                    "Can't auto-start because no executable is configured. Please start manually!")
            else:
                self.logger.info(f"Can't auto-start because {self.executable_path} is not found. "
                                 "Please start manually!")

    def initialize_agent(self):
        # This runs once before the bot starts up
        self.controller_state = SimpleControllerState()
        self.socket = socket.socket()
        self.socket.bind(("localhost", self.port))
        self.socket.listen(1)
        self.client, address = self.socket.accept()
        # print(" listening for connections if port: ", str(self.port))
        self.client.recv(1024)
        message = ("index:" + str(self.index) + ", team:" + str(self.team)).encode('ascii')
        print(message)
        self.client.sendall(message)

    def get_port(self):
        return self.port

    def get_output(self, packet: GameTickPacket) -> SimpleControllerState:
        if self.team == 1:
            rotate_game_tick_packet_boost_omitted(packet)
        Nim.packPacket(pointer(ppacket), GameInformation(packet, self.get_ball_prediction_struct()))
        self.client.sendall(ppacket)
        inputs = self.recieveController(self.client)
        self.controller_state.throttle = inputs["throttle"]
        self.controller_state.steer = inputs["steer"]
        self.controller_state.boost = inputs["boost"]
        self.controller_state.jump = inputs["jump"]
        self.controller_state.yaw = inputs["yaw"]
        self.controller_state.pitch = inputs["pitch"]
        self.controller_state.roll = inputs["roll"]
        self.controller_state.handbrake = inputs["handbrake"]
        self.controller_state.use_item = inputs["use_item"]
        #draw_debug(self.renderer, my_car, Vec3(inputs["botstate"]["x"], inputs["botstate"]["y"], inputs["botstate"]["z"]), ballGoalVector, "SUP")
        return self.controller_state

    def send_game_data(self, socket, packet):
        header = struct.pack("I",len(str(packet)))
        socket.sendall(header)
        socket.sendall(str(packet).encode("utf-8"))

    def recieveController(self, socket):
        header = struct.unpack("H", socket.recv(2))[0]
        received = socket.recv(header)
        controler = json.loads(received,encoding='ascii')
        return controler[0]

"""
def draw_debug(renderer, car, ball, vector, action_display):
    renderer.begin_rendering()
    # draw a line from the car to the ball
    renderer.draw_line_3d(car.physics.location, ball, renderer.white())
    renderer.draw_line_3d(vector[0], vector[1], renderer.white())
    # print the action that the bot is taking
    renderer.draw_string_3d(car.physics.location, 2, 2, action_display, renderer.white())
    renderer.end_rendering()
"""