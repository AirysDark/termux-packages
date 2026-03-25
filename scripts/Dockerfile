# -----------------------------
# Termux Package Builder Dockerfile for CI (Ubuntu 22.04 / LLVM 16)
# -----------------------------

FROM ubuntu:22.04

# -----------------------------
# Environment setup
# -----------------------------
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV container=docker
ENV TMPDIR=/tmp
ENV TERMUX_HOST_LLVM_MAJOR_VERSION=16
ENV TERMUX_HOST_GCC_VERSION=13

# Prevent systemd tmpfiles warnings
RUN groupadd -r systemd-journal -g 999 || true \
 && useradd -r -g systemd-journal -u 999 systemd-network || true

# -----------------------------
# Create directories
# -----------------------------
RUN rm -rf /tmp/termux-packages \
 && mkdir -p /tmp/termux-packages/scripts/build \
 && mkdir -p /etc/apparmor.d

# -----------------------------
# Copy required scripts
# -----------------------------
COPY ./llvm-snapshot.gpg.key ./properties.sh ./setup-ubuntu.sh ./setup-cgct.sh /tmp/termux-packages/scripts/
COPY ./build/termux_download.sh /tmp/termux-packages/scripts/build/

# -----------------------------
# Install packages & create builder user
# -----------------------------
RUN apt-get update && \
    apt-get -yq upgrade && \
    apt-get install -yq sudo curl gnupg git lzip tar unzip python3 python3-pip locales jq xz-utils pkg-config && \
    # Remove default ubuntu user and add builder
    userdel ubuntu || true && \
    useradd -u 1001 -U -m -s /bin/bash builder && \
    echo "builder ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder

# -----------------------------
# Copy AppArmor profile (for reference only, no parsing)
# -----------------------------
COPY ./apparmor/_custom-termux-package-builder.profile /etc/apparmor.d/_custom-termux-package-builder

# -----------------------------
# Ensure scripts are executable (as root)
# -----------------------------
RUN chmod +x /tmp/termux-packages/scripts/setup-*.sh \
 && chmod +x /tmp/termux-packages/scripts/build/termux_download.sh

# -----------------------------
# Skip AppArmor parsing entirely for CI
# -----------------------------
RUN echo "Skipping AppArmor parse in CI / unsupported kernel"

# -----------------------------
# Import PGP keys for verification
# -----------------------------
RUN gpg --import /tmp/termux-packages/scripts/llvm-snapshot.gpg.key

# -----------------------------
# Switch to builder user
# -----------------------------
USER builder:builder
WORKDIR /home/builder/termux-packages

# -----------------------------
# Run setup scripts as builder
# -----------------------------
RUN bash -c "TERMUX_PKGS__BUILD__IS_DOCKER_BUILD='true' \
             TERMUX_HOST_LLVM_MAJOR_VERSION=${TERMUX_HOST_LLVM_MAJOR_VERSION} \
             TERMUX_HOST_GCC_VERSION=${TERMUX_HOST_GCC_VERSION} \
             TERMUX_PKG_TMPDIR=/tmp \
             /tmp/termux-packages/scripts/setup-ubuntu.sh && \
             /tmp/termux-packages/scripts/setup-cgct.sh"

# -----------------------------
# Cleanup to reduce image size
# -----------------------------
USER root
RUN apt-get remove -yq --autoremove sudo curl git lzip unzip xz-utils locales \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /home/builder/lib/*.zip /home/builder/.cache

# -----------------------------
# Switch back to builder user
# -----------------------------
USER builder:builder
WORKDIR /home/builder/termux-packages