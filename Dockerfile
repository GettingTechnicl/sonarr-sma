FROM ghcr.io/linuxserver/sonarr
LABEL maintainer="mdhiggins <mdhiggins23@gmail.com>"

ENV SMA_PATH /usr/local/sma
ENV SMA_RS Sonarr
ENV SMA_UPDATE false
ENV SMA_FFMPEG_PATH /usr/local/bin/ffmpeg
ENV SMA_FFPROBE_PATH /usr/local/bin/ffprobe
ENV SMA_FFMPEG_URL https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-linux64-gpl-shared.tar.xz

# Install dependencies, glibc, and NVIDIA-enabled FFmpeg
RUN \
  apk update && \
  apk add --no-cache \
    git \
    wget \
    python3 \
    py3-pip \
    py3-virtualenv \
    ca-certificates \
    libstdc++ \
    libgcc && \
  # Install glibc for compatibility with precompiled FFmpeg
  wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
  glibc_version=$(curl -s https://api.github.com/repos/sgerrand/alpine-pkg-glibc/releases/latest | grep '"tag_name"' | cut -d '"' -f 4) && \
  wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${glibc_version}/glibc-${glibc_version}.apk && \
  apk add --no-cache ./glibc-${glibc_version}.apk && \
  rm -f ./glibc-${glibc_version}.apk && \
  # Download and extract NVIDIA-enabled FFmpeg from BtbN
  wget -O /tmp/ffmpeg.tar.xz ${SMA_FFMPEG_URL} && \
  mkdir -p /tmp/ffmpeg && \
  tar -xvf /tmp/ffmpeg.tar.xz -C /tmp/ffmpeg && \
  mv /tmp/ffmpeg/ffmpeg-master-latest-linux64-gpl-shared/bin/ffmpeg /usr/local/bin/ && \
  mv /tmp/ffmpeg/ffmpeg-master-latest-linux64-gpl-shared/bin/ffprobe /usr/local/bin/ && \
  cp -r /tmp/ffmpeg/ffmpeg-master-latest-linux64-gpl-shared/lib/* /usr/glibc-compat/lib/ && \
  rm -rf /tmp/ffmpeg /tmp/ffmpeg.tar.xz && \
  chmod +x /usr/local/bin/ffmpeg /usr/local/bin/ffprobe

# Set up Sickbeard MP4 Automator
RUN \
  mkdir ${SMA_PATH} && \
  git config --global --add safe.directory ${SMA_PATH} && \
  git clone https://github.com/mdhiggins/sickbeard_mp4_automator.git ${SMA_PATH} && \
  python3 -m virtualenv ${SMA_PATH}/venv && \
  ${SMA_PATH}/venv/bin/pip install -r ${SMA_PATH}/setup/requirements.txt && \
  apk del --purge && \
  rm -rf /root/.cache /tmp/*

EXPOSE 8989

VOLUME /config
VOLUME /usr/local/sma/config

# update.py sets FFMPEG/FFPROBE paths, updates API key and Sonarr/Radarr settings in autoProcess.ini
COPY extras/ ${SMA_PATH}/
COPY root/ /
