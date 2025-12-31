#!/usr/bin/env bash
#set -e
set -euo pipefail
VENV_BASE="/opt/python3_shared"

echo "


 _____             _         _    _          _
|     |___ ___ ___| |_ ___ _| |  | |_ _ _   |_|
|   --|  _| -_| .'|  _| -_| . |  | . | | |   _
|_____|_| |___|__,|_| |___|___|  |___|_  |  |_|
                                     |___|

 _____ _       _     _           _              _____    __    _____
|     | |_ ___|_|___| |_ ___ ___| |_ ___ ___   |     |__|  |  |   __|___ ___ _ _
|   --|   |  _| |_ -|  _| . | . |   | -_|  _|  | | | |  |  |  |  |  |  _| .'| | |
|_____|_|_|_| |_|___|_| |___|  _|_|_|___|_|    |_|_|_|_____|  |_____|_| |__,|_  |
                            |_|                                             |___|


Version:  0.0.5
Last Updated:  12/31/2025

What this does:
    Creates a GLOBAL Python3 Virtual Environment (I know you think that defeats the entire reason for an venv... it does not. 
    You need a global venv so that you dont have duplicate versions of everything installed. Its global so many python scripts 
    can access the shared resources!


Global Path:  $VENV_BASE/venv


Install:
    rm install_ai.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai.sh && chmod u+x install_ai.sh

"

VENV_DIR="$VENV_BASE/venv"

# Create venv if it doesn't exist
if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR"
fi

# Ensure base directory exists
if [[ ! -d "$VENV_BASE" ]]; then
    sudo mkdir -p "$VENV_BASE"
    sudo chown -R "$USER:$USER" "$VENV_BASE"
fi

# Create venv if missing
if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR"
fi

# Activate venv (bash built-in)
source "$VENV_DIR/bin/activate"

# Upgrade core tooling
pip install --upgrade pip setuptools wheel


#--------------- Install shared packages ---------------
pip install \
    requests \
    flask \
    redis




#------------------- End of Shared ---------------------

# Deactivate cleanly
deactivate
