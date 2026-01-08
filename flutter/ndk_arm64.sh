#!/usr/bin/env bash
# Android uses mediacodec (Android native API), not hwcodec (requires FFmpeg)
cargo ndk --platform 21 --target aarch64-linux-android build --release --features flutter,mediacodec
