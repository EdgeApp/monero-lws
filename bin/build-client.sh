#!/bin/bash

# Build script for monero-lws-client on macOS
# This script builds the client using the beginner build method with git submodules

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"

# Number of parallel jobs (macOS doesn't have nproc, use sysctl)
JOBS="${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || echo 8)}"

# Build type
BUILD_TYPE="${BUILD_TYPE:-Release}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building monero-lws-client on macOS${NC}"
echo "Project root: ${PROJECT_ROOT}"
echo "Build directory: ${BUILD_DIR}"
echo "Build type: ${BUILD_TYPE}"
echo "Parallel jobs: ${JOBS}"
echo ""

# Check if we're in the right directory
if [ ! -f "${PROJECT_ROOT}/CMakeLists.txt" ]; then
    echo -e "${RED}Error: CMakeLists.txt not found. Are you in the monero-lws directory?${NC}"
    exit 1
fi

# Check for required tools
command -v cmake >/dev/null 2>&1 || { echo -e "${RED}Error: cmake is required but not installed.${NC}" >&2; exit 1; }
command -v make >/dev/null 2>&1 || { echo -e "${RED}Error: make is required but not installed.${NC}" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo -e "${RED}Error: git is required but not installed.${NC}" >&2; exit 1; }

# Create build directory if it doesn't exist
if [ ! -d "${BUILD_DIR}" ]; then
    echo -e "${YELLOW}Creating build directory...${NC}"
    mkdir -p "${BUILD_DIR}"
fi

cd "${BUILD_DIR}"

# Initialize git submodules if needed
if [ ! -d "${PROJECT_ROOT}/external/monero/.git" ]; then
    echo -e "${YELLOW}Initializing git submodules...${NC}"
    cd "${PROJECT_ROOT}"
    git submodule update --init --recursive
    cd "${BUILD_DIR}"
else
    echo -e "${GREEN}Git submodules already initialized${NC}"
fi

# Configure with CMake if needed
if [ ! -f "${BUILD_DIR}/CMakeCache.txt" ]; then
    echo -e "${YELLOW}Configuring with CMake...${NC}"
    cmake -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" "${PROJECT_ROOT}"
else
    echo -e "${GREEN}CMake cache exists, skipping configuration${NC}"
    echo -e "${YELLOW}To reconfigure, delete ${BUILD_DIR}/CMakeCache.txt${NC}"
fi

# Build only the client
echo -e "${YELLOW}Building monero-lws-client...${NC}"
make -j"${JOBS}" monero-lws-client

# Check if build succeeded
if [ -f "${BUILD_DIR}/src/monero-lws-client" ]; then
    echo ""
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo -e "${GREEN}Binary location: ${BUILD_DIR}/src/monero-lws-client${NC}"
    
    # Show binary info
    if command -v file >/dev/null 2>&1; then
        echo ""
        file "${BUILD_DIR}/src/monero-lws-client"
    fi
else
    echo -e "${RED}✗ Build failed - binary not found${NC}"
    exit 1
fi


