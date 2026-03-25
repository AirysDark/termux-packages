# Build with:
#   docker build -t ghcr.io/termux/package-builder .
# Push to GitHub registry with:
#   docker push ghcr.io/termux/package-builder
# This is done after changing this file or any of the
# scripts/setup-{ubuntu,cgct}.sh setup scripts.

FROM ubuntu:24.04

# Fix locale to avoid warnings
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV container=docker
ENV TMPDIR=/tmp

# Prevent systemd tmpfiles warnings
RUN groupadd -r systemd-journal -g 999 || true \
 && useradd -r -g systemd-journal -u 999 systemd-network || true

# Create termux-packages directories
RUN rm -rf /tmp/termux-packages \
 && mkdir -p /tmp/termux-packages/scripts/build

# Copy required scripts
COPY ./llvm-snapshot.gpg.key ./properties.sh ./setup-ubuntu.sh ./setup-cgct.sh /tmp/termux-packages/scripts/
COPY ./build/termux_download.sh /tmp/termux-packages/scripts/build/

# Setup needed packages and environment for Linux-only builds
RUN apt-get update && \
    apt-get -yq upgrade && \
    apt-get install -yq sudo curl gnupg git lzip tar unzip python3 python3-pip locales jq xz-utils pkg-config bash && \
    # Create builder user
    userdel ubuntu || true && \
    useradd -u 1001 -U -m -s /bin/bash builder && \
    echo "builder ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder && \
    chmod a+rx /tmp/termux-packages/scripts/*.sh /tmp/termux-packages/scripts/build/termux_download.sh

# Switch to builder user before running scripts to avoid su issues
USER builder:builder
WORKDIR /home/builder/termux-packages

# Ensure scripts are executable and run them explicitly via bash
RUN chmod +x /tmp/termux-packages/scripts/setup-*.sh && \
    bash -c "TERMUX_PKGS__BUILD__IS_DOCKER_BUILD='true' /tmp/termux-packages/scripts/setup-ubuntu.sh && \
             TERMUX_PKGS__BUILD__IS_DOCKER_BUILD='true' /tmp/termux-packages/scripts/setup-cgct.sh"

# Cleanup unused packages and temporary files to reduce image size
USER root
RUN apt-get remove -yq --autoremove sudo curl git lzip unzip xz-utils locales \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /home/builder/lib/*.zip /home/builder/.cache

# Switch back to builder user for any further operations
USER builder:builder
WORKDIR /home/builder/termux-packages