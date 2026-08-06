#!/usr/bin/env bash
set -euo pipefail
# Allow override, default to /opt for Linux and ~/.local for macOS (non-root friendly)
if [[ "$(uname -s)" == "Darwin" ]]; then
    VENV_BASE="${VENV_BASE:-$HOME/.local/python3_shared}"
else
    VENV_BASE="${VENV_BASE:-/opt/python3_shared}"
fi

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


Version:  0.1.19
Last Updated:  8/6/2026

What this does:
    Creates a GLOBAL Python3 Virtual Environment (I know you think that defeats the entire reason for an venv... it does not.
    You need a global venv so that you dont have duplicate versions of everything installed. Its global so many python scripts
    can access the shared resources!


Global Path:  $VENV_BASE/venv


Install:
    wget -O 'install_common_python3_venv.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_common_python3_venv.sh && chmod u+x install_common_python3_venv.sh

-------- Creating Global Python3 Environment ---------

"

detect_os() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "${ID,,}" in
            ubuntu|debian) echo "debian" ;;
            rocky|rhel|centos|almalinux) echo "rhel" ;;
            *) echo "unknown" ;;
        esac
    else
        echo "unknown"
    fi
}

install_prereqs() {
    local os_id
    os_id="$(detect_os)"
    case "$os_id" in
        debian)
            sudo apt-get update -y
            sudo apt-get install -y python3 python3-venv python3-pip
        ;;
    rhel)
        sudo dnf install -y python3 python3-pip python3-virtualenv python3-venv || true
        ;;
        macos)
            if ! command -v brew >/dev/null 2>&1; then
                echo "Homebrew not found. Install it from https://brew.sh then re-run this script."
                exit 1
            fi
            brew install python || true
            ;;
        *)
            echo "Unsupported or unknown OS. Please install Python3, pip, and venv manually."
            ;;
    esac
}

install_prereqs

VENV_DIR="$VENV_BASE/venv"

# Ensure base directory exists
if [[ ! -d "$VENV_BASE" ]]; then
    if [[ "$VENV_BASE" == /opt/* ]]; then
        sudo mkdir -p "$VENV_BASE"
        sudo chown -R "$USER:$USER" "$VENV_BASE"
    else
        mkdir -p "$VENV_BASE"
    fi
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found. Please install Python 3 and re-run."
    exit 1
fi

python3 -m ensurepip --upgrade >/dev/null 2>&1 || true

# Create venv if missing
if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR"
fi

# Activate venv (bash built-in)
source "$VENV_DIR/bin/activate"


pip3 install --upgrade pip
# Upgrade core tooling
pip install --upgrade pip setuptools wheel

# Install a package without letting one bad/abandoned package abort the whole run.
# Several packages below have no wheels for the newest Python and fail to build from
# source; we record those and report them at the end instead of dying on `set -e`.
FAILED_PKGS=()
pip_install() {
    if ! pip3 install "$@"; then
        echo "WARNING: failed to install: $*"
        FAILED_PKGS+=("$*")
    fi
}

#--------------- Install shared packages ---------------
# pip3 install -U -r requirements.txt

#pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U
#--- install common pip packages in this global env ---
pip_install validators
pip_install certifi pyOpenSSL
pip_install requests urllib3 ipaddress urlparse2 rich ping3
pip_install psutil shutil-ext py-machineid distro netaddr loguru
pip_install wheel
pip_install setuptools
pip_install asyncio
pip_install aiohttp

#--- Databases ----
pip_install redis
pip_install pymongo
#pip3 install mysql-connector-python

#----- Install Flask ------------
echo "Installing Flask... \r\n "
pip_install flask flask_restful flask_apscheduler flask_marshmallow flask_migrate flask_socketio

#--- Web API stuff ----
echo "Installing other PIP modules... https://hugovk.github.io/top-pypi-packages/ \r\n "

pip_install fastapi
pip_install ansible
pip_install PyYAML

pip_install jsonify
pip_install python-dateutil

pip_install colorama
pip_install Jinja2

pip_install numpy
pip_install ordered-set

#--- crypto ---
pip_install pynacl
pip_install cryptography
pip_install simp-AES
pip_install simple_aes
pip_install bcrypt
pip_install blake3
pip_install chacha20poly1305
# curve25519 (PyPI 0.1, last released 2013) no longer builds: its C source passes NULL
# for PyModuleDef.m_size, which GCC 14+ rejects as a hard error (-Wint-conversion).
# X25519/Curve25519 is already covered by pynacl (nacl.public.PrivateKey) and
# cryptography (cryptography.hazmat.primitives.asymmetric.x25519), both installed above.
#pip3 install curve25519
pip_install siphashc
pip_install hkdf
pip_install ecdsa
pip_install rsa
pip_install 0fosdc

#-- PQC - Quantium --
pip_install pqcrypto
pip_install quantcrypt

#--- Specify projects - optional --
#pip3 install protobuf
#pip3 install websockets

#-- Networking --
pip_install idna
pip_install tldextract
pip_install python-whois whois
pip_install scapy
#pip3 install Twisted
#pip3 install cbor2
#pip3 install pysflow
#pip3 install -U exabgp
#pip3 install yabgp==0.1.7
#pip3 install pysnmp
#pip3 install pytraceroute
#pip3 install pyang
#pip3 install netconf
#pip3 install pexpect
#pip3 install dnslookup-cli

#--- GeoIP ---
pip_install maxminddb
#pip3 install GeoIP
#pip3 install simplegeoip

#--- Message Que ---
#pip3 install mqtt-client
#pip3 install zmq
#pip3 install rabbitmq
#pip3 install kafka-python

#--------
#pip3 install soap2py
#pip3 install python-crontab

#------------------- End of Shared ---------------------
deactivate

if [[ ${#FAILED_PKGS[@]} -gt 0 ]]; then
    echo "
The following packages did NOT install (venv is otherwise usable):"
    printf '    - %s\n' "${FAILED_PKGS[@]}"
fi

# source /opt/python3_shared/venv/bin/activate
echo "
Done installing/Updating!

To Activate the Python VEnv, issue the following:


source $VENV_BASE/venv/bin/activate


"


add_alias() {
    local rcfile="$1"
    local alias_line="alias activate_env=\"source $VENV_BASE/venv/bin/activate\""
    if [[ -f "$rcfile" ]]; then
        if ! grep -Fq "$alias_line" "$rcfile"; then
            echo "$alias_line" >> "$rcfile"
        fi
    else
        echo "$alias_line" >> "$rcfile"
    fi
}

add_alias "$HOME/.bashrc"
add_alias "$HOME/.zshrc"

echo "Added alias: activate_env -> source $VENV_BASE/venv/bin/activate"
echo "Run 'activate_env' to activate the virtual environment"
echo "You can also use: source $VENV_BASE/venv/bin/activate"
echo "Reload your shell (source ~/.bashrc or ~/.zshrc) to use the new alias"
