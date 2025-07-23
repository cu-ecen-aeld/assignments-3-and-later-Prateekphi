#!/bin/bash

qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a53 \
  -nographic \
  -smp 1 \
  -m 1024M \
  -kernel Image \
  -append "console=ttyAMA0" \
  -initrd initramfs.cpio.gz
