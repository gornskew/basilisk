# The hangar's species: a small Debian carrying Firecracker and its
# kernel and the hangar's scripts.  Built from the firecracker/
# directory as context:
#
#   cd ~/projects/basilisk/firecracker && docker build -f hangar/Dockerfile -t gornskew/hangar:trial .
#
# The room needs /dev/kvm and /dev/net/tun, NET_ADMIN and ip_forward
# (the articles' :devices, :cap-add and :sysctls), /deployments (the
# lab's deployed root, read-only) and /fc (the hangar's own volume: the
# hosted rootfs made by hangar/make-rootfs, the data disks, the run
# directory).  The hangar does no routing of its own: it registers each
# VM with the ship's cyclops, whose :hangar rule routes by host.
# hangar-init is PID 1's charge.
FROM debian:13-slim
ARG FC_VERSION=v1.17.0
ARG FC_KERNEL=firecracker-ci/v1.15/x86_64/vmlinux-6.1.155
ARG ARCH=x86_64
RUN apt-get -qq update && DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends \
    iproute2 iptables curl ca-certificates e2fsprogs procps jq && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/firecracker && cd /opt/firecracker \
    && curl -fsSL https://github.com/firecracker-microvm/firecracker/releases/download/$FC_VERSION/firecracker-$FC_VERSION-$ARCH.tgz \
       | tar xz --strip-components=1 release-$FC_VERSION-$ARCH/firecracker-$FC_VERSION-$ARCH \
    && mv firecracker-$FC_VERSION-$ARCH firecracker && chmod 755 firecracker \
    && curl -fsSL -o vmlinux https://s3.amazonaws.com/spec.ccfc.min/$FC_KERNEL
COPY hosted hosted-services-init.cl guest-init hangar/build-rootfs hangar/hangar-init /usr/local/lib/hangar/
RUN chmod 755 /usr/local/lib/hangar/hosted /usr/local/lib/hangar/hangar-init /usr/local/lib/hangar/guest-init
ENV FC_DIR=/fc FC_BIN=/opt/firecracker/firecracker FC_KERNEL=/opt/firecracker/vmlinux
LABEL basilisk.capabilities="hangar"
ENTRYPOINT ["/usr/local/lib/hangar/hangar-init"]
