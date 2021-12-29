#!/usr/bin/env bash

set -e

[[ -z "$1" ]] && printf '%s\n%s\n' "usage: build.sh <version>" "e.g. build.sh 6.8.0p2" && exit 1

printf '%s\n' "Building version: $1"

sed "s/@VERSION@/${1}/g" Dockerfile.in > Dockerfile

sudo docker build -t "opensmtpd:${1}" .
