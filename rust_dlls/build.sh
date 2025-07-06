#!/bin/bash

# Build 32-bit Redis DLL for MetaTrader 4
# MT4 is 32-bit and requires a 32-bit DLL

echo "Building 32-bit Redis DLL for MT4..."

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    echo "Error: Rust is not installed. Please install Rust first."
    echo "Visit: https://rustup.rs/"
    exit 1
fi

# Add 32-bit target if not already added
echo "Adding 32-bit Windows target..."
rustup target add i686-pc-windows-gnu

# Build for 32-bit Windows
echo "Building DLL..."
cargo build --release --target i686-pc-windows-gnu

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "✓ Build successful!"
    echo "DLL location: target/i686-pc-windows-gnu/release/redis_client.dll"
    echo ""
    echo "Copy the DLL to your MT4 MQL4/Libraries/ folder:"
    echo "cp target/i686-pc-windows-gnu/release/redis_client.dll \"../Libraries/\""
else
    echo "✗ Build failed!"
    exit 1
fi 