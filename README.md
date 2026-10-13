# docker-pi

Run the [Pi coding agent](https://pi.dev) in a Docker sandbox, loosely based on
[the official containerization docs](https://pi.dev/docs/latest/containerization#run-pi-in-plain-docker).

## Install

```sh
make install
```

## Use

From the folder you want Pi to work in:

```sh
pi-sbx
```

This builds the image if needed, mounts the current directory at the same
absolute path inside the container, and runs as your host user so files stay
owned by you. Your host `~/.pi/agent` is bind-mounted in, so the sandbox
shares your settings, extensions, `/login` credentials, and sessions. If a
Docker socket is present, it is mounted too, so `docker` commands run against
your host daemon.

Git config comes from the host's `~/.gitconfig` — or `~/.gitconfig-sbx`
instead, if that file exists.

The image ships Node 24 (Pi included), Python 3 with pip, uv, and Poetry,
build-essential, Go, Rust, git, gh, glab, docker CLI, ripgrep, fd, and common
CLI utilities.

It also bundles the latest [`grilling` and `grill-me`
skills](https://github.com/mattpocock/skills), pulled from that repo at build
time into `~/.agents/skills/` (a directory pi auto-discovers, unlike
`~/.pi/agent`, which the host bind-mount shadows).
