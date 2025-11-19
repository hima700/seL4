# Fault Tolerance Demonstration

## Overview

This document describes the fault tolerance demonstration that shows how seL4's isolation mechanisms prevent fault propagation between components.

## Objective

Demonstrate that when one component (crasher) intentionally fails, other components (server, client, logger) continue functioning normally, proving fault containment.

## Components

### 1. Crasher Component
- **Purpose**: Intentionally crashes to demonstrate fault containment
- **Behavior**: 
  - Sends a test message to server
  - Notifies logger
  - Intentionally dereferences NULL pointer to cause a fault
- **Expected**: Component fails, but fault is contained

### 2. Server Component
- **Purpose**: Continues operating after crasher fails
- **Behavior**:
  - Receives messages from client and crasher
  - Processes requests normally
  - Notifies logger
- **Expected**: Continues functioning after crasher crash

### 3. Client Component
- **Purpose**: Continues operating after crasher fails
- **Behavior**:
  - Waits for crasher to crash
  - Sends messages to server
  - Notifies logger
- **Expected**: Continues functioning after crasher crash

### 4. Logger Component
- **Purpose**: Captures fault events and continues operating
- **Behavior**:
  - Receives notifications from all components
  - Logs events including crasher's pre-crash notification
  - Continues receiving notifications after crash
- **Expected**: Continues functioning and captures fault events

## System Architecture

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Client  │────▶│  Server  │────▶│  Logger  │
└──────────┘     └──────────┘     └──────────┘
     │                 ▲                 ▲
     │                 │                 │
     │            ┌──────────┐          │
     └────────────▶│ Crasher  │──────────┘
                   └──────────┘
                      (fails)
```

## Fault Containment Mechanisms

### 1. Protection Domain Isolation
- Each component runs in a separate protection domain
- Faults in one domain cannot affect others
- seL4 kernel enforces strict isolation

### 2. Capability-Based Access Control
- Components only have capabilities they need
- Crasher has no access to other components' memory
- Fault cannot propagate through unauthorized access

### 3. Fault Handling
- seL4 kernel handles faults at the protection domain level
- Faulting component is isolated
- Other components continue normal operation

## Running the Demonstration

### Build
```bash
./scripts/build.sh fault_tolerance qemu_virt_aarch64 debug
```

### Run and Capture Logs
```bash
./scripts/capture_logs.sh fault_tolerance qemu_virt_aarch64 debug
```

This will:
- Display output on screen (same as `run.sh`)
- Save logs to `out/fault_logs_YYYYMMDD_HHMMSS.txt`

Or run normally (without saving logs):
```bash
./scripts/run.sh fault_tolerance qemu_virt_aarch64 debug
```

## Expected Output

### Actual Output (Verified Working)

The demonstration shows:

**Before Crash**:
```
CRASHER|INFO: Initializing crasher component
CRASHER|INFO: Sending test message to server
SERVER|INFO: Received protected call from crasher (label=9)
SERVER|INFO: Server continues operating normally
CRASHER|INFO: Received reply from server
CRASHER|INFO: Notifying logger before crash
LOGGER|INFO: [LOG #3] Received notification from crasher (before crash)
CRASHER|ERROR: About to crash intentionally...
CRASHER|ERROR: This demonstrates fault containment
```

**Fault Detection**:
```
MON|ERROR: received message 0x00000006  badge: 0x0000000000000004  tcb cap: 0x8000000000000016
MON|ERROR: faulting PD: crasher
MON|ERROR: VMFault: ip=0x0000000000200114  fault_addr=0x0000000000000000  fsr=0x00000000939f0046  (data fault)
MON|ERROR:   ec: 0x00000024  Data Abort from a lower Exception level   il: 1   iss: 0x019f0046
MON|ERROR:   dfsc = translation fault, level 2 (0x00000006) -- write not read
```

**After Crash - Components Continue**:
```
CLIENT|INFO: Sending message to server (after crasher crash)
SERVER|INFO: Received protected call from client (label=1)
CLIENT|INFO: Received reply from server (label=1) - Server still functioning!
CLIENT|INFO: Client continues operating normally
CLIENT|INFO: Fault containment demonstrated - other components unaffected
LOGGER|INFO: [LOG #1] Received notification from client
LOGGER|INFO: Logger continues operating after crasher fault
LOGGER|INFO: Total logs captured: 1
```

## Log Analysis

### Key Indicators of Fault Containment

1. **Crasher Fault**: Look for crasher error messages, then silence
2. **Server Continuity**: Server continues processing requests from client
3. **Logger Continuity**: Logger continues receiving notifications
4. **Client Continuity**: Client successfully communicates with server after crash
5. **No Cross-Component Impact**: No error messages from server/client/logger related to crasher

### Log Patterns to Verify

- Crasher sends message before crash
- Crasher notifies logger before crash
- Crasher crashes (fault occurs)
- Server processes client requests after crash
- Logger receives notifications after crash
- Client successfully communicates after crash
- No fault propagation to other components

## Fault Containment Verification

The demonstration proves:

1. **Isolation**: Faults are contained within the failing component
2. **Resilience**: System continues operating despite component failure
3. **Observability**: Logger captures fault events for analysis
4. **No Cascading Failures**: One component's failure doesn't affect others

## Security Implications

This demonstrates seL4's security properties:
- **Fault Isolation**: Prevents fault propagation
- **Least Privilege**: Components can't access what they don't need
- **Fail-Safe**: System degrades gracefully on component failure
- **Auditability**: Faults are logged and observable

