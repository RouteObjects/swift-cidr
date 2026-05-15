#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

IMAGE="${CIDR_SWIFT_IMAGE:-swift:6.3}"
PLATFORM="${CIDR_LINUX_PLATFORM:-linux/amd64}"
PLATFORM_VOLUME_SUFFIX="${PLATFORM//[^[:alnum:]]/-}"
BUILD_VOLUME="${CIDR_LINUX_BUILD_VOLUME:-swift-cidr-linux-build-${PLATFORM_VOLUME_SUFFIX}}"
BENCHMARK_BUILD_VOLUME="${CIDR_LINUX_BENCHMARK_BUILD_VOLUME:-swift-cidr-linux-benchmarks-build-${PLATFORM_VOLUME_SUFFIX}}"
COMMAND="${1:-test}"

usage() {
    cat <<EOF
Usage: ./scripts/linux-test.sh [test|shell|benchmark-build|help]

Runs swift-cidr Linux validation in Docker using the official Swift image.

Environment:
  CIDR_SWIFT_IMAGE          Swift Docker image. Default: swift:6.3
  CIDR_LINUX_PLATFORM       Docker platform. Default: linux/amd64
  CIDR_LINUX_BUILD_VOLUME   Docker volume for Linux .build artifacts.
                            Default: swift-cidr-linux-build-<platform>
  CIDR_LINUX_BENCHMARK_BUILD_VOLUME
                            Docker volume for Benchmarks/.build artifacts.
                            Default: swift-cidr-linux-benchmarks-build-<platform>

Examples:
  ./scripts/linux-test.sh
  CIDR_LINUX_PLATFORM=linux/arm64 ./scripts/linux-test.sh
  ./scripts/linux-test.sh shell
  ./scripts/linux-test.sh benchmark-build
EOF
}

docker_args=(
    run
    --rm
    --platform "${PLATFORM}"
    --workdir /workspace
    --volume "${PACKAGE_ROOT}:/workspace"
    --volume "${BUILD_VOLUME}:/workspace/.build"
    --volume "${BENCHMARK_BUILD_VOLUME}:/workspace/Benchmarks/.build"
    --env CLANG_MODULE_CACHE_PATH=/workspace/.build/clang-module-cache
    "${IMAGE}"
)

case "${COMMAND}" in
test)
    exec docker "${docker_args[@]}" bash -lc '
        set -euo pipefail
        swift --version
        swift build --target CIDR
        swift build --target CIDRConfig
        swift build --target CIDRPOSIX
        swift build --target CIDRNIO
        ./scripts/test.sh
    '
    ;;
benchmark-build)
    exec docker "${docker_args[@]}" bash -lc '
        set -euo pipefail
        apt-get update
        apt-get install -y --no-install-recommends libjemalloc-dev pkg-config
        rm -rf /var/lib/apt/lists/*
        swift build --package-path Benchmarks --product CIDRProfileTarget
        ./scripts/benchmarks.sh build
        CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh build
        CIDR_BENCHMARK_TARGET=CIDRNIOBenchmarkTarget ./scripts/benchmarks.sh build
    '
    ;;
shell)
    exec docker "${docker_args[@]}" bash
    ;;
help | -h | --help)
    usage
    ;;
*)
    echo "error: unknown command '${COMMAND}'" >&2
    echo >&2
    usage >&2
    exit 1
    ;;
esac
