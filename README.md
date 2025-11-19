# seL4 Microkernel Multi-Component System

This project implements a PC-based seL4 microkernel system using Microkit on x86_64 via QEMU. It demonstrates IPC, capability-based isolation, and component architecture.

## Project Structure

```
seL4/
├── microkit/           # Microkit applications
│   ├── hello_world/    # Baseline hello world (Step 1)
│   ├── ipc_demo/       # Client-server-logger (Steps 2-3)
│   └── fault_tolerance/ # Fault tolerance demo (Step 4)
├── microkit-sdk/       # Microkit SDK 2.0.1
├── scripts/            # Build and run scripts
│   ├── build.sh        # Build applications
│   ├── run.sh          # Run in QEMU
│   ├── clean.sh         # Clean build artifacts
│   ├── capture_logs.sh  # Capture logs for fault analysis
│   ├── run_linux.sh     # Run Linux baseline
│   ├── run_metrics.sh   # Run metrics collection
│   ├── compare_metrics.sh # Compare seL4 vs Linux
│   ├── archive_results.sh # Archive logs/artefacts
│   ├── plot_metrics.py  # Generate plots
│   └── run_all_metrics.sh # One-command metrics pipeline
├── linux_baseline/     # Linux equivalent implementation
│   ├── client/         # Linux client (sockets/IPC)
│   ├── server/         # Linux server (sockets/IPC)
│   └── logger/         # Linux logger (sockets/IPC)
├── metrics/            # Metrics collection scripts
├── docs/               # Architecture diagrams (if needed)
├── out/                # Build output directory
└── README.md           # This file
```

## Dockerized Execution (Recommended)

To ensure a consistent environment and avoid dependency issues, use the Dockerized setup:

1.  **Run the full pipeline:**
    ```bash
    ./scripts/docker_run.sh 5
    ```
    This will:
    -   Build a Docker image with all dependencies (QEMU, Toolchain, Python).
    -   Build the seL4 and Linux components.
    -   Run the metrics collection.
    -   Generate plots.
    -   Save results to `out/` on your host machine.

## Requirements (Local Execution)

If you prefer running locally without Docker:

- Windows 10/11 with WSL2 (Ubuntu)
- Docker Desktop (for seL4 build container)
- QEMU (for running virtualized systems)
  ```bash
  sudo apt update
  sudo apt install qemu-system-arm qemu-system-misc
  ```
- Make and standard build tools
- Python 3 with matplotlib and numpy (for metrics plotting):
  ```bash
  pip3 install matplotlib numpy
  ```
- `bc` (for metrics comparison):
  ```bash
  sudo apt install bc
  ```

## Quick Start

### Step 1: Setup and Baseline Environment

1. **Verify WSL2 and Docker:**
   ```powershell
   wsl --status
   docker --version
   ```

2. **Build hello world application:**
   ```bash
   # IMPORTANT: Run in WSL, not PowerShell!
   # Option 1: From PowerShell, use wsl prefix:
   wsl bash -c "cd /mnt/c/Users/Ibrah/Desktop/RA/sel4/seL4 ; ./scripts/build.sh hello_world qemu_virt_aarch64 debug"
   
   # Option 2: Open WSL terminal and run:
   cd /mnt/c/Users/Ibrah/Desktop/RA/sel4/seL4
   ./scripts/build.sh hello_world qemu_virt_aarch64 debug
   ```

3. **Run in QEMU:**
   ```bash
   # IMPORTANT: Run in WSL, not PowerShell!
   # Option 1: From PowerShell, use wsl prefix:
   wsl bash -c "cd /mnt/c/Users/Ibrah/Desktop/RA/sel4/seL4 ; ./scripts/run.sh hello_world qemu_virt_aarch64 debug"
   
   # Option 2: Open WSL terminal and run:
   cd /mnt/c/Users/Ibrah/Desktop/RA/sel4/seL4
   ./scripts/run.sh hello_world qemu_virt_aarch64 debug
   ```
   
   **Note**: Press `Ctrl+A` then `X` to exit QEMU.

### Building

The build script requires:
- Application name (hello_world, ipc_demo, or fault_tolerance)
- Board (qemu_virt_aarch64, qemu_virt_riscv64)
- Config (debug, release, benchmark)

Examples:
```bash
./scripts/build.sh hello_world qemu_virt_aarch64 debug
./scripts/build.sh ipc_demo qemu_virt_aarch64 debug
./scripts/build.sh fault_tolerance qemu_virt_aarch64 debug
```

### Running

The run script launches QEMU with the built image:
```bash
./scripts/run.sh hello_world qemu_virt_aarch64 debug
./scripts/run.sh ipc_demo qemu_virt_aarch64 debug
./scripts/run.sh fault_tolerance qemu_virt_aarch64 debug
```

Press `Ctrl+A` then `X` to exit QEMU.

### Capturing Logs (Fault Tolerance)

For fault tolerance analysis, capture logs to a file:
```bash
./scripts/capture_logs.sh fault_tolerance qemu_virt_aarch64 debug
```

This will save logs to `out/fault_logs_YYYYMMDD_HHMMSS.txt` for analysis.

