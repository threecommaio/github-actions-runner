FROM quay.io/evryfs/base-ubuntu:focal-20200925

ARG RUNNER_VERSION=2.273.4
ARG VIRTUAL_ENV_INSTALLS="basic python nodejs"

# This the release tag of virtual-environments: https://github.com/actions/virtual-environments/releases
ARG VIRTUAL_ENVIRONMENT_VERSION=ubuntu20/20200920.1
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY conf/dpkg.cfg.d /etc/dpkg/dpkg.cfg.d/

# Install base packages.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sudo=1.8.* \
    lsb-release=11.* \
    software-properties-common=0.98.* \
    gnupg-agent=2.2.* \
    openssh-client=1:8.* \
    make=4.*\
    jq=1.* && \
    apt-get -y clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Update git.
RUN add-apt-repository -y ppa:git-core/ppa && \
    apt-get update && \
    apt-get -y install --no-install-recommends git=1:2.28.* && \
    apt-get -y clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install docker cli.
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get install -y --no-install-recommends docker-ce-cli=5:19.03.* && \
    apt-get -y clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy scripts.
COPY scripts/install-from-virtual-env /usr/local/bin/install-from-virtual-env

# Install base packages from the virtual environment.
RUN for package in ${VIRTUAL_ENV_INSTALLS}; do \
        install-from-virtual-env $package; \
    done && \
    apt-get -y clean && \
    rm -rf /virtual-environments /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install runner and its dependencies.
RUN useradd -mr -d /home/runner runner && \
    curl -sL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" | tar xzvC /home/runner && \
    /home/runner/bin/installdependencies.sh

COPY entrypoint.sh remove_runner.sh /
WORKDIR /home/runner
USER runner
ENTRYPOINT ["/entrypoint.sh"]
