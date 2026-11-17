#!/bin/sh
set -eu

version=9.0.3
checksum=a81acdd21b76228981f6332b0e7f2166e297528d756fb0099d98930d58eb51c3
bundle=GoogleMVFaceDetectorResources.bundle
model=blazeface.tfl
cache_dir="$1/$version"
destination="$2/$bundle"

# SwiftPM links the detector, but ML Kit loads its model from the app bundle.
mkdir -p "$cache_dir" "$2"
if [ ! -f "$cache_dir/$bundle/$model" ]; then
    temp_dir="$(mktemp -d "$cache_dir/download.XXXXXX")"
    trap 'rm -rf "$temp_dir"' EXIT
    # GoogleMVFaceDetectorResources.bundle.zip from the upstream 9.0.3 release.
    url="https://api.github.com/repos/d-date/google-mlkit-swiftpm/releases/assets/734074598"
    curl --fail --location --silent --show-error --retry 2 --connect-timeout 15 \
        --max-time 120 --header 'Accept: application/octet-stream' "$url" \
        -o "$temp_dir/$bundle.zip"
    printf '%s  %s\n' "$checksum" "$bundle.zip" |
        (cd "$temp_dir" && shasum -a 256 --check)
    unzip -q "$temp_dir/$bundle.zip" -d "$temp_dir"
    test -f "$temp_dir/$bundle/$model"
    # The temporary directory is on the same volume as the cache.
    rm -rf "$cache_dir/$bundle"
    mv "$temp_dir/$bundle" "$cache_dir/$bundle"
fi

rm -rf "$destination"
ditto "$cache_dir/$bundle" "$destination"
