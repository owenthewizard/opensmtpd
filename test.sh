#!/usr/bin/env bash

set -e
sed 's/@VERSION@/6.8.0p2/g' Dockerfile.in > Dockerfile
docker build -t opensmtpd:test . && docker run -it --rm opensmtpd:test
