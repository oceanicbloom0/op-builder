# Base stage with build dependencies
FROM ubuntu:22.04 AS base

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    ack antlr3 aria2 asciidoc autoconf automake autopoint binutils bison build-essential \
    bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
    git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev \
    libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libreadline-dev libssl-dev libtool lrzsz \
    mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 python3-pip libpython3-dev qemu-utils \
    rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev python3-pyelftools \
    aria2 clang clangd ecj lib32gcc-s1 libfuse-dev libncursesw5 libpython3-dev lld lldb python3-ply re2c \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* \
&& update-ca-certificates

# Set timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# Toolchain stage
FROM base AS toolchain

ARG SOURCE_URL
ARG SOURCE_BRANCH
ARG DEVICE
ARG GITHUB_WORKSPACE=/workspace

WORKDIR /workspace

# Clone OpenWrt source code
RUN git clone ${SOURCE_URL} -b ${SOURCE_BRANCH} openwrt

# Copy configuration files
COPY . /workspace/

# Set up configuration for toolchain
WORKDIR /workspace/openwrt

# Generate toolchain config
RUN bash /workspace/scripts/openwrt/copy-config.sh \
    && make defconfig \
    && sed -i '/CONFIG_DEFAULT_luci/'d .config \
    && echo -e "\nCONFIG_ALL=y" >> .config \
    && echo -e "\nCONFIG_ALL_NONSHARED=y" >> .config \
    && make defconfig > /dev/null 2>&1
    
# Update and install feeds
RUN ./scripts/feeds update -a \
    && ./scripts/feeds install -a
    
# Compile toolchain and tools
RUN make defconfig \
    && make tools/compile -j$(nproc) || make tools/compile -j1 V=s \
    && make toolchain/compile -j$(nproc) || make toolchain/compile -j1 V=s
    
# Clean up unnecessary files
RUN rm -rf .config* dl bin

# Packages stage
FROM toolchain AS packages

ARG DEVICE
ARG GITHUB_WORKSPACE=/workspace

WORKDIR /workspace/openwrt

# Add packages
RUN chmod +x /workspace/scripts/openwrt/add-package.sh \
    && /workspace/scripts/openwrt/add-package.sh \
    && ./scripts/feeds update -a \
    && ./scripts/feeds install -a
    
# Update configuration
RUN bash /workspace/scripts/openwrt/copy-config.sh \
    && sed -i '/CONFIG_DEFAULT_luci/'d .config \
    && make defconfig
    
# Download packages
RUN make download -j8
    
# Copy files if present
RUN if [ -n "$(ls -A "/workspace/files" 2>/dev/null)" ]; then \
        cp -Rf /workspace/files/* ./ ; \
    fi
    
# Compile packages
RUN make diffconfig \
    && make target/compile -j$(nproc) IGNORE_ERRORS="m n" BUILD_LOG=1 || yes n | make target/compile -j1 V=s IGNORE_ERRORS=1 \
    && make package/compile -j$(nproc) IGNORE_ERRORS=1 || make package/compile -j1 V=s IGNORE_ERRORS=1 \
    && make package/index

# Firmware stage
FROM packages AS firmware

ARG DEVICE
ARG GITHUB_WORKSPACE=/workspace

WORKDIR /workspace/openwrt

# Create defaults directory
RUN mkdir -p files/etc/uci-defaults \
    && cp /workspace/scripts/openwrt/init-settings.sh files/etc/uci-defaults/99-init-settings
    
# Generate firmware
RUN make package/install -j$(nproc) || make package/install -j1 V=s \
    && make target/install -j$(nproc) || make target/install -j1 V=s \
    && make json_overview_image_info \
    && make checksum
    
# Clean up unnecessary files
RUN cd bin/targets/*/* \
    && rm -rf packages sha256* *manifest *.sha *info *kernel.bin *sha *json

# Prepare workspace for artifacts  
WORKDIR /workspace

# Create a directory for artifacts
RUN mkdir -p /artifacts \
    && cp -r openwrt/bin/targets/*/* /artifacts/ \
    && cp -r openwrt/bin/packages /artifacts/packages

# Output stage for packages only
FROM scratch AS output-packages
COPY --from=packages /workspace/openwrt/bin/packages /packages

# Output stage for firmware only
FROM scratch AS output-firmware
COPY --from=firmware /artifacts /firmware 