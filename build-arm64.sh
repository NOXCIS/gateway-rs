#!/bin/bash

# Build script for Helium Gateway on ARM64/Pisces P100
# This script builds the Docker image for ARM64 with ECC608 support

# Set variables
IMAGE_NAME="helium-gateway-arm64"
IMAGE_TAG="latest"

echo "Building $IMAGE_NAME:$IMAGE_TAG for Pisces P100..."

# Use the ARM64-specific Dockerfile
docker build -f Dockerfile.arm64 -t $IMAGE_NAME:$IMAGE_TAG .

echo "Build complete!"
echo ""
echo "To run the image:"
echo "docker run -d --name helium-gateway \\"
echo "  -p 1680:1680/udp \\"
echo "  -p 4467:4467 \\"
echo "  --restart unless-stopped \\"
echo "  --device /dev/i2c-1 \\"
echo "  -v /etc/helium_gateway:/etc/helium_gateway \\"
echo "  $IMAGE_NAME:$IMAGE_TAG" 