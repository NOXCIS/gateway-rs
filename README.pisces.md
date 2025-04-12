# Helium Gateway for Pisces P100

This document provides instructions for building and running the Helium Gateway software on a Pisces P100 gateway device with full ECC608 support.

## Hardware Details

The Pisces P100 is an ARM64-based outdoor gateway with:
- ARM64 processor
- ECC608 security chip for secure cryptographic operations
- LoRaWAN connectivity for Helium network integration
- IP65 weatherproof enclosure for outdoor deployment

## Building for Pisces P100

### Prerequisites

- Docker installed with buildx and QEMU support for ARM64 emulation
- Terminal access to run the build commands

### Building Instructions

We've provided a simplified build script to make this process easier:

```bash
# Make the script executable
chmod +x build-pisces.sh

# Build the image
./build-pisces.sh
```

If you encounter build errors, you can try cleaning up the environment first:

```bash
./build-pisces.sh --clean
```

The build process:
1. Sets up a Docker buildx environment with ARM64 emulation
2. Compiles the Helium Gateway software with ECC608 support 
3. Creates a Docker image ready to deploy on your Pisces P100

## Deploying to Your Pisces P100

### Transfer Method

If building on another machine, transfer the image:

```bash
# Save the Docker image to a compressed file
docker save helium-gateway-pisces:latest | gzip > helium-gateway-pisces.tar.gz

# Copy to your Pisces P100 (replace with your device's IP)
scp helium-gateway-pisces.tar.gz user@your-pisces-ip:~/

# SSH to your device
ssh user@your-pisces-ip

# Load the image on your Pisces P100
docker load < helium-gateway-pisces.tar.gz
```

### Running the Gateway Software

```bash
# Create config directory (if needed)
mkdir -p /etc/helium_gateway

# Start the container
docker run -d --name helium-gateway \
  -p 1680:1680/udp \
  -p 4467:4467 \
  --restart unless-stopped \
  --device /dev/i2c-1 \
  -v /etc/helium_gateway:/etc/helium_gateway \
  helium-gateway-pisces:latest
```

## Configuration

The settings.toml file is already configured for Pisces P100 with ECC608 support:

```toml
# Ecc608 based for Pisces P100:
keypair = "ecc://i2c-1:96?slot=0"
onboarding = "ecc://i2c-1:96?slot=15"
```

You may need to adjust the I2C bus (`i2c-1`) and slot numbers depending on your specific device configuration.

## Troubleshooting

### Common Issues

1. **I2C Device Access**
   - Check that `/dev/i2c-1` exists on your Pisces P100
   - Verify with `ls -l /dev/i2c*`
   - You may need to use a different I2C device path

2. **Build Failures**
   - Try building with `./build-pisces.sh --clean`
   - Make sure Docker has enough resources allocated
   - Check that QEMU emulation is installed correctly

3. **Container Won't Start**
   - Check logs with `docker logs helium-gateway`
   - Verify I2C access permissions
   - Ensure port 1680 isn't already in use

For detailed logs and diagnostics:
```bash
docker logs helium-gateway
```

## Updates

To update to a newer version of the Helium Gateway software:
1. Pull the latest code
2. Rebuild using `./build-pisces.sh --clean`
3. Stop and remove the old container: `docker rm -f helium-gateway`
4. Start a new container with the updated image 