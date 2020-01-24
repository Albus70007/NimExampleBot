import os
import time
import math
import socket
import json
import struct
import subprocess
import psutil

from rlbot.agents.base_agent import BaseAgent, SimpleControllerState, BOT_CONFIG_AGENT_HEADER
from rlbot.botmanager.helper_process_request import HelperProcessRequest

from rlbot.agents.executable_with_socket_agent import ExecutableWithSocketAgent
from rlbot.utils.structures.game_data_struct import GameTickPacket

from util.orientation import Orientation
from util.vec import Vec3


# EDITIED THE PYTHON EXAMPLE BOT SO THAT IT SENDS AND RECEIVES 
# INPUTS AND OUTPUTS THROUGH A SOCKET
# (Tarehart made automatically running your executable possible, 
# credits to him)
class GameBridge(BaseAgent):

    def __init__(self, name, team, index):
        super().__init__(name, team, index)
        self.port = 8077
        self.is_retired = False

    def load_config(self, config_header):
        self.executable_path = config_header.getpath('executable_path')
        self.logger.info("Bot executable is configured as {}".format(self.executable_path))

    @staticmethod
    def create_agent_configurations(config):
        params = config.get_header(BOT_CONFIG_AGENT_HEADER)
        params.add_value('executable_path', str, default=None,
                         description='Relative path to the executable that runs the bot.')

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
        self.frame = 0
        self.socket = socket.socket()
        self.socket.bind(("localhost", self.port))
        self.socket.listen(1)
        self.client, address = self.socket.accept()
        print("listening for connections if port: ", str(self.port))
        
    def get_port(self):
        return self.port

    def get_output(self, packet: GameTickPacket) -> SimpleControllerState:
        ball_location = Vec3(packet.game_ball.physics.location)

        my_car = packet.game_cars[self.index]
        car_location = Vec3(my_car.physics.location)

        car_to_ball = ball_location - car_location

        # Find the direction of our car using the Orientation class
        car_orientation = Orientation(my_car.physics.rotation)
        car_direction = car_orientation.forward

        teamSign = 1 if self.team == 0 else -1
        enemyGoal = Vec3(0.0, 5120.0 * teamSign, 0.0)
        
        self.send_game_data(self.client, packet)
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

        ballGoalVector = (teamSign * ball_location, enemyGoal)

        draw_debug(self.renderer, my_car, packet.game_ball, ballGoalVector, "idk")
        self.frame += 1
        return self.controller_state

    def send_game_data(self, socket, packet):
        message = self.get_game_data(packet)
        header = struct.pack("H",len(json.dumps(message).encode('ascii')))
        socket.sendall(header)
        socket.sendall(json.dumps(message).encode('ascii'))

    def get_game_data(self, packet):
        return self.packetGenerator(packet)

    def recieveController(self, socket):
        header = struct.unpack("H", socket.recv(2))[0]
        received = socket.recv(header)
        controler = json.loads(received,encoding='ascii')
        return controler
 
    def car_packetGenerator(self, packet):
        all_cars = []
        for car in packet.game_cars[:packet.num_cars]:
                all_cars.append({
                    "position": [
                        car.physics.location.x,
                        car.physics.location.y,
                        car.physics.location.z
                    ],
                    "velocity": [
                        car.physics.velocity.x,
                        car.physics.velocity.y,
                        car.physics.velocity.z 
                    ],
                    "euler_angles": [
                        car.physics.rotation.yaw,
                        car.physics.rotation.pitch,
                        car.physics.rotation.roll
                    ],
                    "angular_velocity": [
                        car.physics.angular_velocity.x,
                        car.physics.angular_velocity.y,
                        car.physics.angular_velocity.z
                    ],
                    "boost": car.boost,
                    "on_ground": car.has_wheel_contact,
                    "jumped": car.jumped,
                    "double_jumped": car.double_jumped,
                    "demolished": car.is_demolished,
                    "is_bot": car.is_bot,
                    "team": car.team,
                    "name": car.name,
                    "body_type": car.spawn_id,
                    "hitbox_offset": [
                        car.hitbox_offset.x,
                        car.hitbox_offset.y,
                        car.hitbox_offset.z
                    ],
                    "hitbox_dimensions": [
                        car.hitbox.length,
                        car.hitbox.width,
                        car.hitbox.height
                    ]
                })
        return all_cars

    def packetGenerator(self, packet):
        gamePacket =[{
            "frame": self.frame,
            "index": self.index,
            "score": [
                packet.teams[0].score,
                packet.teams[1].score
            ],
            "ball": {
                "position": [
                    packet.game_ball.physics.location.x,
                    packet.game_ball.physics.location.y,
                    packet.game_ball.physics.location.z
                ],
                "velocity": [
                    packet.game_ball.physics.velocity.x,
                    packet.game_ball.physics.velocity.y,
                    packet.game_ball.physics.velocity.z
                ],
                "euler_angles": [
                    packet.game_ball.physics.rotation.yaw,
                    packet.game_ball.physics.rotation.pitch,
                    packet.game_ball.physics.rotation.roll
                ],
                "angular_velocity": [
                    packet.game_ball.physics.angular_velocity.x,
                    packet.game_ball.physics.angular_velocity.y,
                    packet.game_ball.physics.angular_velocity.z
                ],
                "damage": 0.0,
                "shape": packet.game_ball.collision_shape.type,
                "radius": -92.0,
                "height": -1.0
            },
            "cars": self.car_packetGenerator(packet),
            "goals": [
                {
                    "position": [
                        0.0,
                        0.0,
                        0.0
                    ],
                    "direction": [
                        0.0,
                        0.0,
                        0.0
                    ],
                    "width": 0.0,
                    "height": 0.0,
                    "team": 0,
                    "state": 0
                },
                {
                    "position": [
                        0.0,
                        0.0,
                        0.0
                    ],
                    "direction": [
                        0.0,
                        0.0,
                        0.0
                    ],
                    "width": 0.0,
                    "height": 0.0,
                    "team": 0,
                    "state": 0
                }
            ],
            "pads": [
                {
                    "position": [
                        0.0,
                        0.0,
                        0.0
                    ],
                    "type": 0,
                    "available": False
                },
                {
                    "position": [
                        0.0,
                        0.0,
                        0.0
                    ],
                    "type": 0,
                    "available": False
                }
            ],
            "time_left": packet.game_info.game_time_remaining,
            "time_elapsed": packet.game_info.seconds_elapsed,
            "is_overtime": packet.game_info.is_overtime,
            "is_round_active": packet.game_info.is_round_active,
            "is_kickoff_paused": packet.game_info.is_kickoff_pause,
            "is_match_ended": packet.game_info.is_match_ended,
            "is_unlimited_time": packet.game_info.is_unlimited_time,
            "gravity": -0.0,
            "map": 32758,
            "type": 0
        }]
        return gamePacket

def find_correction(current: Vec3, ideal: Vec3) -> float:
    # Finds the angle from current to ideal vector in the xy-plane. Angle will be between -pi and +pi.

    # The in-game axes are left handed, so use -x
    current_in_radians = math.atan2(current.y, -current.x)
    ideal_in_radians = math.atan2(ideal.y, -ideal.x)

    diff = ideal_in_radians - current_in_radians

    # Make sure that diff is between -pi and +pi.
    if abs(diff) > math.pi:
        if diff < 0:
            diff += 2 * math.pi
        else:
            diff -= 2 * math.pi

    return diff


def draw_debug(renderer, car, ball, vector, action_display):
    renderer.begin_rendering()
    # draw a line from the car to the ball
    renderer.draw_line_3d(car.physics.location, ball.physics.location, renderer.white())
    renderer.draw_line_3d(vector[0], vector[1], renderer.white())
    # print the action that the bot is taking
    renderer.draw_string_3d(car.physics.location, 2, 2, action_display, renderer.white())
    renderer.end_rendering()
