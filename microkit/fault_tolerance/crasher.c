/*
 * Copyright 2025
 * seL4 Microkit Fault Tolerance Demo - Crasher Component
 * 
 * This component intentionally crashes to demonstrate fault containment.
 * Other components (server, logger) should continue functioning.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */
#include <stdint.h>
#include <microkit.h>

#define SERVER_CH 0
#define LOGGER_CH 1

void init(void)
{
    microkit_dbg_puts("CRASHER|INFO: Initializing crasher component\n");
    microkit_dbg_puts("CRASHER|INFO: Will crash after 2 seconds to demonstrate fault containment\n");
    
    /* Send a message to server to show communication works */
    microkit_msginfo msg = microkit_msginfo_new(99, 0); /* label=99 (test message) */
    microkit_dbg_puts("CRASHER|INFO: Sending test message to server\n");
    microkit_msginfo reply = microkit_ppcall(SERVER_CH, msg);
    uint64_t reply_label = microkit_msginfo_get_label(reply);
    microkit_dbg_puts("CRASHER|INFO: Received reply from server (label=");
    microkit_dbg_putc('0' + (reply_label % 10));
    microkit_dbg_puts(")\n");
    
    /* Notify logger before crashing */
    microkit_dbg_puts("CRASHER|INFO: Notifying logger before crash\n");
    microkit_notify(LOGGER_CH);
    
    /* Wait a bit to ensure notifications are processed */
    for (volatile int i = 0; i < 1000000; i++);
    
    microkit_dbg_puts("CRASHER|ERROR: About to crash intentionally...\n");
    microkit_dbg_puts("CRASHER|ERROR: This demonstrates fault containment\n");
    
    /* Intentionally crash by dereferencing NULL pointer */
    volatile int *null_ptr = (volatile int *)0x0;
    *null_ptr = 0xDEADBEEF; /* This will cause a fault */
    
    /* Should never reach here */
    microkit_dbg_puts("CRASHER|ERROR: Should not reach here\n");
}

void notified(microkit_channel ch)
{
    /* Crasher doesn't handle notifications - will crash before receiving any */
}


