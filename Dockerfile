#-------------------------------------------------------------------------------
# Arm GNU Toolchain Devcontainer
# Copyright © 2023 islandcontroller and contributors
# Migrated to Alpine by David Webb 2026-01-17
#-------------------------------------------------------------------------------

# Base image: Alpine Dev Container
FROM mcr.microsoft.com/devcontainers/base:alpine

# Root user for setup
USER root

# Dependencies setup
RUN apk add --no-cache \
    cmake \
    curl \
    make \
    openocd \
    tar \
    udev \
    usbutils

# Setup dir for packages installation
WORKDIR /tmp

#- Arm GNU Toolchain -----------------------------------------------------------
ARG TOOLCHAIN_VERSION=15.2.rel1
ARG TOOLCHAIN_URL="https://developer.arm.com/-/media/Files/downloads/gnu/$TOOLCHAIN_VERSION/binrel/arm-gnu-toolchain-$TOOLCHAIN_VERSION-x86_64-arm-none-eabi.tar.xz"
ARG TOOLCHAIN_INSTALL_DIR="/opt/gcc-arm-none-eabi"

# Download and install package
RUN curl -sLO ${TOOLCHAIN_URL} && \
    curl -sL ${TOOLCHAIN_URL}.asc | tr [:upper:] [:lower:] | md5sum -c - && \
    mkdir -p ${TOOLCHAIN_INSTALL_DIR} && \
    tar -xf $(basename ${TOOLCHAIN_URL}) -C ${TOOLCHAIN_INSTALL_DIR} --strip-components=1 && \
    rm $(basename "${TOOLCHAIN_URL}")
COPY gcc-arm-none-eabi.cmake ${TOOLCHAIN_INSTALL_DIR}
ENV PATH=$PATH:${TOOLCHAIN_INSTALL_DIR}/bin

# #- JLink Debugger --------------------------------------------------------------
# Temporarily removed to transition to Alpine linux
# ARG JLINK_VERSION=884
# ARG JLINK_URL="https://www.segger.com/downloads/jlink/JLink_Linux_V${JLINK_VERSION}_x86_64.tgz"
# ARG JLINK_MD5="73e5713443df97785594f890e03fab2f"
# ARG JLINK_POST="accept_license_agreement=accepted&submit=Download+software"
# ARG JLINK_INSTALL_DIR="/opt/SEGGER/JLink"

# # Download and install package
# RUN curl -sLO -d ${JLINK_POST} -X POST ${JLINK_URL} && \
#     echo "${JLINK_MD5} $(basename ${JLINK_URL})" | md5sum -c - && \
#     mkdir -p ${JLINK_INSTALL_DIR} && \
#     tar -xf $(basename "${JLINK_URL}") -C ${JLINK_INSTALL_DIR} --strip-components=1 && \
#     rm $(basename "${JLINK_URL}")
# # Workaround for JFlash not starting correctly, see:
# # https://forum.segger.com/thread/8238-solved-j-flash-v7-54d-error-could-not-open-flash-device-list-file/?postID=30359#post30359
# RUN find ${JLINK_INSTALL_DIR} -name "J*" -exec sh -c 'for f in $@; do ln -Tsf $f /usr/bin/$(basename "$f"); done' {} +

#- Devcontainer utilities ------------------------------------------------------
ARG UTILS_INSTALL_DIR="/opt/devcontainer/"

# Add setup files and register in path
COPY setup-devcontainer ${UTILS_INSTALL_DIR}/bin/
COPY install-rules ${UTILS_INSTALL_DIR}
COPY cmake-tools-kits.json ${UTILS_INSTALL_DIR}
ENV PATH=$PATH:${UTILS_INSTALL_DIR}/bin

#- User setup ------------------------------------------------------------------
# Add plugdev group for non-root ttyUSB access and dialout group for non-root debugger access
RUN usermod -aG dialout vscode && usermod -aG plugdev vscode

USER vscode

VOLUME [ "/workspaces" ]
WORKDIR /workspaces
