/*
 * Copyright 2025
 * seL4 Microkit Fault Tolerance Demo - Server Component
 * 
 * This server continues functioning even when crasher component fails.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */
#include <stdint.h>
#include <microkit.h>

#define CLIENT_CH 0
#define CRASHER_CH 1
#define LOGGER_CH 2

void init(void)
{
    microkit_dbg_puts("SERVER|INFO: Initializing server component\n");
    microkit_dbg_puts("SERVER|INFO: Server ready to receive messages\n");
    microkit_dbg_puts("SERVER|INFO: Server will continue operating even if crasher fails\n");
}

microkit_msginfo protected(microkit_channel ch, microkit_msginfo msginfo)
{
    uint64_t label = microkit_msginfo_get_label(msginfo);
    
    if (ch == CLIENT_CH) {
        microkit_dbg_puts("SERVER|INFO: Received protected call from client (label=");
        microkit_dbg_putc('0' + (label % 10));
        microkit_dbg_puts(")\n");
        
        /* Send reply */
        return microkit_msginfo_new(label + 10, 0);
        
    } else if (ch == CRASHER_CH) {
        microkit_dbg_puts("SERVER|INFO: Received protected call from crasher (label=");
        microkit_dbg_putc('0' + (label % 10));
        microkit_dbg_puts(")\n");
        microkit_dbg_puts("SERVER|INFO: Server continues operating normally\n");
        
        /* Notify logger */
        microkit_notify(LOGGER_CH);
        
        /* Send reply */
        return microkit_msginfo_new(label + 20, 0);
    }
    
    /* Default reply */
    return microkit_msginfo_new(0, 0);
}

void notified(microkit_channel ch)
{
    if (ch == CLIENT_CH) {
        microkit_dbg_puts("SERVER|INFO: Received notification from client\n");
    } else if (ch == LOGGER_CH) {
        microkit_dbg_puts("SERVER|INFO: Received notification from logger\n");
    }
}

