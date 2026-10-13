FROM node:24-bookworm-slim

ARG GO_VERSION=1.27.2
ARG GLAB_VERSION=1.123.0

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash ca-certificates git ripgrep \
    curl wget jq zip unzip less procps openssh-client \
    fd-find gh \
    python3 python3-pip python3-venv pipx \
    build-essential \
  && rm -rf /var/lib/apt/lists/* \
  && ln -sf "$(command -v fdfind)" /usr/local/bin/fd

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
ENV HOME=/home/sbx

WORKDIR /workspace
ENTRYPOINT ["pi"]
