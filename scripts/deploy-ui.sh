#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE_URI="$1"

CONTAINER="portal-ui"
BACKUP="portal-ui-previous"

# Only accept an immutable private ECR image reference.
if [[ ! "$IMAGE_URI" =~ ^[0-9]{12}\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com/.+@sha256:[a-f0-9]{64}$ ]]; then
  echo "Invalid ECR image digest reference"
  exit 1
fi

REGISTRY="${IMAGE_URI%%/*}"
ECR_REGION="$(printf '%s' "$REGISTRY" | cut -d. -f4)"

docker info >/dev/null

if docker container inspect "$BACKUP" >/dev/null 2>&1; then
  echo "Inspect the backup left by an earlier deployment: $BACKUP"
  exit 1
fi

# Uses the EC2 instance role.
aws ecr get-login-password --region "$ECR_REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

# Download before stopping the old application.
docker pull "$IMAGE_URI"

had_previous=false
new_started=false

rollback() {
  trap - ERR

  echo "Deployment failed"
  docker logs --tail 100 "$CONTAINER" 2>/dev/null || true

  if [ "$new_started" = "true" ]; then
    docker rm -f "$CONTAINER" || true
  fi

  if [ "$had_previous" = "true" ]; then
    docker rename "$BACKUP" "$CONTAINER"
    docker start "$CONTAINER"
    echo "Previous container restarted"
  fi

  exit 1
}

trap rollback ERR

if docker container inspect "$CONTAINER" >/dev/null 2>&1; then
  docker stop "$CONTAINER"
  docker rename "$CONTAINER" "$BACKUP"
  had_previous=true
fi

docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  --publish 8080:8080 \
  --memory 1g \
  "$IMAGE_URI"

new_started=true
healthy=false

for attempt in $(seq 1 60); do
  if curl --fail --silent \
    --connect-timeout 2 \
    --max-time 3 \
    http://localhost:8080/actuator/health/readiness \
    >/dev/null; then
    healthy=true
    break
  fi

  echo "Waiting for readiness: attempt $attempt"
  sleep 3
done

if [ "$healthy" != "true" ]; then
  echo "Readiness smoke test failed"
  false
fi

actual_image="$(docker inspect --format '{{.Config.Image}}' "$CONTAINER")"

if [ "$actual_image" != "$IMAGE_URI" ]; then
  echo "Running image does not match selected image"
  false
fi

echo "PASS: Expected image is running and readiness check passed"
echo "Image: $actual_image"

if [ "$had_previous" = "true" ]; then
  docker rm "$BACKUP"
fi

trap - ERR
