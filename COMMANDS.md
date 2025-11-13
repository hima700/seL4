# Command Trace Log

This file documents all commands executed during the seL4 microkernel project implementation.

## Step 1: Setup and Baseline Environment

### Initial Setup
- Created branch `step-1-setup` for Step 1 work
- Created project directory structure: microkit/, scripts/, docs/, out/
- Verified WSL2 Ubuntu installation
- Verified Docker Desktop availability (version 28.4.0)

### Docker and Build Environment
- Cloned seL4-CAmkES-L4v-dockerfiles repository
- Downloaded Microkit SDK 2.0.1 (linux-x86-64) from GitHub releases
- Extracted SDK to microkit-sdk/ directory

### Hello World Application
- Created microkit/hello_world/hello.c - baseline hello world application
- Created microkit/hello_world/system.system - system configuration XML
- Created microkit/hello_world/Makefile - build configuration
- Created scripts/build.sh - automated build script
- Created scripts/run.sh - QEMU launcher script
- Created scripts/clean.sh - cleanup script
- Made scripts executable with chmod +x

### Commands Executed
```bash
# Branch creation
git checkout -b step-1-setup

# Directory structure
mkdir -p microkit/hello_world microkit/ipc_demo scripts docs out

# Docker verification
docker --version
wsl --status

# Clone dockerfiles
git clone https://github.com/seL4/seL4-CAmkES-L4v-dockerfiles.git

# Download Microkit SDK
wget https://github.com/seL4/microkit/releases/download/2.0.1/microkit-sdk-2.0.1-linux-x86-64.tar.gz
tar -xzf microkit-sdk-2.0.1-linux-x86-64.tar.gz
mv microkit-sdk-2.0.1 microkit-sdk

# Make scripts executable
chmod +x scripts/build.sh scripts/run.sh scripts/clean.sh
```

### Notes
- Microkit SDK 2.0.1 downloaded and extracted
- For x86_64 QEMU support, may need to use seL4 docker container or build seL4 separately
- Current SDK supports qemu_virt_aarch64 and qemu_virt_riscv64 boards
- Build scripts configured for available boards

## Step 2: IPC Client-Server Implementation

### Branch Creation
- Created branch `step-2-ipc` for Step 2 work

### IPC Components Created
- Created microkit/ipc_demo/client.c - IPC client with message passing and shared memory
- Created microkit/ipc_demo/server.c - IPC server with protected call handler and notification handler
- Created microkit/ipc_demo/system.system - System configuration with 2 protection domains, shared memory, and endpoint
- Created microkit/ipc_demo/Makefile - Build configuration for IPC demo

### IPC Features Implemented
- Message passing via microkit_ppcall() with reply objects
- Badge-based client identification (badge=1)
- Shared memory region (4KB) mapped to both client and server
- Notification mechanism for shared memory synchronization
- Multiple message types (label 1 and 2) demonstrating request/response protocol

### Commands Executed
```bash
# Branch creation
git checkout -b step-2-ipc
```

