[![Build Status](https://travis-ci.org/fuzzitdev/example-swift.svg?branch=master)](https://travis-ci.org/fuzzitdev/example-swift)
[![fuzzit](https://app.fuzzit.dev/badge?org_id=fuzzitdev&branch=master)](https://fuzzit.dev)

# Continuous Fuzzing for Swift Example

This is an example of how to integrate [libFuzzer](https://github.com/apple/swift/blob/master/docs/libFuzzerIntegration.rst)
targets with the [Fuzzit](https://fuzzit.dev) Continuous Fuzzing Platform.

This example will show the following steps:
* [Building and running a simple libfuzzer target locally](#building-libfuzzer-target)
* [Integrate the libFuzzer target with Fuzzit via Travis-CI](#integrating-with-fuzzit-from-ci)

Result:
* Fuzzit will run the fuzz targets continuously on a daily basis with the latest release.
* Fuzzit will run regression tests on every pull-request with the generated corpus and crashes to catch bugs early on.

Fuzzing for swift can help find both complex bugs, security bugs and correctness bugs.

This tutorial focuses less on how to build libFuzzer targets and more on how to integrate the targets with Fuzzit. A lot of 
great information is available at the [libFuzzer Tutorial](https://llvm.org/docs/LibFuzzer.html) and [Swift libFuzzer](https://github.com/apple/swift/blob/master/docs/libFuzzerIntegration.rst).

## Building libFuzzer Target



### Understanding the bug

The bug is located at `main.swift` in the following code

```swift
    if
        buffer[0] == 0x46,
        buffer[1] == 0x55,
        buffer[2] == 0x5a,
        buffer[3] == 0x5a,
        buffer[4] == 0x49,
        buffer[5] == 0x65
    {
        fatalError()
    }
```

This is the simplest example to demonstrate how libFuzzer find a specified input (`FUZZIT`) that triggers `fatalErro`
using guided code coverage fuzzing.


### Setting up the development environment

libFuzzer is built-in in swift toolchain in the latest development releases. We created a [docker](https://github.com/fuzzitdev/fuzzit/blob/master/docker/ubuntu/bionic/swift/Dockerfile)
image with bionic-swift-5.1-dev and clang-9 hosted at `gcr.io/fuzzit-public/bionic-swift51`

```bash
docker run -it gcr.io/fuzzit-public/bionic-swift51:beb0e9b /bin/bash

# Build libFuzzer target
git clone https://github.com/fuzzitdev/example-swift
cd example-swift
swift build -c release -Xswiftc -sanitize=fuzzer -Xswiftc -parse-as-library

# Run libFuzzer
./.build/release/example-swift
```

Will print the following output and stacktrace:

```text
==66== ERROR: libFuzzer: deadly signal
    #0 0x558dcccbfb2f in __sanitizer_print_stack_trace /home/buildnode/jenkins/workspace/oss-swift-package-linux-ubuntu-18_04/llvm/projects/compiler-rt/lib/ubsan/ubsan_diag_standalone.cc:29:3
    #1 0x558dccc3f798 in fuzzer::PrintStackTrace() /home/buildnode/jenkins/workspace/oss-swift-package-linux-ubuntu-18_04/llvm/projects/compiler-rt/lib/fuzzer/FuzzerUtil.cpp:206:5
    #2 0x558dccc29ff8 in fuzzer::Fuzzer::CrashCallback() /home/buildnode/jenkins/workspace/oss-swift-package-linux-ubuntu-18_04/llvm/projects/compiler-rt/lib/fuzzer/FuzzerLoop.cpp:237:3
    #3 0x558dccc29fbf in fuzzer::Fuzzer::StaticCrashSignalCallback() /home/buildnode/jenkins/workspace/oss-swift-package-linux-ubuntu-18_04/llvm/projects/compiler-rt/lib/fuzzer/FuzzerLoop.cpp:209:6
    #4 0x7f21dcf8688f  (/lib/x86_64-linux-gnu/libpthread.so.0+0x1288f)
    #5 0x7f21dd4e6400 in $ss17_assertionFailure__4file4line5flagss5NeverOs12StaticStringV_SSAHSus6UInt32VtFTf4xxnnn_n (/usr/lib/swift/linux/libswiftCore.so+0x353400)
    #6 0x7f21dd2e0e38 in $ss17_assertionFailure__4file4line5flagss5NeverOs12StaticStringV_SSAHSus6UInt32VtF (/usr/lib/swift/linux/libswiftCore.so+0x14de38)
    #7 0x558dcccc00fa in $s13example_swift6fuzzMe4data4sizes5Int32VSPys4Int8VG_AFtF (/app/example-swift/.build/x86_64-unknown-linux/release/example-swift+0xb10fa)
    #8 0x558dccc2b54a in fuzzer::Fuzzer::ExecuteCallback(unsigned char const*, unsigned long) /home/buildnode/jenkins/workspace/oss-swift-package-linux-ubuntu-18_04/llvm/projects/compiler-rt/lib/fuzzer/FuzzerLoop.cpp:571:15
    #9 0x558dccc2ac95 in fuzzer::Fuzzer::RunOne(unsigned char const*, unsigned long, bool, fuzzer::InputInfo*, bool*) /home/buildnode/jenkins/workspace/oss-swift-package-linux-ubuntu-18_04/llvm/projects/compiler-rt/lib/fuzzer/FuzzerLoop.cpp:480:3
    #10 0x558dccc2c6ab in fuzzer::Fuzzer::MutateAndTestOne() /home/buildnode/jenkins/workspace/oss-swift-package-linux-ubuntu-18_04/llvm/projects/compiler-rt/lib/fuzzer/FuzzerLoop.cpp:708:19
    #11 0x558dccc2d385 in fuzzer::Fuzzer::Loop(std::Fuzzer::vector<std::Fuzzer::basic_string<char, std::Fuzzer::char_traits<char>, std::Fuzzer::allocator<char> >, fuzzer::fuzzer_allocator<std::Fuzzer::basic_string<char, std::Fuzzer::char_traits<char>, std::Fuzzer::allocator<char> > > > const&) /home/buildnode/jenkins/workspace/oss-swift-package-linux-ubuntu-18_04/llvm/projects/compiler-rt/lib/fuzzer/FuzzerLoop.cpp:839:5
    #12 0x558dccc26dab in fuzzer::FuzzerDriver(int*, char***, int (*)(unsigned char const*, unsigned long)) /home/buildnode/jenkins/workspace/oss-swift-package-linux-ubuntu-18_04/llvm/projects/compiler-rt/lib/fuzzer/FuzzerDriver.cpp:764:6
    #13 0x558dccc3fe32 in main /home/buildnode/jenkins/workspace/oss-swift-package-linux-ubuntu-18_04/llvm/projects/compiler-rt/lib/fuzzer/FuzzerMain.cpp:20:10
    #14 0x7f21dc1e2b96 in __libc_start_main (/lib/x86_64-linux-gnu/libc.so.6+0x21b96)
    #15 0x558dccc21279 in _start (/app/example-swift/.build/x86_64-unknown-linux/release/example-swift+0x12279)

NOTE: libFuzzer has rudimentary signal handlers.
      Combine libFuzzer with AddressSanitizer or similar for better crash reports.
SUMMARY: libFuzzer: deadly signal
MS: 2 InsertByte-InsertRepeatedBytes-; base unit: 53bc6cb455c00ab402de0304ec2fb992cf8498bc
0x46,0x55,0x5a,0x5a,0x49,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x65,0x3a,0x5a,
FUZZIeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee:Z
artifact_prefix='./'; Test unit written to ./crash-207ef2bb62cc2acee33ea863800c4aa638118df2
Base64: RlVaWkllZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZWVlZTpa

```

## Integrating with Fuzzit from CI

The best way to integrate with Fuzzit is by adding a two stages in your Continuous Build system
(like Travis CI or Circle CI).

Fuzzing stage:

* Build a fuzzing target
* Download `fuzzit` cli
* Authenticate via passing `FUZZIT_API_KEY` environment variable
* Create a fuzzing job by uploading the fuzzing target

Regression stage
* Build a fuzzing target
* Download `fuzzit` cli
* Authenticate via passing `FUZZIT_API_KEY` environment variable OR defining the corpus as public. This way
No authentication would be require and regression can be used for [forked PRs](https://docs.travis-ci.com/user/pull-requests#pull-requests-and-security-restrictions) as well
* Create a local regression fuzzing job - This will pull all the generated corpuses and run them through
the fuzzing binary. If new bugs are introduced this will fail the CI and alert

Here is the relevant snippet from the [fuzzit.sh](https://github.com/fuzzitdev/example-swift/blob/master/fuzzit.sh)
which is being run by [.travis.yml](https://github.com/fuzzitdev/example-swift/blob/master/.travis.yml)

```bash
wget -q -O fuzzit https://github.com/fuzzitdev/fuzzit/releases/download/v2.4.17/fuzzit_Linux_x86_64
chmod a+x fuzzit

## upload fuzz target for long fuzz testing on fuzzit.dev server or run locally for regression
./fuzzit create job --type ${1} --host bionic-swift51 fuzzitdev/example-swift ./.build/release/example-swift
``` 

In production it is advised to download a pinned version of the [CLI](https://github.com/fuzzitdev/fuzzit)
like in the example. In development you can use the latest version:
https://github.com/fuzzitdev/fuzzit/releases/latest/download/fuzzit_${OS}_${ARCH}.
Valid values for `${OS}` are: `Linux`, `Darwin`, `Windows`.
Valid values for `${ARCH}` are: `x86_64` and `i386`.
