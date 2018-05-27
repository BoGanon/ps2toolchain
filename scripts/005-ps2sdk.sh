#!/bin/bash
# ps2sdk.sh by Naomi Peori (naomi@peori.ca)
# changed to use Git by Mathias Lafeldt <misfire@debugon.org>

# make sure ps2sdk's makefile does not use it
unset PS2SDKSRC

## Download the source code.
if test ! -d "ps2sdk/.git"; then
	git clone https://github.com/ps2dev/ps2sdk && cd ps2sdk || exit 1
else
	cd ps2sdk &&
		git pull && git fetch origin &&
		git reset --hard origin/master || exit 1
fi

## Determine the maximum number of processes that Make can work with.
## MinGW's Make doesn't work properly with multi-core processors.
OSVER=$(uname)
if [ ${OSVER:0:10} == MINGW32_NT ]; then
	PROC_NR=2
elif [ ${OSVER:0:6} == Darwin ]; then
	PROC_NR=$(sysctl -n hw.ncpu)
else
	PROC_NR=$(nproc)
fi

## Build and install
make clean && make -j $PROC_NR && make install && make clean || { exit 1; }

