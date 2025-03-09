#! /bin/bash

NUM_ARGS="$#"
RUN_COMMAND="$1"
OCEL_MOUNT_PATH="$2"

if command -v docker compose &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo "Error: Neither 'docker compose' nor 'docker-compose' found."
    exit 1
fi

if [[ $NUM_ARGS -ne 1 && $NUM_ARGS -ne 2 ]]; then
    echo "Please provide an app command and optionally a path to a folder of event logs to mount, e.g.: >> ./app.sh --start ../my_ocels/"
    echo "For more information, e.g. all available commands, see the user manual."
    exit 1
fi

if [[ -n "$OCEL_MOUNT_PATH" ]]; then
    if ! command -v realpath &> /dev/null; then
        echo "Error: 'realpath' command not found. Please install it (e.g., sudo apt install coreutils)."
        exit 1
    fi
    OCEL_MOUNT_PATH=$(realpath "$OCEL_MOUNT_PATH")
    if [[ ! -d "$OCEL_MOUNT_PATH" ]]; then
        echo "$OCEL_MOUNT_PATH is not a valid directory or does not exist."
        exit 1
    fi
fi

case "$RUN_COMMAND" in
    ("--start")
        if ! $DOCKER_COMPOSE build --no-cache _backend_base; then
            echo "Error: Failed to build the backend base image."
            exit 1
        fi
        if [[ -n "$OCEL_MOUNT_PATH" ]]; then
            export OCEL_MOUNT_PATH="$OCEL_MOUNT_PATH" 
            $DOCKER_COMPOSE -f docker-compose.yml -f docker-compose.mount-ocels.yml -f docker-compose.prod.yml config --services | grep -v _backend_base | xargs $DOCKER_COMPOSE -f docker-compose.yml -f docker-compose.mount-ocels.yml -f docker-compose.prod.yml build --no-cache
            $DOCKER_COMPOSE -f docker-compose.yml -f docker-compose.mount-ocels.yml -f docker-compose.prod.yml up
        else
            $DOCKER_COMPOSE -f docker-compose.yml -f docker-compose.prod.yml config --services | grep -v _backend_base | xargs $DOCKER_COMPOSE -f docker-compose.yml -f docker-compose.prod.yml build --no-cache
            $DOCKER_COMPOSE -f docker-compose.yml -f docker-compose.prod.yml up --detach
        fi
        ;;
    ("--start-dev")
        if ! $DOCKER_COMPOSE build _backend_base; then
                echo "Docker build failed. Exiting."
                exit 1
        fi
        $DOCKER_COMPOSE -f docker-compose.yml -f docker-compose.dev.yml config --services | grep -v _backend_base | xargs $DOCKER_COMPOSE -f docker-compose.yml -f docker-compose.dev.yml build --no-cache
        $DOCKER_COMPOSE -f docker-compose.yml -f docker-compose.dev.yml up --detach
        ;;
    ("--stop") 
        $DOCKER_COMPOSE stop
        ;;
    ("--remove")
        $DOCKER_COMPOSE -f docker-compose.yml -f docker-compose.prod.yml down --volumes
        ;;
    (*) 
        echo "Please provide a valid app command, e.g. --start. For more information, e.g. all available commands, see the user manual."
        exit 1
        ;;
esac

exit 0
