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

# Snapshot the host gitconfig (staged at .gitconfig-host by the launcher)
# into ~/.gitconfig. Only copy if absent: git can't write to a single-file
# bind mount, and re-copying on restart would wipe container-local edits
# (e.g. glab's credential helper).
if [ -e "$HOME/.gitconfig-host" ] && [ ! -e "$HOME/.gitconfig" ]; then
  cp "$HOME/.gitconfig-host" "$HOME/.gitconfig"
fi

# Repos are bind-mounted from the host and owned by the host UID, which
# differs from the arbitrary UID the launcher passes to docker --user. That
# trips git's dubious-ownership check; the sandbox only mounts the user's own
# directories, so trust everything by default.
git config --global --add safe.directory '*' 2>/dev/null || true

exec "$@"
