#!/usr/bin/env bash
############################################################ /ᐠ｡ꞈ｡ᐟ\############################################################
#Developed by: Tal Mendelson
#Purpose: Script to demonstrate Ansible's copy and shell module usage per ansible playbook practice task - Ansible Shallow Dive
#         from https://gitlab.com/vaiolabs-io/ansible-shallow-dive
#Date:17/05/2025
#Version: 0.0.1
############################################################ /ᐠ｡ꞈ｡ᐟ\ ############################################################
set -euo pipefail
set -x

# Check if running on Debian and warn user if not.
LIKE_ID_SYS=$(grep ID_LIKE= /etc/os-release | cut -d= -f2)
if [[ "$LIKE_ID_SYS" != "debian" ]]; then
    echo "This script has been tested on Debian-based systems only."
    read -p "Do you wish to continue anyway? [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echo "Continuing..."
            ;;
        *)
            echo "Exiting."
            exit 1
            ;;
    esac
fi

## Verify Prerequisites ##

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
    echo "Docker is not installed."
    exit 1
fi

# Check Internet conectivity
if ! ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
    echo "No internet connection"
    exit 1
fi

function download_with_curl(){
    # If git not available, use curl to download the archvie.
    curl -L -o ansible-shallow-dive.tar.gz https://gitlab.com/vaiolabs-io/ansible-shallow-dive/-/archive/main/ansible-shallow-dive-main.tar.gz
    if [[ $? -ne 0 ]]; then
        echo "Failed to download ansible-shallow-dive repo."
        exit 1
    fi

    # Extracts archive
    tar -xzf ansible-shallow-dive.tar.gz
    if [[ $? -ne 0 ]]; then
        echo "Failed to extract archive."
        exit 1
    fi

    mv ansible-shallow-dive-main ansible-shallow-dive

    # Remove un-needed .gz file after extracting
    rm -r ansible-shallow-dive.tar.gz
}

# Download Repo from https://gitlab.com/vaiolabs-io/ansible-shallow-dive
if command -v git >/dev/null 2>&1; then
    git clone https://gitlab.com/vaiolabs-io/ansible-shallow-dive.git

    if [[ $? -eq 0 && -d "ansible-shallow-dive" ]]; then
        echo "Repository cloned successfully."
    else
        echo "Git clone failed, attempting to download using CURL."
        download_with_curl
    fi

else
download_with_curl
fi

# Start the lab
pushd ./ansible-shallow-dive/99_misc/setup/docker
docker compose up -d
if [[ $? -ne 0 ]]; then
    echo "Something went wrong while starting the containers."
    popd
    exit 1
fi

popd
# Create 05_summary_practice folder and copy needed ansible files to it.
mkdir -p ./ansible-shallow-dive/03_playbooks/05_summary_practice
cp -pL ../* ./ansible-shallow-dive/03_playbooks/05_summary_practice/ &>/dev/null

docker exec docker-ansible-host-1 bash -c "\
   export ANSIBLE_HOST_KEY_CHECKING=False; \
   cd ~/ansible_course/03_playbooks/05_summary_practice; \
   ansible-playbook playbook.yaml -v -b"