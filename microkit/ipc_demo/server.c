/*
 * Copyright 2025
 * seL4 Microkit IPC Server Component
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */
#include <stdint.h>
#include <microkit.h>

#define CLIENT_CH 0
#define SHARED_MEMORY_SIZE 4096

/* Shared memory region (mapped by system) */
extern char shared_buffer[SHARED_MEMORY_SIZE];

microkit_msginfo protected(microkit_channel ch, microkit_msginfo msginfo)
{
    uint64_t label = microkit_msginfo_get_label(msginfo);
    uint64_t badge = microkit_msginfo_get_badge(msginfo);

    microkit_dbg_puts("SERVER|INFO: Received protected call (label=");
    microkit_dbg_putc('0' + label);
    microkit_dbg_puts(", badge=");
    microkit_dbg_putc('0' + badge);
    microkit_dbg_puts(")\n");

    switch (label) {
    case 1:
        microkit_dbg_puts("SERVER|INFO: Processing request type 1\n");
        /* Echo back with label 10 */
        return microkit_msginfo_new(10, 0);
    
    case 2:
        microkit_dbg_puts("SERVER|INFO: Processing request type 2\n");
        /* Echo back with label 20 */
        return microkit_msginfo_new(20, 0);
    
    default:
        microkit_dbg_puts("SERVER|ERROR: Unknown message label\n");
        return microkit_msginfo_new(0, 0);
    }
}

void init(void)
{
    microkit_dbg_puts("SERVER|INFO: Initializing server component\n");
    microkit_dbg_puts("SERVER|INFO: Server ready to receive messages\n");
}

void notified(microkit_channel ch)
{
    if (ch == CLIENT_CH) {
        microkit_dbg_puts("SERVER|INFO: Received notification from client\n");
        microkit_dbg_puts("SERVER|INFO: Reading from shared memory: ");
        
        /* Read and print shared memory content */
        for (int i = 0; i < SHARED_MEMORY_SIZE && shared_buffer[i] != '\0'; i++) {
            microkit_dbg_putc(shared_buffer[i]);
        }
        microkit_dbg_puts("\n");

        /* Write response back to shared memory */
        const char *response = "Server response via shared memory!";
        for (int i = 0; response[i] != '\0' && i < SHARED_MEMORY_SIZE - 1; i++) {
            shared_buffer[i] = response[i];
        }
        shared_buffer[SHARED_MEMORY_SIZE - 1] = '\0';

        microkit_dbg_puts("SERVER|INFO: Wrote response to shared memory\n");
    } else {
        microkit_dbg_puts("SERVER|WARN: Received notification on unexpected channel\n");
    }
}

