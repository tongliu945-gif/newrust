#!/usr/bin/env bash
# Android uses mediacodec (Android native API), not hwcodec (requires FFmpeg)
cargo ndk --platform 21 --target armv7-linux-androideabi build --release --features flutter,mediacodec
