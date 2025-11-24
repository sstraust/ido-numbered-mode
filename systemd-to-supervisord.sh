#!/bin/bash
# Converts systemd service files to supervisord configuration
# Usage: ./systemd-to-supervisord.sh [service-file.service]

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

convert_to_supervisord() {
    local service_file="$1"

    if [ ! -f "$service_file" ]; then
        echo "Error: Service file not found: $service_file"
        exit 1
    fi

    local service_name=$(basename "$service_file" .service)
    local description=$(grep "^Description=" "$service_file" | cut -d'=' -f2- || echo "$service_name")
    local user=$(grep "^User=" "$service_file" | cut -d'=' -f2- || echo "")
    local working_dir=$(grep "^WorkingDirectory=" "$service_file" | cut -d'=' -f2- || echo "/app")
    local exec_start=$(grep "^ExecStart=" "$service_file" | cut -d'=' -f2- || echo "")
    local restart=$(grep "^Restart=" "$service_file" | cut -d'=' -f2- || echo "")

    print_header "Converting: $(basename "$service_file")"

    echo -e "\n${GREEN}Supervisord Program Definition:${NC}\n"

    # Start program section
    echo "# ${description}"
    echo "[program:${service_name}]"
    echo "command=${exec_start}"
    echo "directory=${working_dir}"
    echo "autostart=true"

    # Restart policy
    case "$restart" in
        always|on-failure)
            echo "autorestart=true"
            ;;
        *)
            echo "autorestart=false"
            ;;
    esac

    # User
    if [ -n "$user" ]; then
        echo "user=${user}"
    fi

    # Logging
    echo "stderr_logfile=/dev/stderr"
    echo "stderr_logfile_maxbytes=0"
    echo "stdout_logfile=/dev/stdout"
    echo "stdout_logfile_maxbytes=0"

    # Environment variables
    if grep -q "^Environment=" "$service_file"; then
        local env_string=""
        while IFS= read -r line; do
            if [[ $line =~ ^Environment= ]]; then
                env_line=$(echo "$line" | cut -d'=' -f2-)
                env_line=$(echo "$env_line" | sed 's/"//g' | sed "s/'//g")
                if [ -n "$env_string" ]; then
                    env_string="${env_string},${env_line}"
                else
                    env_string="${env_line}"
                fi
            fi
        done < "$service_file"

        if [ -n "$env_string" ]; then
            echo "environment=${env_string}"
        fi
    fi

    echo ""
}

show_usage() {
    print_header "Supervisord Setup"

    cat <<'EOF'

To use supervisord in Docker:

1. Create supervisord.conf with all your services:

[supervisord]
nodaemon=true
logfile=/dev/stdout
logfile_maxbytes=0

# Add converted program definitions here
[program:service1]
command=node server.js
...

2. Update your Dockerfile:

FROM node:20-bullseye
RUN apt-get update && apt-get install -y supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

3. Build and run:

docker-compose build
docker-compose up -d

See:
- Dockerfile.supervisord (example Dockerfile)
- supervisord.conf (example configuration)

EOF
}

# Main
if [ $# -eq 0 ]; then
    SERVICE_DIR="resources/systemctl"

    if [ ! -d "$SERVICE_DIR" ]; then
        echo "Error: Directory $SERVICE_DIR not found"
        exit 1
    fi

    print_header "Converting All Services to Supervisord"

    echo "[supervisord]"
    echo "nodaemon=true"
    echo "logfile=/dev/stdout"
    echo "logfile_maxbytes=0"
    echo "loglevel=info"
    echo ""

    for service_file in "$SERVICE_DIR"/*.service; do
        if [ -f "$service_file" ]; then
            convert_to_supervisord "$service_file"
        fi
    done

    show_usage
else
    convert_to_supervisord "$1"
    show_usage
fi
