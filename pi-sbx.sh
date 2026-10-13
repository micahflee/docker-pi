#!/usr/bin/env bash
# Launch the Pi sandbox in the current directory.
#
# Auto-builds the image (a cached no-op when unchanged), mounts $PWD at the
# same absolute path inside the container, and shares the host ~/.pi/agent
# (settings, extensions, auth.json, sessions) with the container.

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

# Mount the project at its real host path (not /workspace) so paths printed
# on the host and in the container match, then start Pi there.
cwd=$(pwd -P)
run_args=(
  --user "$(id -u):$(id -g)"
  -v "$cwd:$cwd"
  -w "$cwd"
  -v "$agent_dir:/home/sbx/.pi/agent"
)

# Share the host Docker daemon, if there is one.
if [ -e /var/run/docker.sock ]; then
  run_args+=(
    -v /var/run/docker.sock:/var/run/docker.sock
    --group-add "$(stat -c %g /var/run/docker.sock)"
  )
fi

exec docker run --rm -it "${run_args[@]}" pi-sandbox
