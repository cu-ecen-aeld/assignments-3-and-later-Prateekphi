#!/bin/bash
# Author: Siddhant Jajoo

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
FINDER_APP_DIR=$(realpath $(dirname $0)/../finder-app)
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)

if [ $# -ge 1 ]; then
    OUTDIR=$1
fi
echo "Using output directory: ${OUTDIR}"
mkdir -p ${OUTDIR}

cd "$OUTDIR"
# Clone and build kernel
if [ ! -d linux-stable ]; then
    echo "Cloning Linux stable kernel..."
    git clone ${KERNEL_REPO} --depth 1 --branch ${KERNEL_VERSION}
fi

if [ ! -e linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
    cd ..
fi

echo "Kernel build complete. Creating rootfs..."

# Create root filesystem directory structure
cd "$OUTDIR"
if [ -d rootfs ]; then
    sudo rm -rf rootfs
fi

mkdir -p rootfs/{bin,sbin,etc,proc,sys,usr/{bin,sbin},dev,lib,lib64,home}
mkdir -p rootfs/home/conf

# Clone and build BusyBox
if [ ! -d busybox ]; then
    git clone git://busybox.net/busybox.git
fi

cd busybox
git checkout ${BUSYBOX_VERSION}
make distclean
make defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=$OUTDIR/rootfs install

# Add library dependencies
cd "$OUTDIR"
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)

cp -a ${SYSROOT}/lib/ld-linux-aarch64.so.1 rootfs/lib || echo "ld-linux-aarch64.so.1 not found"
cp -a ${SYSROOT}/lib64/libc.so.6 rootfs/lib64 || echo "libc.so.6 not found"
cp -a ${SYSROOT}/lib64/ld-linux-aarch64.so.1 rootfs/lib64 || echo "ld-linux-aarch64.so.1 not found"

# Create device nodes
sudo mknod -m 666 rootfs/dev/null c 1 3
sudo mknod -m 600 rootfs/dev/console c 5 1

# Build writer utility
cd "${FINDER_APP_DIR}"
make clean
make CROSS_COMPILE=${CROSS_COMPILE}

# Copy finder scripts and apps
cp writer rootfs/home/
cp finder.sh rootfs/home/
cp finder-test.sh rootfs/home/
cp -r "${FINDER_APP_DIR}/conf" rootfs/home/
chmod +x rootfs/home/finder.sh
chmod +x rootfs/home/finder-test.sh
echo "Files copied to rootfs/home:"
ls -l rootfs/home/
echo "Contents of conf:"
ls -l rootfs/home/conf/

# Set permissions
sudo chown -R root:root rootfs

# Create init file
cat << EOF > rootfs/init
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
echo "Init script running..."
/bin/sh
EOF

chmod +x rootfs/init

# Create initramfs
cd rootfs
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
cd ..
gzip -f initramfs.cpio

echo "Initramfs and kernel image are ready:"
echo "- ${OUTDIR}/linux-stable/arch/arm64/boot/Image"
echo "- ${OUTDIR}/initramfs.cpio.gz"

