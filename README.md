# docker-pi

Run the [Pi coding agent](https://pi.dev) in a Docker sandbox, loosely based on
[the official containerization docs](https://pi.dev/docs/latest/containerization#run-pi-in-plain-docker).

Your host `~/.pi/agent` is bind-mounted into the container, so the sandbox
shares your settings, extensions, `/login` credentials, and sessions. Log in
and install extensions on the host; the sandbox inherits them.

## Install

```sh
make install
```

## Use

From the folder you want Pi to work in:

```sh
pi-sbx
```

This builds the image if needed, mounts the current directory at
`/workspace`, and runs as your host user so files stay owned by you.
