#!/bin/bash
set -e

# === Configuration ===
SCRIPT_DIR="$(realpath "$(dirname "$0")")"
FINDER_APP_DIR="$SCRIPT_DIR/../finder-app"

OUTDIR=$(realpath "${1:-./output}")
KERNEL_REPO="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git"
KERNEL_VERSION="v5.15.126"
KERNEL_DIR="$OUTDIR/linux"
BUSYBOX_VERSION="1.36.1"
BUSYBOX_DIR="$OUTDIR/busybox"
ROOTFS="$OUTDIR/rootfs"

# === Prepare Output Directory ===
mkdir -p "$OUTDIR"

# === Clone and Build Linux Kernel ===
echo "=== Cloning Linux kernel ==="
if [ ! -d "$KERNEL_DIR" ]; then
    git clone --depth 1 --branch "$KERNEL_VERSION" "$KERNEL_REPO" "$KERNEL_DIR"
else
    echo "Linux kernel already cloned."
fi

echo "=== Building Linux kernel ==="
cd "$KERNEL_DIR"
make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- mrproper
make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- defconfig
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- all
echo "=== Kernel build complete ==="

# === Download and Build BusyBox ===
cd "$OUTDIR"
echo "=== Downloading and extracting BusyBox ==="
if [ ! -d "$BUSYBOX_DIR" ]; then
    wget https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
    tar -xf busybox-${BUSYBOX_VERSION}.tar.bz2
    mv busybox-${BUSYBOX_VERSION} "$BUSYBOX_DIR"
else
    echo "BusyBox already present."
fi

echo "=== Building BusyBox ==="
cd "$BUSYBOX_DIR"
make distclean
make defconfig
sed -i 's/.*CONFIG_STATIC.*/CONFIG_STATIC=y/' .config
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu-
make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- install
echo "=== BusyBox build and install complete ==="

# === Create Root Filesystem ===
echo "=== Setting up Root Filesystem ==="
rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"

# Create required directories
mkdir -p "$ROOTFS"/{bin,sbin,etc,proc,sys,usr/{bin,sbin},dev,home,tmp,var/log,lib,lib64}

# Copy BusyBox files
echo "Copying BusyBox files to rootfs..."
cp -a "$BUSYBOX_DIR/_install/"* "$ROOTFS/"

# Create init script
cat << EOF > "$ROOTFS/init"
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs devtmpfs /dev
echo "Init script running..."
exec /bin/sh
EOF

chmod +x "$ROOTFS/init"

# === Copy finder-app scripts and writer ===
CROSS_COMPILE=aarch64-none-linux-gnu-

for file in writer finder.sh finder-test.sh; do
  if [ ! -f "$FINDER_APP_DIR/$file" ]; then
    echo "Error: $file not found in $FINDER_APP_DIR"
    exit 1
  fi
done

echo "Copying writer and scripts from $FINDER_APP_DIR..."

cp "$FINDER_APP_DIR"/writer "$ROOTFS/home/"
cp "$FINDER_APP_DIR"/finder.sh "$ROOTFS/home/"
cp "$FINDER_APP_DIR"/finder-test.sh "$ROOTFS/home/"
chmod +x "$ROOTFS/home/writer"
chmod +x "$ROOTFS/home/finder.sh" "$ROOTFS/home/finder-test.sh"

# Create and copy conf directory
mkdir -p "$ROOTFS/home/conf"

if [ ! -f "$FINDER_APP_DIR/conf/username.txt" ]; then
    echo "Error: username.txt not found in $FINDER_APP_DIR/conf/"
    exit 1
fi

cp "$FINDER_APP_DIR/conf/username.txt" "$ROOTFS/home/conf/"

# === Copy autorun-qemu.sh ===
if [ ! -f "$FINDER_APP_DIR/autorun-qemu.sh" ]; then
    echo "Error: autorun-qemu.sh not found in $FINDER_APP_DIR"
    exit 1
fi

cp "$FINDER_APP_DIR/autorun-qemu.sh" "$ROOTFS/home/"
chmod +x "$ROOTFS/home/autorun-qemu.sh"

# === Library dependencies ===
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
echo "Copying necessary libraries from sysroot: $SYSROOT"

cp -v "$SYSROOT"/lib64/libc.so.6 "$ROOTFS/lib64/" || echo "Warning: libc.so.6 not found"
cp -v "$SYSROOT"/lib64/ld-linux-aarch64.so.1 "$ROOTFS/lib64/" || echo "Warning: ld-linux-aarch64.so.1 not found"

# === Create initramfs ===
echo "Creating initramfs..."
cd "$ROOTFS"
find . | cpio -H newc -ov --owner root:root > "$OUTDIR/initramfs.cpio"
gzip -f "$OUTDIR/initramfs.cpio"
cd -

echo "=== Build Complete: Kernel + BusyBox + RootFS + Initramfs ==="

