FROM ubuntu:focal
LABEL maintainer="GeoPD <geoemmanuelpd2001@gmail.com>"
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /tmp

RUN apt-get -yqq update \
    && apt-get install --no-install-recommends -yqq git-core gnupg flex bison build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 libncurses5 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig ca-certificates libssl-dev bc \
    && TZ=Asia/Kolkata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Setup GCC Toolchains
RUN export GCC_DIR=/tmp/gcc \
    && git clone --depth=1 https://github.com/mvaisakh/gcc-arm -b gcc-master $GCC_DIR/gcc32 \
    && git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 -b gcc-master $GCC_DIR/gcc64

VOLUME ["/tmp/gcc"]
ENTRYPOINT ["/bin/bash"]
