#!/usr/bin/env bash
# Launch the Pi sandbox in the current directory. Creates a persistent
# container per directory (or execs into / restarts the existing one).
# Subcommands: ls (list sandboxes), rm (delete this directory's sandbox).

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
check_agent_dir() {
  if [ ! -d "$agent_dir" ]; then
    echo "pi-sbx: $agent_dir does not exist." >&2
    echo "Start pi on the host first so it creates your agent directory" >&2
    echo "(settings, extensions, logins), or mkdir -p it yourself." >&2
    echo "Docker would otherwise create it as root." >&2
    exit 1
  fi
}

cwd=$(pwd -P)
name="pi-sbx-$(printf '%s' "$cwd" | sha256sum | cut -c1-12)"

case "${1:-run}" in
  ls)
    docker ps -a --filter label=pi-sbx \
      --format '{{.Names}}\t{{.State}}\t{{.Label "pi-sbx.path"}}' |
      while IFS=$'\t' read -r n s p; do
        printf '%s  %s  %s\n' "$n" "$s" "$p"
      done
    exit 0
    ;;

  rm)
    shift
    force=0
    for arg in "$@"; do
      case "$arg" in
        -y|--force) force=1 ;;
        *) echo "usage: pi-sbx rm [-y|--force]" >&2; exit 2 ;;
      esac
    done
    if ! docker container inspect "$name" >/dev/null 2>&1; then
      echo "pi-sbx: no sandbox for $cwd" >&2
      exit 1
    fi
    if [ "$force" -ne 1 ]; then
      running=$(docker container inspect -f '{{.State.Running}}' "$name")
      if [ "$running" = "true" ]; then
        echo "pi-sbx: container $name is currently running and will be killed."
      fi
      read -r -p "Are you sure? [y/N] " reply
      case "$reply" in
        y|Y|yes|YES) ;;
        *) echo "Aborted."; exit 1 ;;
      esac
    fi
    docker rm -f "$name"
    echo "Removed $name (the pi-sandbox image is kept)."
    exit 0
    ;;

  run)
    check_agent_dir
    if docker container inspect "$name" >/dev/null 2>&1; then
      running=$(docker container inspect -f '{{.State.Running}}' "$name")
      if [ "$running" = "true" ]; then
        exec docker exec -it "$name" pi
      fi
      exec docker start -ai "$name"
    fi

    docker build -t pi-sandbox "$repo_dir"

    gitconfig="$HOME/.gitconfig-sbx"
    if [ ! -e "$gitconfig" ]; then
      gitconfig="$HOME/.gitconfig"
    fi

    run_args=(
      --name "$name"
      --label pi-sbx
      --label "pi-sbx.path=$cwd"
      --user "$(id -u):$(id -g)"
      -v "$cwd:$cwd"
      -w "$cwd"
      -v "$agent_dir:/home/sbx/.pi/agent"
    )
    if [ -e "$gitconfig" ]; then
      run_args+=(-v "$gitconfig:/home/sbx/.gitconfig:ro")
    fi

    if [ -e /var/run/docker.sock ]; then
      run_args+=(
        -v /var/run/docker.sock:/var/run/docker.sock
        --group-add "$(stat -c %g /var/run/docker.sock)"
      )
    fi

    exec docker run -it "${run_args[@]}" pi-sandbox
    ;;

  *)
    echo "usage: pi-sbx [ls | rm [-y|--force]]" >&2
    exit 2
    ;;
esac
