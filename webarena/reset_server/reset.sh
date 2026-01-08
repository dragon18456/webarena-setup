#!/bin/bash

MAX_ATTEMPTS=3
ATTEMPT=1
LOG_FILE="/tmp/reset_02_output_$$.log"

cleanup() {
    rm -f "$LOG_FILE"
}
trap cleanup EXIT

cd ..

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "=== Reset attempt $ATTEMPT of $MAX_ATTEMPTS ==="
    
    # Run 02 and capture output to check for acceptable errors
    if ! sudo bash 02_docker_remove_containers.sh 2>"$LOG_FILE"; then
        # Check if all errors are "No such container" (which is OK)
        if grep -v "No such container" "$LOG_FILE" | grep -q "Error"; then
            echo "=== 02_docker_remove_containers.sh failed with unexpected error ==="
            cat "$LOG_FILE"
            ATTEMPT=$((ATTEMPT + 1))
            if [ $ATTEMPT -le $MAX_ATTEMPTS ]; then
                echo "Retrying in 5 seconds..."
                sleep 5
            fi
            continue
        fi
        echo "=== 02 had 'No such container' errors (OK, continuing) ==="
    fi
    
    # Try the critical steps
    if sudo bash 03_docker_create_containers.sh && \
       sudo bash 04_docker_start_containers.sh && \
       sudo bash 05_docker_patch_containers.sh; then
        echo "=== Reset succeeded on attempt $ATTEMPT ==="
        exit 0
    fi
    
    echo "=== Reset attempt $ATTEMPT failed ==="
    ATTEMPT=$((ATTEMPT + 1))
    
    if [ $ATTEMPT -le $MAX_ATTEMPTS ]; then
        echo "Retrying in 5 seconds..."
        sleep 5
    fi
done

echo "=== Reset failed after $MAX_ATTEMPTS attempts ==="
exit 1
