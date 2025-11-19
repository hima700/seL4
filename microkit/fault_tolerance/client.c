/*
 * Copyright 2025
 * seL4 Microkit Fault Tolerance Demo - Client Component
 * 
 * This client continues functioning even when crasher component fails.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */
#include <stdint.h>
#include <microkit.h>

#define SERVER_CH 0
#define LOGGER_CH 1

void init(void)
{
    microkit_dbg_puts("CLIENT|INFO: Initializing client component\n");
    microkit_dbg_puts("CLIENT|INFO: Client will continue operating even if crasher fails\n");
    
    /* Wait a bit to let crasher crash first */
    for (volatile int i = 0; i < 2000000; i++);
    
    /* Send message to server after crasher has crashed */
    microkit_msginfo msg = microkit_msginfo_new(1, 0);
    microkit_dbg_puts("CLIENT|INFO: Sending message to server (after crasher crash)\n");
    microkit_msginfo reply = microkit_ppcall(SERVER_CH, msg);
    uint64_t reply_label = microkit_msginfo_get_label(reply);
    microkit_dbg_puts("CLIENT|INFO: Received reply from server (label=");
    microkit_dbg_putc('0' + (reply_label % 10));
    microkit_dbg_puts(") - Server still functioning!\n");
    
    /* Notify logger */
    microkit_dbg_puts("CLIENT|INFO: Notifying logger (after crasher crash)\n");
    microkit_notify(LOGGER_CH);
    
    microkit_dbg_puts("CLIENT|INFO: Client continues operating normally\n");
    microkit_dbg_puts("CLIENT|INFO: Fault containment demonstrated - other components unaffected\n");
}

void notified(microkit_channel ch)
{
    if (ch == SERVER_CH) {
        microkit_dbg_puts("CLIENT|INFO: Received notification from server\n");
    } else if (ch == LOGGER_CH) {
        microkit_dbg_puts("CLIENT|INFO: Received notification from logger\n");
    }
}


