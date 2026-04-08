#!/usr/bin/env bash

set -e

COMMIT_SHA_SHORT=${GITHUB_SHA:0:8}
BUILD_STATUS="✅ Success"
ROOMID="!rnWsCVUmDHDJbiSPMM:matrix.org"

# helper functions
log_error() {
  echo -e "\e[31m$1\e[0m"
}

log_info() {
  echo -e "\e[37m$1\e[0m"
}

log_success() {
  echo -e "\e[32m$1\e[0m"
}

# Determine build source: nightly, tag or branch
if [[ "$GITHUB_EVENT_NAME" == "schedule" ]]; then
  BUILD_SOURCE="nightly-${GITHUB_REF_NAME}"
elif [[ "$GITHUB_REF_TYPE" == "tag" ]]; then
  BUILD_SOURCE="tag ${GITHUB_REF_NAME}"
else
  BUILD_SOURCE="${GITHUB_REF_NAME}"
fi

if [[ "$JOB_STATUS" == "failure" ]]; then
  BUILD_STATUS="❌️ Failure"
fi

BUILD_LINK="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
COMMIT_AUTHOR=$(git log -1 --pretty=format:'%an' 2>/dev/null || echo "unknown")

message_html='<b>'$BUILD_STATUS'</b> <a href="'${BUILD_LINK}'">'${GITHUB_REPOSITORY}'#'$COMMIT_SHA_SHORT'</a> ('${BUILD_SOURCE}') by <b>'${COMMIT_AUTHOR}'</b>'
message_html=$(echo "$message_html" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

log_info "Sending report to the element chat...."

response=$(curl -s -o /dev/null -X PUT -w "%{http_code}" "https://matrix.org/_matrix/client/v3/rooms/${ROOMID}/send/m.room.message/$(date +%s)" \
  -H "Authorization: Bearer ${MATRIX_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{
    "msgtype": "m.text",
    "body": "'"$message_html"'",
    "format": "org.matrix.custom.html",
    "formatted_body": "'"$message_html"'"
  }')

if [[ "$response" != "200" ]]; then
  log_error "❌ Error: Failed to send notification to element. Expected status code 200, but got $response."
  exit 1
fi

log_success "✅ Notification successfully sent to Element chat (ownCloud Infinite Scale Alerts)"
