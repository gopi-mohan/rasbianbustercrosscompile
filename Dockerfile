#Reference : https://github.com/sdhibit/docker-rpi-raspbian
#https://hub.docker.com/r/sdthirlwall/raspberry-pi-cross-compiler/
FROM debian:buster
RUN printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d
RUN apt-get update 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils 
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure apt-utils 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y automake 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y cmake 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y fakeroot 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y g++ 
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y make 
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y runit 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y sudo 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y xz-utils
RUN apt-get install -y pkg-config
RUN apt-get install ca-certificates
RUN update-ca-certificates -f

# Here is where we hardcode the toolchain decision.
ENV HOST=arm-linux-gnueabihf \
    TOOLCHAIN=gcc-linaro-arm-linux-gnueabihf-raspbian-x64 \
    RPXC_ROOT=/rpxc


WORKDIR $RPXC_ROOT

RUN curl -L https://github.com/raspberrypi/tools/tarball/master \
  | tar --wildcards --strip-components 3 -xzf - "*/arm-bcm2708/$TOOLCHAIN/"

ENV ARCH=arm \
    CROSS_COMPILE=$RPXC_ROOT/bin/$HOST- \
    PATH=$RPXC_ROOT/bin:$PATH \
    QEMU_PATH=/usr/bin/qemu-arm-static \
    QEMU_EXECVE=1 \
    SYSROOT=$RPXC_ROOT/sysroot
WORKDIR $SYSROOT
COPY raspbian.15Dec2021.tar.xz .

RUN tar -xJf ./raspbian.15Dec2021.tar.xz 
RUN curl -Ls https://github.com/resin-io-projects/armv7hf-debian-qemu/raw/master/bin/qemu-arm-static \
    > $SYSROOT/$QEMU_PATH \
 && chmod +x $SYSROOT/$QEMU_PATH \
 && mkdir -p $SYSROOT/build 

RUN chroot $SYSROOT $QEMU_PATH /bin/sh -c '\
        echo "deb http://archive.raspbian.org/raspbian buster firmware" \
            >> /etc/apt/sources.list \
        && apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils \
        && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure apt-utils \
        && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y \
                libc6-dev \
                symlinks \
		libssl-dev \
		pkg-config \
        && symlinks -cors /'

COPY image/ /

WORKDIR /build
ENTRYPOINT [ "/rpxc/entrypoint.sh" ]
