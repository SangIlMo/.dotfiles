#!/bin/bash

# Swarm Coordinator Hook
# Triggered on TaskUpdate events to notify leader of task completion

# Enable strict error handling
set -euo pipefail

# Configuration
ORCHESTRATION_DIR="${HOME}/.claude/orchestration"
INBOX_DIR="${ORCHESTRATION_DIR}/inbox"
LOG_FILE="${ORCHESTRATION_DIR}/swarm.log"

# Create directories if not exist
mkdir -p "${INBOX_DIR}"
mkdir -p "${ORCHESTRATION_DIR}/results"

# Initialize log file
touch "${LOG_FILE}"

# Function to log messages
log() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%S")] $*" >> "${LOG_FILE}"
}

# Get task information from environment variables
# These are set by Claude Code when the hook is triggered
TASK_ID="${TASK_ID:-unknown}"
TASK_STATUS="${TASK_STATUS:-unknown}"
TASK_OWNER="${TASK_OWNER:-unknown}"
TASK_SUBJECT="${TASK_SUBJECT:-unknown}"

log "Hook triggered: task_id=${TASK_ID} status=${TASK_STATUS} owner=${TASK_OWNER}"

# Only process completed tasks
if [[ "${TASK_STATUS}" == "completed" ]]; then
    # Create notification message for leader
    NOTIFICATION=$(jq -n \
        --arg task_id "${TASK_ID}" \
        --arg owner "${TASK_OWNER}" \
        --arg subject "${TASK_SUBJECT}" \
        --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%S")" \
        '{
            type: "task_completed",
            task_id: $task_id,
            owner: $owner,
            subject: $subject,
            timestamp: $timestamp
        }')

    # Append to leader inbox
    echo "${NOTIFICATION}" >> "${INBOX_DIR}/leader.jsonl"

    log "Notification sent to leader inbox"
fi

# Always exit successfully to not block the TaskUpdate operation
exit 0
