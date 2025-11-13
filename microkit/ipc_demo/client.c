/*
 * Copyright 2025
 * seL4 Microkit IPC Client Component
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */
#include <stdint.h>
#include <microkit.h>

#define SERVER_CH 0
#define LOGGER_CH 1
#define SHARED_MEMORY_SIZE 4096

/* Shared memory region (mapped by system) */
/* The system.system file sets setvar_vaddr="shared_buffer" which creates a uintptr_t variable */
/* Default to 0, Microkit tool will patch this with actual virtual address */
uintptr_t shared_buffer = 0;

/* Helper macro to access shared memory as a char array */
#define SHARED_BUF ((char *)shared_buffer)

void init(void)
{
    microkit_dbg_puts("CLIENT|INFO: Initializing client component\n");

    /* Send initial message to server */
    microkit_msginfo msg = microkit_msginfo_new(1, 1); /* label=1, count=1 */
    microkit_dbg_puts("CLIENT|INFO: Sending message to server (label=1)\n");
    microkit_msginfo reply = microkit_ppcall(SERVER_CH, msg);
    
    uint64_t reply_label = microkit_msginfo_get_label(reply);
    microkit_dbg_puts("CLIENT|INFO: Received reply from server (label=");
    microkit_dbg_putc('0' + reply_label);
    microkit_dbg_puts(")\n");

    /* Test shared memory communication */
    microkit_dbg_puts("CLIENT|INFO: Writing to shared memory\n");
    const char *test_data = "Hello from client via shared memory!";
    for (int i = 0; test_data[i] != '\0' && i < SHARED_MEMORY_SIZE - 1; i++) {
        SHARED_BUF[i] = test_data[i];
    }
    SHARED_BUF[SHARED_MEMORY_SIZE - 1] = '\0';

    /* Notify server that data is ready */
    microkit_dbg_puts("CLIENT|INFO: Notifying server about shared memory data\n");
    microkit_notify(SERVER_CH);

    /* Send another message with different label */
    msg = microkit_msginfo_new(2, 0); /* label=2, count=0 */
    microkit_dbg_puts("CLIENT|INFO: Sending second message (label=2)\n");
    reply = microkit_ppcall(SERVER_CH, msg);
    reply_label = microkit_msginfo_get_label(reply);
    microkit_dbg_puts("CLIENT|INFO: Received reply (label=");
    microkit_dbg_putc('0' + reply_label);
    microkit_dbg_puts(")\n");

    /* Notify logger */
    microkit_dbg_puts("CLIENT|INFO: Notifying logger\n");
    microkit_notify(LOGGER_CH);

    microkit_dbg_puts("CLIENT|INFO: Client initialization complete\n");
}

void notified(microkit_channel ch)
{
    if (ch == SERVER_CH) {
        microkit_dbg_puts("CLIENT|INFO: Received notification from server\n");
    } else if (ch == LOGGER_CH) {
        microkit_dbg_puts("CLIENT|INFO: Received notification from logger\n");
    } else {
        microkit_dbg_puts("CLIENT|WARN: Received notification on unexpected channel\n");
    }
}

