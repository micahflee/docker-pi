FROM node:24-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates git ripgrep \
  && rm -rf /var/lib/apt/lists/*
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# Writable HOME for the arbitrary host UID the launcher passes with --user.
# The real ~/.pi/agent is bind-mounted here at run time.
RUN mkdir -p /home/sbx/.pi && chmod 777 /home/sbx
ENV HOME=/home/sbx

WORKDIR /workspace
ENTRYPOINT ["pi"]