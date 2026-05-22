ARG NODE_VERSION=24-bookworm-slim
FROM node:${NODE_VERSION}

ARG TZ=UTC
ENV TZ="$TZ"

ARG CLAUDE_CODE_VERSION=2.1.148

RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  procps \
  sudo \
  fzf \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  inotify-tools \
  ulogd2 \
  curl \
  jq \
  nano \
  vim \
  python3 \
  python3-pip \
  python3-venv \
  wget \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN corepack enable

RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

ARG USERNAME=node

RUN mkdir /commandhistory && touch /commandhistory/.bash_history && chown -R $USERNAME /commandhistory \
  && { echo 'export HISTFILE=/commandhistory/.bash_history'; \
       echo 'export HISTCONTROL="ignoreboth"'; \
       echo 'export HISTTIMEFORMAT="%Y %h %d %H:%M:%S "'; \
       echo 'export HISTFILESIZE=-1'; \
       echo 'export HISTSIZE=-1'; \
       echo 'export PROMPT_COMMAND="history -a"'; \
     } >> /etc/bash.bashrc

ENV DEVCONTAINER=true

RUN mkdir -p /workspace && chown -R node:node /workspace

WORKDIR /workspace

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

USER node

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

ENV SHELL=/bin/bash

ENV EDITOR=vim
ENV VISUAL=vim

ENV NODE_OPTIONS="--max-old-space-size=4096"

RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

COPY *.sh /usr/local/bin/
COPY allowed-domains.conf /etc/allowed-domains.conf
COPY ulogd.conf /etc/ulogd-blocked.conf
COPY managed-settings.json /etc/claude-code/managed-settings.json
USER root
RUN chmod +x /usr/local/bin/*.sh && \
  echo 'Defaults:node env_keep += "FIREWALL_VERBOSE"' > /etc/sudoers.d/node && \
  echo 'node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh, /usr/sbin/ulogd' >> /etc/sudoers.d/node && \
  chmod 0440 /etc/sudoers.d/node
USER node

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
