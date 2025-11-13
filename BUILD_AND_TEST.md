# Build and Test Instructions

## Prerequisites

1. **WSL2 Ubuntu** - Make sure WSL2 is running
2. **ARM64 Toolchain** - Required for cross-compilation. The build script will auto-setup if missing:
   ```bash
   # Manual setup (optional - build script does this automatically)
   ./scripts/setup_toolchain.sh
   ```
   Or install via package manager (requires sudo):
   ```bash
   sudo apt install gcc-aarch64-linux-gnu
   ```
   **Note**: The Microkit SDK does NOT include the toolchain - it must be installed separately.

3. **QEMU** - Install QEMU for ARM64 emulation:
   ```bash
   sudo apt update
   sudo apt install qemu-system-arm
   ```

4. **Build Tools** - Ensure you have make (Microkit SDK provides libraries, not toolchain)

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

### Error: aarch64-none-elf-gcc: No such file or directory

**Problem**: ARM64 cross-compiler toolchain not found.

**Solution**: The build script automatically sets up the toolchain if it's in `$HOME/.local/arm-toolchain/`. If you see this error:

1. **Automatic setup** (recommended):
   ```bash
   source scripts/setup_toolchain.sh
   ./scripts/build.sh ipc_demo qemu_virt_aarch64 debug
   ```

2. **Manual installation** (requires sudo):
   ```bash
   sudo apt install gcc-aarch64-linux-gnu
   # Note: Package name may differ - check available packages
   ```

**Root Cause**: Microkit SDK does NOT include the toolchain - only libraries and headers. The toolchain must be installed separately.

**Fix Applied**: Modified `scripts/build.sh` to automatically detect and add toolchain to PATH if `aarch64-none-elf-gcc` is not found.

### Error: dirname: command not found / mkdir: command not found

**Problem**: PATH environment variable not set correctly in WSL.

**Solution**: The build script now sets a minimal PATH at the start:
```bash
export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"
```

**Fix Applied**: Added PATH setup at beginning of `scripts/build.sh`.

### Error: undefined reference to `shared_buffer`

**Problem**: Shared memory variable not properly declared for linker.

**Solution**: Changed from `extern char shared_buffer[]` to `uintptr_t shared_buffer = 0;` and use pointer cast:
```c
uintptr_t shared_buffer = 0;  // Microkit tool patches this
#define SHARED_BUF ((char *)shared_buffer)
```

**Root Cause**: `setvar_vaddr` in system.system creates a `uintptr_t` variable, not a char array. The Microkit tool patches the value after linking.

**Fix Applied**: Updated `client.c` and `server.c` to use `uintptr_t` with pointer cast macro.

### Error: invalid attribute 'badge' on element 'end'

**Problem**: Badge attribute not supported in Microkit system XML.

**Solution**: Removed `badge="1"` attribute from channel endpoint. Badges are automatically assigned by Microkit.

**Fix Applied**: Updated `system.system` to remove badge attribute.

### Error: microkit_msginfo_get_badge: implicit declaration

**Problem**: Badge access function doesn't exist in Microkit API.

**Solution**: Removed badge access code. Badge information is not directly accessible via Microkit API.

**Fix Applied**: Removed badge printing from `server.c`.

### QEMU Not Found

If you get "qemu-system-aarch64: command not found":
```bash
sudo apt install qemu-system-arm
```

### Permission Errors

Make sure scripts are executable:
```bash
chmod +x scripts/*.sh
```

### SDK Path Issues

Verify Microkit SDK is at `microkit-sdk/`:
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

## Build Test Results

### Hello World Build: SUCCESS ✓
- Built successfully: `out/hello_world-qemu_virt_aarch64-debug/loader.img`
- All components compiled and linked correctly
- Microkit tool generated system image successfully

### IPC Demo Build: SUCCESS ✓
- Built successfully: `out/ipc_demo-qemu_virt_aarch64-debug/loader.img`
- Client, server, and logger components compiled
- System configuration validated
- Shared memory mapping configured correctly

### Known Issues

1. **QEMU not installed**: QEMU needs to be installed to run the images:
   ```bash
   sudo apt install qemu-system-arm
   ```

2. **Toolchain setup**: First build requires toolchain download (~123MB). Subsequent builds are faster.

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

## Summary of Fixes Applied

1. **Toolchain Setup**: Created `scripts/setup_toolchain.sh` to automatically download ARM GNU toolchain
2. **Build Script PATH**: Fixed PATH issues in build script for WSL environment
3. **Shared Memory**: Fixed shared_buffer declaration to use `uintptr_t` with pointer cast
4. **System XML**: Removed invalid `badge` attribute from channel configuration
5. **API Usage**: Removed non-existent `microkit_msginfo_get_badge()` function call

