#!/bin/bash
# Run tests using Docker (requires Docker to be installed)

cd "$(dirname "$0")"

echo "Building test container..."
docker build -f Dockerfile.test -t ido-numbered-mode-test .

echo "Running tests..."
docker run --rm ido-numbered-mode-test
