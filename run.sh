#!/bin/sh

[ "$1" ] || {
    echo "Specify which flavor of busybox to build:"
    ls -d */
    exit 1
    }
[ -d "$1" ] || {
    echo "Could not find directory $1."
        exit 1
    }

sudo docker build -t tarmaker:$1 $1/tarmaker || {
    echo "Something went wrong. Aborting."
        exit 1
    }

[ -f $1/tarmaker/rootfs.tar ] && mv $1/tarmaker/rootfs.tar $1/tarmaker/rootfs.tar.old
[ -f $1/tarmaker/rootfs.tar.md5 ] && mv $1/tarmaker/rootfs.tar.md5 $1/tarmaker/rootfs.tar.md5.old

sudo docker run --name builder-$1 tarmaker:$1
sudo docker cp builder-$1:/tmp/rootfs.tar $1
sudo docker cp builder-$1:/tmp/rootfs.tar.md5 $1
sudo chown 1000:1000 $1/rootfs*

cd $1
if md5sum --check rootfs.tar.md5; then
    sudo docker rm -f builder-$1 &&\
    sudo docker rmi tarmaker:$1 &&\
    # We must wait until all removal is done before next step
    sudo docker build -t busyboxplus:$1 .
else
    echo "Checksum failed. Aborting."
    echo "Note: the tarmaker:$1 image and builder-$1 container have not been deleted."
    exit 1
fi
