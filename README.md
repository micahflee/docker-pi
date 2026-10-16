# pi-sbx

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

This creates a persistent Docker container for the current directory (named
by a hash of its path). Run it again from the same folder and it restarts
(or execs into) the same container, so anything you installed or configured
inside it sticks around. If the container is already running (another
terminal), a new pi session is started inside it.

Your host `~/.pi/agent` is bind-mounted in, so the sandbox
shares your settings, extensions, `/login` credentials, and sessions. If a
Docker socket is present, it is mounted too, so `docker` commands run against
your host daemon.

## Homedir template

Optionally, seed the sandbox's home directory by placing files in
`~/.config/pi-sbx/home-template/` on the host — ssh keys, agent skills,
dotfiles, and so on. Everything there is copied into the container's
`$HOME` when it's first created. Each file is copied only if it doesn't
already exist (existing directories like `~/.ssh` are merged), and file
modes are preserved, so ssh key permissions carry over. For example:

```
~/.config/pi-sbx/home-template/
  .gitconfig
  .ssh/
    config
    id_ed25519
  .agents/skills/...
```

Copies happen only at first start, so container-local edits stick around
across restarts.

Mounts and the image are fixed at container creation; to pick up Dockerfile
or host config changes, remove the sandbox and let it be recreated.

## Clipboard

The container can't reach the host clipboard, so the image sets
`PI_CLIPBOARD_OSC52=1`: copies in pi also emit an OSC 52 escape sequence the
host terminal applies. Requires an OSC-52-capable terminal (iTerm2, kitty,
WezTerm, Alacritty, ghostty, foot — not Terminal.app or GNOME Terminal).

## Commands

- `pi-sbx` — run (or rejoin) the sandbox for the current directory
- `pi-sbx ls` — list all sandboxes (name, state, path)
- `pi-sbx shell` — open an interactive shell inside this directory's sandbox
- `pi-sbx rm [-y|--force]` — delete this directory's sandbox (prompts
  unless `-y`; `~/.pi/agent` on the host is untouched, the image is kept)

The image ships Node 24 (Pi included), Python 3 with pip, uv, and Poetry,
build-essential, Go, Rust, git, gh, glab, docker CLI, ripgrep, fd, and common
CLI utilities.

It also bundles the latest [`grilling` and `grill-me`
skills](https://github.com/mattpocock/skills), pulled from that repo at build
time into `~/.agents/skills/` (a directory pi auto-discovers, unlike
`~/.pi/agent`, which the host bind-mount shadows).
