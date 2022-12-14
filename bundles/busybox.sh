#!/bin/bash
# DNS not working, requires glibc nss libraries

set -euo pipefail

source_url="https://busybox.net/downloads/busybox-1.35.0.tar.bz2"
source_dir="busybox-1.35.0"

pushd $sources_dir
    if [ ! -d $source_dir ]
    then
        wget -qO- $source_url | tar -xj
    fi

    pushd $source_dir
        cp -v $config_dir/busybox.config busybox.config
        cp busybox.config .config
        make -j$(nproc)
        strip busybox

        mkdir -pv ./bin
        cp -pv busybox ./bin
        
        pushd bin
            for e in $(./busybox --list);
            do
                ln -svf busybox $e
            done
        popd

        cp -vP bin/* $rootfs_dir/bin
        ln -svf ../bin/init $rootfs_dir/sbin/init
    popd
popd
