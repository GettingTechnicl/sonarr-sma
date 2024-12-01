FROM ghcr.io/linuxserver/sonarr
LABEL maintainer="mdhiggins <mdhiggins23@gmail.com>"

ENV SMA_PATH="/usr/local/sma"
ENV SMA_RS="Sonarr"
ENV SMA_UPDATE="false"
ENV SMA_FFMPEG_PATH="/usr/local/bin/ffmpeg"
ENV SMA_FFPROBE_PATH="/usr/local/bin/ffprobe"

# Install build tools and runtime dependencies
RUN apk update && apk add --no-cache \
    git \
    wget \
    python3 \
    py3-pip \
    py3-virtualenv \
    ca-certificates \
    gcc \
    g++ \
    make \
    musl-dev \
    libgcc \
    libstdc++ \
    yasm \
    nasm \
    x264-dev \
    x265-dev \
    libvpx-dev \
    libvorbis-dev \
    libopus-dev \
    lame-dev \
    zlib-dev \
    libwebp-dev \
    libtheora-dev && \
    # Clone FFmpeg source code and build
    git clone --depth=1 https://github.com/FFmpeg/FFmpeg.git /tmp/ffmpeg && \
    cd /tmp/ffmpeg && \
    ./configure --prefix=/usr/local \
                --disable-debug \
                --enable-gpl \
                --enable-nonfree \
                --enable-libx264 \
                --enable-libx265 \
                --enable-libvpx \
                --enable-libvorbis \
                --enable-libopus \
                --enable-libmp3lame \
                --enable-libwebp \
                --enable-libtheora && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/ffmpeg && \
    # Clean up build dependencies
    apk del gcc g++ make musl-dev && \
    rm -rf /var/cache/apk/*

# Set up Sickbeard MP4 Automator
RUN mkdir -p ${SMA_PATH} && \
    git config --global --add safe.directory ${SMA_PATH} && \
    git clone https://github.com/mdhiggins/sickbeard_mp4_automator.git ${SMA_PATH} && \
    python3 -m virtualenv ${SMA_PATH}/venv && \
    ${SMA_PATH}/venv/bin/pip install -r ${SMA_PATH}/setup/requirements.txt && \
    apk del py3-virtualenv && \
    rm -rf /root/.cache /tmp/*

EXPOSE 8989

VOLUME /config
VOLUME /usr/local/sma/config

COPY extras/ ${SMA_PATH}/
COPY root/ /
