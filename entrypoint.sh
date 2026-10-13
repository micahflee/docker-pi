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
# sudo validates the account via /etc/shadow; without an entry there it
# reports "account validation failure, is your account locked?". A "*"
# password means "no password login" but the account is not locked.
if [ "$(getent shadow user 2>/dev/null | cut -d: -f1)" != "user" ]; then
  echo 'user:*:19750:0:99999:7:::' >> /etc/shadow
fi

exec "$@"
