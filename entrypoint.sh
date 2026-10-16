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

# Seed $HOME from the host's ~/.config/pi-sbx/home-template (staged at
# ~/.home-template by the launcher) — ssh keys, agent skills, etc. Copy
# each path only if absent: the mount is read-only, and re-copying on
# restart would wipe container-local edits. Existing directories are
# merged, and mode bits are preserved (e.g. 700 ~/.ssh, 400 keys) so
# things like ssh keep working; user-write is added where the host file
# lacked it so tools in the container can still edit the copy.
template="$HOME/.home-template"
if [ -d "$template" ]; then
  (
    cd "$template" || exit 1
    # sort ensures a directory is created before anything inside it
    find . -mindepth 1 | sort | while IFS= read -r rel; do
      dst="$HOME/$rel"
      # skip anything that already exists (file OR directory), and
      # skip the staging mount itself
      if [ "$rel" = "./.home-template" ] || [ -e "$dst" ] || [ -L "$dst" ]; then
        continue
      fi
      if [ -d "$rel" ]; then
        mkdir -m "$(stat -c %a "$rel")" "$dst"
      else
        cp -Rp "$rel" "$dst"
        [ -w "$rel" ] || chmod u+w "$dst"
      fi
    done
  )
fi

# Repos are bind-mounted from the host and owned by the host UID, which
# differs from the arbitrary UID the launcher passes to docker --user. That
# trips git's dubious-ownership check; the sandbox only mounts the user's own
# directories, so trust everything by default.
git config --global --add safe.directory '*' 2>/dev/null || true

exec "$@"
