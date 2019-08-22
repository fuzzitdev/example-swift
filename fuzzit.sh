#!/bin/bash
set -xe


docker run -v `pwd`:/app gcr.io/fuzzit-public/bionic-swift51 /bin/bash -c "swift build -c release -Xswiftc -sanitize=fuzzer -Xswiftc -parse-as-library"

## Install fuzzit specific version for production or latest version for development :
## https://github.com/fuzzitdev/fuzzit/releases/latest/download/fuzzit_Linux_x86_64
wget -q -O fuzzit https://github.com/fuzzitdev/fuzzit/releases/download/v2.4.31/fuzzit_Linux_x86_64
chmod a+x fuzzit

## upload fuzz target for long fuzz testing on fuzzit.dev server or run locally for regression
./fuzzit create job --type ${1} --host bionic-swift51 fuzzitdev/example-swift ./.build/release/example-swift
