ARG NODE_VERSION=24-bookworm-slim
FROM node:${NODE_VERSION}

ARG TZ=UTC
ENV TZ="$TZ"

ARG CLAUDE_CODE_VERSION=2.1.169

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
  openssh-client \
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

# Writable plugin cache dir, kept out of the bind-mounted ~/.claude
RUN mkdir -p /home/node/.claude-plugins && chown node:node /home/node/.claude-plugins

WORKDIR /workspace

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

ARG KUBECTL_VERSION=1.32.4
RUN ARCH=$(dpkg --print-architecture) && \
  curl -fLo /usr/local/bin/kubectl "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" && \
  case "$ARCH" in \
    amd64) echo "10d739e9af8a59c9e7a730a2445916e04bc9cbb44bc79d22ce460cd329fa076c  /usr/local/bin/kubectl" ;; \
    arm64) echo "c6f96d0468d6976224f5f0d81b65e1a63b47195022646be83e49d38389d572c2  /usr/local/bin/kubectl" ;; \
  esac | sha256sum --check && \
  chmod +x /usr/local/bin/kubectl

ARG WIZCLI_VERSION=0.109.14
RUN ARCH=$(dpkg --print-architecture) && \
  curl -fLo /usr/local/bin/wizcli "https://downloads.wiz.io/wizcli/${WIZCLI_VERSION}/wizcli-linux-${ARCH}" && \
  case "$ARCH" in \
    amd64) echo "a749ddfb9b984b34f052c16aced3c18d7a7c459b507c126d0d6e117f585f2be0  /usr/local/bin/wizcli" ;; \
    arm64) echo "90c17e0489ea7b95e87a6dda3bdd9fc7481da23efe54708853df26000ae78a63  /usr/local/bin/wizcli" ;; \
  esac | sha256sum --check && \
  chmod +x /usr/local/bin/wizcli

USER node

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=/home/node/.local/bin:$PATH:/usr/local/share/npm-global/bin

ENV SHELL=/bin/bash

ENV EDITOR=vim
ENV VISUAL=vim

ENV NODE_OPTIONS="--max-old-space-size=4096"

RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} && \
  mkdir -p /home/node/.local/bin

ARG UV_VERSION=0.11.17
RUN ARCH=$(uname -m) && \
  curl -fLo /tmp/uv.tar.gz "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${ARCH}-unknown-linux-gnu.tar.gz" && \
  case "$ARCH" in \
    x86_64)  echo "0017ccecaeb4d431d7f93b583ebff0c5c38e00eb734fcf13d05f72ca419125fe  /tmp/uv.tar.gz" ;; \
    aarch64) echo "de008880a903ac2c5654647dc19a75c0d6652313c977a2bc5ce05e1e3a93429e  /tmp/uv.tar.gz" ;; \
  esac | sha256sum --check && \
  tar -xzf /tmp/uv.tar.gz --strip-components=1 -C /home/node/.local/bin \
    "uv-${ARCH}-unknown-linux-gnu/uv" "uv-${ARCH}-unknown-linux-gnu/uvx" && \
  rm /tmp/uv.tar.gz

COPY *.sh /usr/local/bin/
COPY allowed-domains.conf /etc/allowed-domains.conf
COPY ulogd.conf /etc/ulogd-blocked.conf
COPY managed-settings.json /etc/claude-code/managed-settings.json
USER root
RUN chmod +x /usr/local/bin/*.sh && \
  echo 'Defaults:node env_keep += "FIREWALL FIREWALL_VERBOSE"' > /etc/sudoers.d/node && \
  echo 'node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh, /usr/sbin/ulogd' >> /etc/sudoers.d/node && \
  chmod 0440 /etc/sudoers.d/node
USER node

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
