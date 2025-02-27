#!/bin/bash

# Script Name
SCRIPT_NAME="docker_clean_install.sh"

# Log file with time/date stamp and script name
LOG_FILE="$(date +'%Y-%m-%d_%H-%M-%S')_${SCRIPT_NAME%.*}.log"

# Function to log messages with time/date stamp
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to clean up Docker
clean_docker() {
    log "Checking for existing Docker installations..."

    if command_exists docker; then
        log "Docker is installed. Cleaning up Docker images, containers, and volumes..."
        docker system prune -a -f --volumes
        log "Stopping all running Docker containers..."
        docker stop $(docker ps -aq)
        log "Removing all Docker containers..."
        docker rm -f $(docker ps -aq)
        log "Removing all Docker images..."
        docker rmi -f $(docker images -q)
        log "Removing all Docker volumes..."
        docker volume rm -f $(docker volume ls -q)
    else
        log "Docker is not installed."
    fi

    log "Removing Docker, Docker-Compose, and related files..."
    sudo apt-get remove -y docker docker-engine docker.io containerd runc
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    sudo rm -rf /etc/docker
    sudo rm -rf /etc/containerd
    sudo rm -rf /var/run/docker.sock
    sudo rm -rf /usr/local/bin/docker-compose
    sudo rm -rf /usr/local/bin/docker
    sudo rm -rf /usr/share/keyrings/docker-archive-keyring.gpg
    sudo groupdel docker 2>/dev/null
    log "Docker cleanup complete."
}

# Function to install Docker and Docker-Compose
install_docker() {
    log "Installing Docker and Docker-Compose..."

    # Install Docker
    log "Updating package list..."
    sudo apt-get update -y

    log "Installing dependencies..."
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    log "Adding Docker's official GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    log "Adding Docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    log "Installing Docker Engine..."
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    log "Adding current user to Docker group..."
    sudo usermod -aG docker $USER
    log "Docker installed successfully."
}

# Function to set up Portainer
setup_portainer() {
    log "Setting up Portainer..."

    log "Creating Portainer volume..."
    docker volume create portainer_data

    log "Running Portainer container..."
    docker run -d -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

    log "Portainer is now running on port 9000."
}

# Main script execution
log "Starting Docker cleanup and installation script..."

# Clean up Docker
clean_docker

# Install Docker and Docker-Compose
install_docker

# Set up Portainer
setup_portainer

log "Script execution completed. Check $LOG_FILE for details."
