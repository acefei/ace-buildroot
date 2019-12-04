FROM debian:10

LABEL maintainer "acefei"

ENV DEBIAN_FRONTEND=noninteractive 

RUN apt-get update && apt-get install -y \
    build-essential \
    libncurses5-dev \
    libguestfs-tools \
    bc unzip \
    rsync cpio wget sudo \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && adduser --disabled-password --gecos "" build \
    && echo "build ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers 

USER build
