# RLBotNimExample
Example of a nim bot using the RLBot framework, an intermediary python bot and a tiny library for accessing game data through a socket 

## Quick Start
Follow this guide to install RLBotGUI, and then clone this code into your desired folder, and inside the GUI, press the + button, load cgf file, and select PythonBridge/src/bot.cfg.
https://youtu.be/YJ69QZ-EX7k

It shows you how to:
- Install the RLBot GUI
- Use it to create a new bot

## Changing the bot

- Bot behavior is controlled by `Nimbot.nim` (I encourage you to move your bot logic to a separate file, and then call those functions from your bot file, but its not neccesary)
- Bot appearance is controlled by `PythonBridge/src/appearance.cfg`

See https://github.com/RLBot/RLBotNimExample/wiki for documentation and tutorials.

### Older Setup Technique

**Please don't do this unless you've followed the quick start video and it doesn't work!**

https://www.youtube.com/watch?v=UjsQFNN0nSA

1. Make sure you've installed [Python 3.7 64 bit](https://www.python.org/ftp/python/3.7.4/python-3.7.4-amd64.exe). During installation:
   - Select "Add Python to PATH"
   - Make sure pip is included in the installation
1. Download or clone this repository
1. In the files from the previous step, find and double click on run-gui.bat
1. Click the 'Run' button