### Cleaning

Remove build artifacts:
```bash
./scripts/clean.sh          # Clean all
./scripts/clean.sh hello_world  # Clean specific app
```

## Development Workflow

1. Edit source files in `microkit/` directories
2. Build using `scripts/build.sh`
3. Run and test using `scripts/run.sh`
4. Check serial output for debug messages

## Project Status

### Completed Requirements

**Step 1: Setup and Baseline Environment** ✅ **TESTED AND WORKING**
- Microkit SDK 2.0.1 installed
- Hello world baseline application created and tested
- Build and run scripts implemented
- **Verification**: Hello world runs successfully in QEMU, outputs expected messages

**Step 2: IPC Client-Server Implementation** ✅ **TESTED AND WORKING**
- Client component with message passing
- Server component with protected call handler
- Shared memory communication (4KB region)
- Reply objects for request/response protocol
- **Verification**: Client-server IPC works, shared memory read/write confirmed

**Step 3: Component Isolation** ✅ **TESTED AND WORKING**
- Logger component as third protection domain
- VSpace isolation (separate virtual address spaces)
- CSpace isolation (separate capability spaces)
- Least-privilege enforcement (logger has notifications only, no memory access)
- **Verification**: All three components run, logger isolated with minimal capabilities

**Step 4: Fault Tolerance Demonstration** ✅ **TESTED AND WORKING**
- Crasher component intentionally fails to demonstrate fault containment
- Server, client, and logger continue operating after crasher crash
- Log capture script for fault analysis
- **Verification**: 
  - Crasher crashes (NULL pointer dereference)
  - Fault detected: "MON|ERROR: faulting PD: crasher"
  - Server continues processing requests
  - Client continues communicating
  - Logger continues capturing events
  - Fault containment proven - no propagation to other components

**Step 5: Comparison Against Linux (User-Space)** ✅ **IMPLEMENTED**
- Linux equivalent client-server-logger using sockets/IPC
- Shared memory via POSIX shared memory (`shm_open`/`mmap`)
- Logger via Unix domain sockets (UDP)
- Measurement code using `CLOCK_MONOTONIC_RAW` for high-resolution timestamps
- **Build**: `cd linux_baseline && make`
- **Run**: `./scripts/run_linux.sh [iterations]`
- **Compare**: `./scripts/compare_metrics.sh [iterations]`

**Step 6: Reproducible Build/Run/Measure Harness** ✅ **IMPLEMENTED**
- One-command metrics pipeline: `./scripts/run_all_metrics.sh [iterations]`
- Metrics runner: `./scripts/run_metrics.sh [app] [board] [config] [iterations]`
- RDTSC/CLOCK_MONOTONIC_RAW timestamping in client PD
- CSV output: `out/metrics/YYYYMMDD-HHMM/results.csv`
- Plotting script: `./scripts/plot_metrics.py [csv] [output.png]`
- Archive script: `./scripts/archive_results.sh [timestamp]`
- Results archived under `out/YYYYMMDD-HHMM/`

### Architecture

The system consists of three protection domains:
- **Client**: Sends messages to server, uses shared memory, notifies logger
- **Server**: Receives messages, processes requests, uses shared memory, notifies logger
- **Logger**: Receives notifications only, no memory access to other components

See `docs/ARCHITECTURE.md`, `docs/ISOLATION.md`, and `docs/FAULT_TOLERANCE.md` for detailed documentation.

## Metrics and Comparison

### Running Metrics Collection

**One-command pipeline** (recommended):
```bash
./scripts/run_all_metrics.sh 10
```

This will:
1. Build Linux baseline
2. Build seL4 IPC demo
3. Run Linux metrics (10 iterations)
4. Run seL4 metrics (10 iterations)
5. Archive results to `out/YYYYMMDD-HHMM/`
6. Generate plots (if Python/matplotlib available)

**Individual steps**:
```bash
# Build Linux baseline
cd linux_baseline && make

# Run Linux baseline
./scripts/run_linux.sh 10

# Run seL4 metrics
./scripts/run_metrics.sh ipc_demo qemu_virt_aarch64 debug 10

# Compare results
./scripts/compare_metrics.sh 10

# Archive results
./scripts/archive_results.sh
```

### Metrics Output

- **CSV format**: `out/metrics/YYYYMMDD-HHMM/results.csv`
  - Columns: `iteration,latency_ns,timestamp`
- **Plots**: `out/metrics/YYYYMMDD-HHMM/metrics_plot.png` (if matplotlib available)
- **Logs**: Individual run logs in `out/metrics/YYYYMMDD-HHMM/run_*.log`

### Comparison Metrics

The comparison measures:
- **IPC Latency**: Round-trip time for client-server messages
- **Throughput**: Messages per second
- **Memory Usage**: Per-component memory footprint
- **Fault Impact**: Crash ripple effect (Linux vs seL4 isolation)

### Prerequisites for Metrics

- Python 3 with matplotlib and numpy (for plotting):
  ```bash
  pip3 install matplotlib numpy
  ```
- `bc` (for calculations in comparison script):
  ```bash
  sudo apt install bc
  ```

## Notes on x86_64 Support

