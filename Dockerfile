# A toolchain that builds all seven programs: Ubuntu 18.04 is the last Ubuntu release that packages
# OpenCV 3 (3.2, contrib modules included), which these programs need. CI builds this image too.
#
#   docker build -t ntou-cs-opencv-hw .
#
# The programs end up in /src/build inside the image.
FROM ubuntu:18.04

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      cmake make g++ libopencv-dev libopencv-contrib-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .
RUN mkdir build && cd build && cmake .. && make -j"$(nproc)"
