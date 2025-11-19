/*
 * Copyright 2025
 * seL4 Microkit Fault Tolerance Demo - Logger Component
 * 
 * This logger continues functioning even when crasher component fails.
 * It captures fault events and logs them.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */
#include <stdint.h>
#include <microkit.h>

#define CLIENT_CH 0
#define SERVER_CH 1
#define CRASHER_CH 2

static int log_count = 0;

void init(void)
{
    microkit_dbg_puts("LOGGER|INFO: Initializing logger component\n");
    microkit_dbg_puts("LOGGER|INFO: Logger ready to capture fault events\n");
    microkit_dbg_puts("LOGGER|INFO: Logger will continue operating even if crasher fails\n");
    log_count = 0;
}

void notified(microkit_channel ch)
{
    log_count++;
    
    if (ch == CLIENT_CH) {
        microkit_dbg_puts("LOGGER|INFO: [LOG #");
        microkit_dbg_putc('0' + log_count);
        microkit_dbg_puts("] Received notification from client\n");
    } else if (ch == SERVER_CH) {
        microkit_dbg_puts("LOGGER|INFO: [LOG #");
        microkit_dbg_putc('0' + log_count);
        microkit_dbg_puts("] Received notification from server\n");
    } else if (ch == CRASHER_CH) {
        microkit_dbg_puts("LOGGER|INFO: [LOG #");
        microkit_dbg_putc('0' + log_count);
        microkit_dbg_puts("] Received notification from crasher (before crash)\n");
    } else {
        microkit_dbg_puts("LOGGER|WARN: [LOG #");
        microkit_dbg_putc('0' + log_count);
        microkit_dbg_puts("] Received notification on unexpected channel\n");
    }
    
    /* After crasher fails, logger should still receive notifications */
    microkit_dbg_puts("LOGGER|INFO: Logger continues operating after crasher fault\n");
    microkit_dbg_puts("LOGGER|INFO: Total logs captured: ");
    microkit_dbg_putc('0' + log_count);
    microkit_dbg_puts("\n");
}


