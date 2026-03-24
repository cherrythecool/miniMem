#! /bin/sh

mkdir -p bin
cc src/main.m -framework AppKit -framework Foundation -O3 -Wall -o bin/miniMem