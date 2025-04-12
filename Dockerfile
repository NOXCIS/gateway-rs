# ==============================================================================
# This Docker file is designed support multi-architecture[1] images.
#
# How you build depends on your use case. If you only want to build
# for the architecture you're invoking docker from (host arch):
#
#     docker build .
#
# However, if you want to build for another architecture or multiple
# architectures, use buildx[2]:
#
#     docker buildx build --platform linux/arm64,linux/amd64 .
#
# Adding support for additional architectures requires editing the
# `case "$TARGETPLATFORM" in` in the build stage (and likely quite a
# bit of googling).
#
# 1: https://www.docker.com/blog/how-to-rapidly-build-multi-architecture-images-with-buildx
# 2: https://docs.docker.com/build/install-buildx
# ==============================================================================


# ------------------------------------------------------------------------------
# Cargo Build Stage
#
# Uses platform-specific emulation instead of cross-compilation
# ------------------------------------------------------------------------------
FROM rust:alpine3.17 AS cargo-build

ARG TARGETPLATFORM

# Install build dependencies
RUN apk add --no-cache --update \
    clang \
    cmake \
    g++ \
    gcc \
    libc-dev \
    musl-dev \
    libgcc \
    protobuf

WORKDIR /tmp/helium_gateway

# First, copy just what we need for dependency calculation
COPY Cargo.toml Cargo.lock ./
COPY lorawan ./lorawan

# Create dummy main.rs 
RUN mkdir -p src && \
    echo 'fn main() { println!("Dummy"); }' > src/main.rs

# Configure build flags based on target platform
RUN \
case "$TARGETPLATFORM" in \
    "linux/amd64") \
        echo "--features=tpm" > cargo_flags.txt ; \
        apk add --no-cache --update tpm2-tss-dev ; \
        ;; \
    "linux/arm64") \
        echo "--features=ecc608" > cargo_flags.txt ; \
        ;; \
    *) \
        exit 1 \
        ;; \
esac

# Build dependencies
RUN cargo build --release $(cat cargo_flags.txt)

# Copy the actual source code
COPY src ./src
COPY config ./config

# Build using the platform-specific compiler
RUN cargo build --release $(cat cargo_flags.txt)

# ------------------------------------------------------------------------------
# Final Stage
#
# Run steps run in a VM based on the target architecture
# Produces image for target architecture
# ------------------------------------------------------------------------------
FROM alpine:3.17.3
ENV RUST_BACKTRACE=1
ENV GW_LISTEN="0.0.0.0:1680"
ARG TARGETPLATFORM

# Install required packages based on architecture
RUN \
if [ "$TARGETPLATFORM" = "linux/amd64" ]; \
    then apk add --no-cache --update \
    libstdc++ \
    tpm2-tss-esys \
    tpm2-tss-fapi \
    tpm2-tss-mu \
    tpm2-tss-rc \
    tpm2-tss-tcti-device ; \
elif [ "$TARGETPLATFORM" = "linux/arm64" ]; \
    then apk add --no-cache --update \
    libstdc++ ; \
fi

COPY --from=cargo-build /tmp/helium_gateway/target/release/helium_gateway /usr/local/bin/helium_gateway
RUN mkdir -p /etc/helium_gateway
COPY config/settings.toml /etc/helium_gateway/settings.toml
CMD ["helium_gateway", "server"]
