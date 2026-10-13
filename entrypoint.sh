#!/bin/sh
# The launcher runs the container with an arbitrary host UID:GID
# (docker run --user), which has no /etc/passwd entry — bash then
# shows "I have no name!". Register a matching user ("user") here.
set -e

uid=$(id -u)
gid=$(id -g)

if ! getent passwd "$uid" >/dev/null 2>&1; then
  echo "user:x:${uid}:${gid}::/home/sbx:/bin/bash" >> /etc/passwd
fi
if ! getent group "$gid" >/dev/null 2>&1; then
  echo "user:x:${gid}:" >> /etc/group
fi

exec "$@"
