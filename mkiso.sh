#!/bin/bash
set -euo pipefail

commands=(
    realpath
    cp
    bc
    wget
    tar
    make
    gcc
    flex
    bison
    strip
    find
    cpio
    gzip
    bzip2
    mkisofs
)

# check for existance
all_commands_exist=0
for cmd in "${commands[@]}"
do
    if ! command -v $cmd &> /dev/null
    then
        echo "$cmd could not be found"
        all_commands_exist=1
    fi
done
if [ $all_commands_exist -eq 1 ]
then
    exit 1
fi

force_kernel=""
for arg in "$@"
do
    if [ $arg = "kernel" ]; then
        force_kernel=yes
    fi
done

run_dir=$(pwd)
run_dir=$(realpath $run_dir)
build_dir="${run_dir}/build"
sources_dir="${build_dir}/sources"
config_dir="${run_dir}/config"
iso_dir=${run_dir}
rootfs_dir="${build_dir}/rootfs"
pack_dir="${build_dir}/pack"

mkdir -pv $build_dir
mkdir -pv $sources_dir
mkdir -pv $pack_dir

mkdir -pv $rootfs_dir
cp -rv $run_dir/rootfs/* $rootfs_dir
find $rootfs_dir -name ".keep" -delete 

export sources_dir config_dir pack_dir rootfs_dir force_kernel
./bundles/busybox_uclibc.sh
./bundles/kernel.sh
./bundles/isolinux.sh

pushd $rootfs_dir
    find . | cpio -o -H newc | gzip - > $pack_dir/isolinux/initrd.gz
popd

echo "Make iso"
mkisofs -R -l -L -D \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -input-charset ascii \
        -no-emul-boot -boot-load-size 4 \
        -boot-info-table \
        -V NET \
        $pack_dir \
        > $iso_dir/net.iso
