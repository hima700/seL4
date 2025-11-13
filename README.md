# seL4 Microkernel Multi-Component System

This project implements a PC-based seL4 microkernel system using Microkit on x86_64 via QEMU. It demonstrates IPC, capability-based isolation, and component architecture.

## Project Structure

```
seL4/
├── microkit/           # Microkit applications
│   ├── hello_world/    # Baseline hello world (Step 1)
│   └── ipc_demo/       # Client-server-logger (Steps 2-3)
├── microkit-sdk/       # Microkit SDK 2.0.1
├── scripts/            # Build and run scripts
│   ├── build.sh        # Build applications
│   ├── run.sh          # Run in QEMU
│   └── clean.sh        # Clean build artifacts
├── docs/               # Architecture diagrams
├── out/                # Build output directory
├── seL4-CAmkES-L4v-dockerfiles/  # Docker build environment
├── COMMANDS.md         # Command trace log
└── README.md           # This file
```

## Requirements

- Windows 10/11 with WSL2 (Ubuntu)
- Docker Desktop (for seL4 build container)
- QEMU (for running virtualized systems)
- Make and standard build tools

## Quick Start

### Step 1: Setup and Baseline Environment

1. **Verify WSL2 and Docker:**
   ```powershell
   wsl --status
   docker --version
   ```

2. **Build hello world application:**
   ```bash
   # In WSL2
   cd /mnt/c/Users/Ibrah/Desktop/RA/sel4/seL4
   ./scripts/build.sh hello_world qemu_virt_aarch64 debug
   ```

3. **Run in QEMU:**
   ```bash
   ./scripts/run.sh hello_world qemu_virt_aarch64 debug
   ```

### Building

The build script requires:
- Application name (hello_world or ipc_demo)
- Board (qemu_virt_aarch64, qemu_virt_riscv64)
- Config (debug, release, benchmark)

Example:
```bash
./scripts/build.sh hello_world qemu_virt_aarch64 debug
```

### Running

The run script launches QEMU with the built image:
```bash
./scripts/run.sh hello_world qemu_virt_aarch64 debug
```

Press `Ctrl+A` then `X` to exit QEMU.

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

**Step 1: Setup and Baseline Environment** ✓
- Microkit SDK 2.0.1 installed
- Hello world baseline application created
- Build and run scripts implemented

**Step 2: IPC Client-Server Implementation** ✓
- Client component with message passing
- Server component with protected call handler
- Shared memory communication (4KB region)
- Badge-based client identification
- Reply objects for request/response protocol

**Step 3: Component Isolation** ✓
- Logger component as third protection domain
- VSpace isolation (separate virtual address spaces)
- CSpace isolation (separate capability spaces)
- Least-privilege enforcement (logger has notifications only)
- Capability mapping documentation

### Architecture

The system consists of three protection domains:
- **Client**: Sends messages to server, uses shared memory, notifies logger
- **Server**: Receives messages, processes requests, uses shared memory, notifies logger
- **Logger**: Receives notifications only, no memory access to other components

See `docs/ARCHITECTURE.txt` and `docs/ISOLATION.md` for detailed documentation.

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
