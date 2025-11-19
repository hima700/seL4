# Component Isolation Documentation

## Overview

This document describes the isolation mechanisms demonstrated in the seL4 Microkit IPC demo system with three components: client, server, and logger.

## Protection Domains

### 1. Client Protection Domain
- **Priority**: 99
- **Capabilities**:
  - Endpoint to server (channel 0, badge=1)
  - Notification endpoint to logger (channel 1)
  - Shared memory region (4KB, RW access at 0x20000000)
- **VSpace**: Separate virtual address space
- **CSpace**: Separate capability space with minimal grants

### 2. Server Protection Domain
- **Priority**: 100
- **Capabilities**:
  - Endpoint from client (channel 0, receives badge=1)
  - Reply capability for responding to client
  - Notification endpoint to logger (channel 1)
  - Shared memory region (4KB, RW access at 0x20000000)
- **VSpace**: Separate virtual address space
- **CSpace**: Separate capability space

### 3. Logger Protection Domain
- **Priority**: 98
- **Capabilities**:
  - Notification endpoints from client and server (channels 0 and 1)
  - **NO memory access** to client or server components
- **VSpace**: Separate virtual address space
- **CSpace**: Separate capability space with minimal grants (notifications only)

## Isolation Mechanisms

### VSpace Isolation

Each protection domain has its own virtual address space:
- Client: Maps shared memory at 0x20000000
- Server: Maps shared memory at 0x20000000 (same virtual address, different VSpace)
- Logger: No memory mappings (demonstrates complete isolation)

The kernel enforces that each component can only access memory it has been granted capabilities for.

### CSpace Isolation

Each protection domain has a separate capability space:
- Client CSpace contains:
  - Endpoint capability to server
  - Notification capability to logger
  - Memory capability for shared region
- Server CSpace contains:
  - Endpoint capability (passive, receives calls)
  - Reply capability
  - Notification capability to logger
  - Memory capability for shared region
- Logger CSpace contains:
  - Only notification capabilities (no memory, no endpoints)

### Least-Privilege Enforcement

The logger component demonstrates least-privilege:
- **Cannot** access client or server memory
- **Cannot** send messages to client or server
- **Can only** receive notifications and log them

This ensures that even if the logger is compromised, it cannot affect other components.

## Capability Flow

```
Client                    Server                    Logger
  |                         |                         |
  |--[endpoint, badge=1]-->|                         |
  |<--[reply]--------------|                         |
  |                         |                         |
  |--[shared mem, RW]------|                         |
  |                         |                         |
  |--[notification]---------------------------------->|
  |                         |--[notification]-------->|
```

## Security Properties

1. **Fault Isolation**: If client crashes, server and logger continue operating
2. **Memory Isolation**: Logger cannot read/write client or server memory
3. **Capability Isolation**: Each component only has capabilities it needs
4. **No Direct Communication**: Logger cannot directly communicate with client/server (only via notifications)

## Verification

To verify isolation:
1. Logger attempts to access shared_buffer (will fail - not mapped)
2. Logger attempts to send message to server (will fail - no endpoint capability)
3. Client and server can communicate via endpoint and shared memory
4. All components can notify logger (logger has notification capabilities)


