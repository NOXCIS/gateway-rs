#!/bin/bash

# Set variables
IMAGE_NAME="helium-gateway-pisces"
TAG="latest"

# Check for cleanup parameter
if [ "$1" == "--clean" ]; then
  echo "Cleaning previous builder..."
  docker buildx rm pisces-builder 2>/dev/null || true
  echo "Removing previous image..."
  docker rmi $IMAGE_NAME:$TAG 2>/dev/null || true
fi

echo "=== Building Helium Gateway for Pisces P100 (ARM64) ==="
echo "This will build a Docker image for your ARM64 Pisces P100 device with ECC608 support"

# Setup buildx for cross-platform builds
echo "Setting up Docker buildx..."
docker buildx create --name pisces-builder --use 2>/dev/null || true
docker buildx inspect --bootstrap

# Check if QEMU is installed for ARM64 emulation
if docker buildx inspect | grep -q 'platforms.*linux/arm64'; then
  echo "✅ ARM64 emulation is available"
else
  echo "⚠️ ARM64 emulation may not be available. Attempting build anyway..."
fi

# Build for Pisces P100 (ARM64)
echo "Building image $IMAGE_NAME:$TAG for ARM64..."
echo "This may take a while..."

# Run the build with more verbosity
if docker buildx build \
  --platform linux/arm64 \
  --tag $IMAGE_NAME:$TAG \
  --load \
  --progress=plain \
  .; then
  
  echo "✅ Build completed successfully!"
  echo ""
  echo "To run on your Pisces P100:"
  echo "docker run -d --name helium-gateway \\"
  echo "  -p 1680:1680/udp \\"
  echo "  -p 4467:4467 \\"
  echo "  --restart unless-stopped \\"
  echo "  --device /dev/i2c-1 \\"
  echo "  -v /etc/helium_gateway:/etc/helium_gateway \\"
  echo "  $IMAGE_NAME:$TAG"
  echo ""
  echo "If you want to transfer this image to your Pisces P100, use:"
  echo "docker save $IMAGE_NAME:$TAG | gzip > helium-gateway-pisces.tar.gz"
  echo "Then copy and load it on your device with:"
  echo "scp helium-gateway-pisces.tar.gz user@your-pisces-ip:~/"
  echo "ssh user@your-pisces-ip"
  echo "docker load < helium-gateway-pisces.tar.gz"
else
  echo "❌ Build failed"
  echo ""
  echo "If you want to try with a clean build environment, run:"
  echo "./build-pisces.sh --clean"
  exit 1
fi 