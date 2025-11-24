#!/bin/bash
# Converts systemd service files to docker-compose.yml entries
# Usage: ./systemd-to-docker.sh [service-file.service]

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

parse_service_file() {
    local service_file="$1"
    local service_name=$(basename "$service_file" .service)

    # Extract key fields from systemd service file
    local description=$(grep "^Description=" "$service_file" | cut -d'=' -f2- || echo "$service_name")
    local user=$(grep "^User=" "$service_file" | cut -d'=' -f2- || echo "root")
    local working_dir=$(grep "^WorkingDirectory=" "$service_file" | cut -d'=' -f2- || echo "/app")
    local exec_start=$(grep "^ExecStart=" "$service_file" | cut -d'=' -f2- || echo "")
    local restart=$(grep "^Restart=" "$service_file" | cut -d'=' -f2- || echo "no")

    # Extract environment variables
    local env_vars=$(grep "^Environment=" "$service_file" | cut -d'=' -f2- || echo "")

    # Extract dependencies (After=)
    local after=$(grep "^After=" "$service_file" | cut -d'=' -f2- || echo "")

    # Use cat heredoc to safely pass values with spaces
    cat <<SERVICEDATA
service_name=$service_name
description=$description
user=$user
working_dir=$working_dir
exec_start=$exec_start
restart=$restart
SERVICEDATA
}

convert_to_docker_compose() {
    local service_file="$1"

    if [ ! -f "$service_file" ]; then
        echo "Error: Service file not found: $service_file"
        exit 1
    fi

    print_header "Converting: $(basename "$service_file")"

    # Parse the service file - use while loop to avoid issues with spaces
    while IFS='=' read -r key value; do
        case "$key" in
            service_name) local service_name="$value" ;;
            description) local description="$value" ;;
            user) local user="$value" ;;
            working_dir) local working_dir="$value" ;;
            exec_start) local exec_start="$value" ;;
            restart) local restart="$value" ;;
        esac
    done < <(parse_service_file "$service_file")

    echo -e "\n${GREEN}Docker Compose Service Definition:${NC}\n"

    cat <<EOF
  ${service_name}:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: ${service_name}
    working_dir: ${working_dir}
EOF

    # Add command
    if [ -n "$exec_start" ]; then
        echo "    command: ${exec_start}"
    fi

    # Add environment variables
    if grep -q "^Environment=" "$service_file"; then
        echo "    environment:"
        # Parse multiple Environment= lines
        while IFS= read -r line; do
            if [[ $line =~ ^Environment= ]]; then
                env_line=$(echo "$line" | cut -d'=' -f2-)
                # Remove quotes if present
                env_line=$(echo "$env_line" | sed 's/"//g' | sed "s/'//g")
                # Split KEY=VALUE
                if [[ $env_line =~ ^([^=]+)=(.*)$ ]]; then
                    key="${BASH_REMATCH[1]}"
                    value="${BASH_REMATCH[2]}"
                    echo "      ${key}: \"${value}\""
                fi
            fi
        done < "$service_file"
    fi

    # Add database dependencies if mentioned
    local deps=""
    if grep -q "postgres\|POSTGRES" "$service_file"; then
        deps="${deps}postgres "
    fi
    if grep -q "mongo\|MONGO" "$service_file"; then
        deps="${deps}mongodb "
    fi

    if [ -n "$deps" ]; then
        echo "    depends_on:"
        for dep in $deps; do
            if [ "$dep" = "postgres" ]; then
                cat <<EOF
      postgres:
        condition: service_healthy
EOF
            elif [ "$dep" = "mongodb" ]; then
                cat <<EOF
      mongodb:
        condition: service_healthy
EOF
            fi
        done
    fi

    # Add restart policy
    case "$restart" in
        always)
            echo "    restart: always"
            ;;
        on-failure)
            echo "    restart: on-failure"
            ;;
        unless-stopped)
            echo "    restart: unless-stopped"
            ;;
    esac

    # Add volumes
    echo "    volumes:"
    echo "      - .${working_dir}:${working_dir}"
    echo "      - /app/node_modules"
    echo "      - /app/.venv"

    echo ""
}

show_conversion_notes() {
    print_header "Conversion Notes"

    cat <<'EOF'

📝 Manual Steps Required:

1. Review the generated docker-compose service definition
2. Adjust the command if needed (systemd ExecStart may need modification)
3. Add any missing environment variables to .env file
4. If the service uses specific ports, add them:
   ports:
     - "PORT:PORT"

5. If the service needs specific volumes, add them:
   volumes:
     - ./local/path:/container/path

6. Create a Dockerfile if your service needs custom dependencies

Common Adjustments:

• ExecStart paths: Change absolute paths to relative or container paths
  systemd: /usr/bin/node /opt/app/server.js
  docker:  node server.js

• User permissions: Docker runs as specified user in Dockerfile
  systemd: User=www-data
  docker:  USER www-data (in Dockerfile)

• Environment files: Convert to .env or docker-compose environment section
  systemd: EnvironmentFile=/etc/myapp/config
  docker:  env_file: .env

• Logging: Docker captures stdout/stderr automatically
  systemd: StandardOutput=journal
  docker:  (automatic via docker logs)

EOF
}

# Main
if [ $# -eq 0 ]; then
    # No arguments, convert all services in resources/systemctl/
    SERVICE_DIR="resources/systemctl"

    if [ ! -d "$SERVICE_DIR" ]; then
        echo "Error: Directory $SERVICE_DIR not found"
        exit 1
    fi

    print_header "Converting All Services"

    echo -e "\n${GREEN}Add these to your docker-compose.yml under 'services:':${NC}\n"
    echo "services:"

    for service_file in "$SERVICE_DIR"/*.service; do
        if [ -f "$service_file" ]; then
            convert_to_docker_compose "$service_file"
        fi
    done

    show_conversion_notes
else
    # Convert specific service file
    convert_to_docker_compose "$1"
    show_conversion_notes
fi
