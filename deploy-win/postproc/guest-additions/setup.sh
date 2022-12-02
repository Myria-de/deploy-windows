#!/bin/bash
mnt="$(readlink -f "$1")"
my_dir="$(dirname "$0")"
cd "$my_dir"
cp vboxpost.cmd "$mnt"



