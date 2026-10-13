FROM node:24-bookworm-slim

ARG GO_VERSION=1.27.2
ARG GLAB_VERSION=1.123.0

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash ca-certificates git ripgrep sudo vim \
    curl wget jq zip unzip less procps openssh-client \
    fd-find gh \
    python3 python3-pip python3-venv pipx \
    build-essential \
  && rm -rf /var/lib/apt/lists/* \
  && ln -sf "$(command -v fdfind)" /usr/local/bin/fd

# Passwordless sudo so the runtime user can apt-install things on the fly.
# The launcher passes an arbitrary host UID, so allow all users; the
# entrypoint registers a passwd entry for the UID at startup.
RUN echo 'ALL ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/nopasswd \
  && chmod 440 /etc/sudoers.d/nopasswd \
  && visudo -c

# Docker CLI from Docker's apt repo, so it matches a current host daemon.
RUN curl -fsSL https://download.docker.com/linux/debian/gpg \
    -o /etc/apt/keyrings/docker.asc \
  && echo "deb [signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" \
    > /etc/apt/sources.list.d/docker.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends docker-ce-cli \
  && rm -rf /var/lib/apt/lists/*

# Go, pinned to an upstream release (bump GO_VERSION to upgrade).
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz" \
    -o /tmp/go.tgz \
  && tar -C /usr/local -xzf /tmp/go.tgz \
  && rm /tmp/go.tgz
ENV PATH=/usr/local/go/bin:$PATH

# Rust, installed system-wide so it works for any runtime UID.
ENV RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path \
  --default-toolchain stable \
  && chmod -R a+rwX /usr/local/rustup /usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

# uv / uvx.
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Poetry via pipx, system-wide.
RUN PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install poetry \
  && chmod -R a+rwX /opt/pipx

# glab (GitLab CLI), pinned to an upstream release (bump GLAB_VERSION to upgrade).
RUN arch="$(dpkg --print-architecture)" \
  && curl -fsSL "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VERSION}/glab_${GLAB_VERSION}_linux_${arch}.deb" \
    -o /tmp/glab.deb \
  && dpkg -i /tmp/glab.deb \
  && rm /tmp/glab.deb

RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# Writable HOME for the arbitrary host UID the launcher passes with --user.
# The real ~/.pi/agent is bind-mounted here at run time.
RUN mkdir -p /home/sbx/.pi && chmod 777 /home/sbx

# The launcher passes an arbitrary host UID:GID via docker --user, which has
# no /etc/passwd entry (bash shows "I have no name!"). The entrypoint adds a
# matching "user" entry at startup; passwd/group must be writable for that.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
  && chmod 666 /etc/passwd /etc/group

# Bundle the latest grilling/grill-me skills from mattpocock/skills.
# They go in ~/.agents/skills (which pi auto-discovers) rather than
# ~/.pi/agent/skills, because the launcher bind-mounts the host's
# ~/.pi/agent over that path at run time.
RUN git clone --depth 1 https://github.com/mattpocock/skills /tmp/skills \
  && mkdir -p /home/sbx/.agents/skills \
  && cp -r /tmp/skills/skills/productivity/grilling \
          /tmp/skills/skills/productivity/grill-me \
          /home/sbx/.agents/skills/ \
  && chmod -R a+rX /home/sbx/.agents/skills \
  && rm -rf /tmp/skills
ENV HOME=/home/sbx

# Fallback only; pi-sbx.sh overrides this so the container's working
# directory matches the mounted host path.
WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "pi"]