The Microkit SDK 2.0.1 currently provides boards for:
- `qemu_virt_aarch64` (ARM64)
- `qemu_virt_riscv64` (RISC-V)

For x86_64 QEMU support, you may need to:
- Use the seL4 docker container: `cd seL4-CAmkES-L4v-dockerfiles && make user`
- Build seL4 separately for x86_64 platform
- Check Microkit SDK documentation for x86_64 board support

---

## Original seL4 Build Environment Setup

This section documents the original seL4 build environment setup using Docker.

# seL4 Build Environment Setup and Repo Cheatsheet

This README walks you through setting up a build environment for seL4, Microkit and CAmkES using Docker, and using the repo tool for source dependency management.

## 1. Prerequisites: Docker Installation

Before you begin, you need to install Docker on your system. Below are general instructions; for detailed platform‑specific steps refer to Docker's official documentation [docs.docker.com](https://docs.docker.com).

### On Ubuntu / Debian

```bash
sudo apt update  
sudo apt install docker.io  
sudo systemctl enable --now docker  
sudo usermod -aG docker $(whoami)  
```

> Note: After adding your account to the Docker group you may have to logout and log back in for the change to take effect.

### On other Linux distributions

Use your distribution's package manager (e.g., `dnf`, `yum`, `pacman`) to install Docker or follow the instructions at the Docker site. Then add your user to the `docker` group:

```bash
sudo usermod -aG docker $(whoami)  
```

Logout and log back in.

### On macOS / Windows

Install Docker Desktop from [docs.docker.com](https://docs.docker.com). After installation ensure Docker daemon is running and you can run `docker version` from your terminal or command prompt.

## 2. Using Docker for seL4, Microkit, and CAmkES

This section is adapted from the "Using Docker" page of the seL4 documentation.

### Requirements

These instructions assume you are using Debian or a derivative such as Ubuntu, and are using Bash for your shell. However, it should be informative enough for users of other distributions/shells to adapt.
To begin, you will need at least these two programs:

* `make` (`sudo apt install make`)
* `docker` (See [get.docker.com](https://get.docker.com) or [docs.docker.com](https://docs.docker.com) for installation instructions)
  For convenience, add your account to the Docker group:

```bash
sudo usermod -aG docker $(whoami)  
```

Note that after doing so you may have to logout of your account and log back in for the change to have effect.

### Setting up a build environment

To get a running build environment for seL4, run:

```bash
git clone https://github.com/seL4/seL4-CAmkES-L4v-dockerfiles.git  
cd seL4-CAmkES-L4v-dockerfiles  
make user  
```

This will give you a terminal inside a container that has all the relevant tools to build, simulate, and test seL4 and related projects.
The first time you run this, Docker will fetch the relevant images, which may take a while.

To map a particular directory into the container:

```bash
make user HOST_DIR=/scratch/seL4_stuff  # as an example  
# Now /host in the container maps to /scratch/seL4_stuff  
```

To make this easier to type, you can setup a bash alias such as this:

```bash
echo $'alias container=\'make -C /<path>/<to>/seL4‑CAmkES‑L4v‑dockerfiles user HOST_DIR=$(pwd)\'' >> ~/.bashrc  
# now open a new terminal, or run `source ~/.bashrc`  
```

Replace `/<path>/<to>/` to match where you cloned the git repo of the docker files. This then allows you to run:

```bash
container  
```

to start the container in the current directory you are in.

### An example workflow:

A good workflow is to run two terminals:

* Terminal A is a normal terminal, and is used for git and editing (e.g., vim, emacs, vscode).
* Terminal B is running a Docker container, and is only used for compilation.
  This gives you the flexibility to use all the tools you are used to, while having the seL4 dependencies separated from your machine.

#### Compiling seL4 test

Start two terminals, terminal A (host) and terminal B (docker).
In terminal A, run these commands:

```bash
jblogs@host:~$ mkdir ~/seL4test  
jblogs@host:~$ cd ~/seL4test  
jblogs@host:~/seL4test$ repo init -u https://github.com/seL4/sel4test-manifest.git  
jblogs@host:~/seL4test$ repo sync  
```

In terminal B, run these commands:

```bash
jblogs@host:~/seL4test$ container  # using the bash alias defined above  
jblogs@in-container:/host$ mkdir build-x86  
jblogs@in-container:/host$ cd build-x86  
jblogs@in-container:/host/build-x86$ ../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE  
jblogs@in-container:/host/build-x86$ ninja  
```

If you need to make any code modifications or commit things to git, use terminal A. If you need to recompile or simulate an image, use terminal B.

> **Note:** If QEMU fails when trying to simulate the image, try configuring your Docker host to give the container more memory.


## 3. Summary

* Install Docker and `make`.
* Clone the seL4‑CAmkES‑L4v‑dockerfiles repository and run `make user` to start a build container.
* Use the two‑terminal workflow (one for editing, one for compiling).
* Use `repo` with manifests (common.xml, master.xml, pinned) to manage multiple git repositories as a group.
* Use `repo init`, `repo sync`, `repo diff`, `repo status`, `repo diffmanifests` as needed.
