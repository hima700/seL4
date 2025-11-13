# Build and Test Instructions

## Prerequisites

1. **WSL2 Ubuntu** - Make sure WSL2 is running
2. **QEMU** - Install QEMU for ARM64 emulation:
   ```bash
   sudo apt update
   sudo apt install qemu-system-arm
   ```
3. **Build Tools** - Ensure you have make and gcc cross-compiler (should be in Microkit SDK)

## Building Applications

### Build Hello World (Baseline)

From WSL2, navigate to the project directory:

```bash
cd /mnt/c/Users/Ibrah/Desktop/RA/sel4/seL4
./scripts/build.sh hello_world qemu_virt_aarch64 debug
```

This will:
- Build the hello world application
- Create output in `out/hello_world-qemu_virt_aarch64-debug/`
- Generate `loader.img` boot image

### Build IPC Demo (Client-Server-Logger)

```bash
./scripts/build.sh ipc_demo qemu_virt_aarch64 debug
```

This will:
- Build client, server, and logger components
- Create output in `out/ipc_demo-qemu_virt_aarch64-debug/`
- Generate `loader.img` boot image

## Running Applications

### Run Hello World

```bash
./scripts/run.sh hello_world qemu_virt_aarch64 debug
```

Expected output:
```
=== seL4 Microkit Hello World ===
Baseline verification successful
System initialized and running
```

To exit QEMU: Press `Ctrl+A` then `X`

### Run IPC Demo

```bash
./scripts/run.sh ipc_demo qemu_virt_aarch64 debug
```

Expected output should show:
- Client initialization and message sending
- Server receiving messages and processing
- Logger receiving notifications
- Shared memory communication

To exit QEMU: Press `Ctrl+A` then `X`

## Troubleshooting

### QEMU Not Found

If you get "qemu-system-aarch64: command not found":
```bash
sudo apt install qemu-system-arm
```

### Build Errors

1. **Missing toolchain**: The Microkit SDK should include the toolchain, but if you see errors:
   ```bash
   # Check if toolchain is in SDK
   ls microkit-sdk/bin/
   ```

2. **Permission errors**: Make sure scripts are executable:
   ```bash
   chmod +x scripts/*.sh
   ```

3. **SDK path issues**: Verify Microkit SDK is at `microkit-sdk/`:
   ```bash
   ls -d microkit-sdk
   ```

### Run Errors

1. **Image not found**: Make sure you built first:
   ```bash
   ./scripts/build.sh ipc_demo qemu_virt_aarch64 debug
   ```

2. **QEMU crashes**: Try increasing memory or check QEMU version:
   ```bash
   qemu-system-aarch64 --version
   ```

## Alternative: Using Docker Container

If you prefer using the seL4 Docker container:

```bash
cd seL4-CAmkES-L4v-dockerfiles
make user HOST_DIR=/mnt/c/Users/Ibrah/Desktop/RA/sel4/seL4
```

Then inside the container:
```bash
cd /host
./scripts/build.sh ipc_demo qemu_virt_aarch64 debug
./scripts/run.sh ipc_demo qemu_virt_aarch64 debug
```

## Clean Build Artifacts

To clean all build outputs:
```bash
./scripts/clean.sh
```

To clean specific application:
```bash
./scripts/clean.sh hello_world
./scripts/clean.sh ipc_demo
```

