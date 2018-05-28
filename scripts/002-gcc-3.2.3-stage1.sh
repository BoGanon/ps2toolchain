#!/bin/bash
# gcc-3.2.3-stage1.sh by AKuHAK
# Based on gcc-3.2.2-stage1.sh by Naomi Peori (naomi@peori.ca)

# Source the PS2DEV environment
source ../ps2dev.sh || { exit 1; }

GCC_VERSION=3.2.3
## Download the source code.
SOURCE=http://ftpmirror.gnu.org/gcc/gcc-$GCC_VERSION/gcc-core-$GCC_VERSION.tar.bz2
if [ ! -e gcc-core-$GCC_VERSION.tar.bz2 ]; then
	wget --continue $SOURCE || { exit 1; }
fi

SOURCE=http://ftpmirror.gnu.org/gcc/gcc-$GCC_VERSION/gcc-g++-$GCC_VERSION.tar.bz2
if [ ! -e gcc-g++-$GCC_VERSION.tar.bz2 ]; then
	wget --continue $SOURCE || { exit 1; }
fi

## Unpack the source code.
echo Decompressing GCC $GCC_VERSION. Please wait.
rm -Rf gcc-$GCC_VERSION && tar xfj gcc-core-$GCC_VERSION.tar.bz2 && tar xfj gcc-g++-$GCC_VERSION.tar.bz2 || { exit 1; }

## Enter the source directory and patch the source code.
cd gcc-$GCC_VERSION || { exit 1; }
if [ -e ../../patches/gcc-$GCC_VERSION-PS2.patch ]; then
	cat ../../patches/gcc-$GCC_VERSION-PS2.patch | patch -p1 || { exit 1; }
fi

OSVER=$(uname)
## Apple needs to pretend to be linux
if [ ${OSVER:0:6} == Darwin ]; then
	TARG_XTRA_OPTS="--build=i386-linux-gnu --host=i386-linux-gnu"
else
	TARG_XTRA_OPTS=""
fi

## Determine the maximum number of processes that Make can work with.
## MinGW's Make doesn't work properly with multi-core processors.
if [ ${OSVER:0:10} == MINGW32_NT ]; then
	PROC_NR=2
elif [ ${OSVER:0:6} == Darwin ]; then
	PROC_NR=$(sysctl -n hw.ncpu)
else
	PROC_NR=$(nproc)
fi

## Move outside of source directory.
cd .. || { exit 1; }

## For each target...
for TARGET in "ee" "iop"; do

	## Create and enter the build directory.
	rm -Rf build-$TARGET-stage1 && mkdir build-$TARGET-stage1 && cd build-$TARGET-stage1 || { exit 1; }

	## Configure the build.
	if [ ${OSVER:0:6} == Darwin ]; then
		CC=/usr/bin/gcc CXX=/usr/bin/g++ LD=/usr/bin/ld CFLAGS="-O0 -ansi -Wno-implicit-int -Wno-return-type" ../gcc-$GCC_VERSION/configure --prefix="$PS2DEV/$TARGET" --target="$TARGET" --enable-languages="c" --with-newlib --without-headers $TARG_XTRA_OPTS || { exit 1; }
	else
		../gcc-$GCC_VERSION/configure --prefix="$PS2DEV/$TARGET" --target="$TARGET" --enable-languages="c" --with-newlib --without-headers $TARG_XTRA_OPTS || { exit 1; }
	fi

	## Compile and install.
	make clean && make -j $PROC_NR && make install && make clean || { exit 1; }

	## Exit the build directory.
	cd .. || { exit 1; }

	## End target.
done
