# Helium Gateway for Pisces P100

This document provides instructions for building and running the Helium Gateway software on a Pisces P100 gateway device.

## Hardware Details

The Pisces P100 is an ARM64-based outdoor gateway with the following specifications:
- ARM64 processor
- ECC608 security chip for secure cryptographic operations
- LoRaWAN connectivity
- Ethernet connectivity
- IP65 weatherproof enclosure

## Building for Pisces P100

The Helium Gateway software can be built for the Pisces P100 using Docker. We've included special configuration files to make this process easier.

### Prerequisites

- Make sure Docker is installed on your system
- SSH access to your Pisces P100
- Access to the P100's ECC608 chip through I2C

### Building the Docker Image

1. Clone this repository
2. Run the build script:
   ```bash
   chmod +x build-arm64.sh
   ./build-arm64.sh
   ```
3. The script will build a Docker image named `helium-gateway-arm64:latest`

### Transferring to the Pisces P100

You can either:

1. Build directly on the P100 if it has enough resources, or
2. Build on another machine and transfer the image:
   ```bash
   docker save helium-gateway-arm64:latest | gzip > helium-gateway-arm64.tar.gz
   scp helium-gateway-arm64.tar.gz user@your-pisces-ip:~/
   ssh user@your-pisces-ip
   docker load < helium-gateway-arm64.tar.gz
   ```

## Running on the Pisces P100

1. Make sure the I2C device is accessible (typically `/dev/i2c-1`)
2. Create a directory for the gateway configuration:
   ```bash
   mkdir -p /etc/helium_gateway
   ```
3. Run the Docker container:
   ```bash
   docker run -d --name helium-gateway \
     -p 1680:1680/udp \
     -p 4467:4467 \
     --restart unless-stopped \
     --device /dev/i2c-1 \
     -v /etc/helium_gateway:/etc/helium_gateway \
     helium-gateway-arm64:latest
   ```

## Configuration

The settings.toml file is configured to use the ECC608 secure element on the Pisces P100. The key configuration is:

```toml
# Ecc608 based for Pisces P100:
keypair = "ecc://i2c-1:96?slot=0"
onboarding = "ecc://i2c-1:96?slot=15"
```

You may need to adjust the I2C bus (`i2c-1`) and slot numbers based on your specific P100 configuration.

## Troubleshooting

If you encounter issues with the ECC608 chip, verify:
1. The I2C device is accessible (check with `ls -l /dev/i2c*`)
2. The Docker container has proper permissions to access the device
3. The correct slot numbers are configured in settings.toml

For general gateway issues, check the logs:
```bash
docker logs helium-gateway
```

## Maintenance

To update the gateway software:
1. Pull the latest code
2. Rebuild using the build script
3. Stop and remove the old container
4. Run a new container with the updated image 