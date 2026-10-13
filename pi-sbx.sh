#!/usr/bin/env bash
# Launch the Pi sandbox in the current directory.
#
# Auto-builds the image (a cached no-op when unchanged), mounts $PWD as the
# workspace, and shares the host ~/.pi/agent (settings, extensions, auth.json,
# sessions) with the container.

set -euo pipefail

# Resolve this script through the ~/.local/bin/pi-sbx symlink to find the
# Dockerfile committed next to it.
script="$0"
while [ -L "$script" ]; do
  target=$(readlink "$script")
  case "$target" in
    /*) script="$target" ;;
    *) script="$(dirname "$script")/$target" ;;
  esac
done
repo_dir=$(cd "$(dirname "$script")" && pwd -P)

agent_dir="$HOME/.pi/agent"
if [ ! -d "$agent_dir" ]; then
  echo "pi-sbx: $agent_dir does not exist." >&2
  echo "Start pi on the host first so it creates your agent directory" >&2
  echo "(settings, extensions, logins), or mkdir -p it yourself." >&2
  echo "Docker would otherwise create it as root." >&2
  exit 1
fi

docker build -t pi-sandbox "$repo_dir"

exec docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  -v "$PWD:/workspace" \
  -v "$HOME/.pi/agent:/home/sbx/.pi/agent" \
  pi-sandbox
