/*
 * Copyright 2025
 * seL4 Microkit Logger Component
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */
#include <stdint.h>
#include <microkit.h>

#define CLIENT_CH 0
#define SERVER_CH 1

#define LOG_BUFFER_SIZE 256
static char log_buffer[LOG_BUFFER_SIZE];
static int log_index = 0;

static void append_log(const char *msg)
{
    for (int i = 0; msg[i] != '\0' && log_index < LOG_BUFFER_SIZE - 1; i++) {
        log_buffer[log_index++] = msg[i];
    }
    if (log_index < LOG_BUFFER_SIZE - 1) {
        log_buffer[log_index++] = '\n';
    }
    log_buffer[LOG_BUFFER_SIZE - 1] = '\0';
}

void init(void)
{
    microkit_dbg_puts("LOGGER|INFO: Initializing logger component\n");
    microkit_dbg_puts("LOGGER|INFO: Logger has minimal capabilities (notifications only)\n");
    microkit_dbg_puts("LOGGER|INFO: No memory access to client or server components\n");
    append_log("Logger initialized");
}

void notified(microkit_channel ch)
{
    if (ch == CLIENT_CH) {
        microkit_dbg_puts("LOGGER|INFO: Received notification from client\n");
        append_log("Client notification");
        microkit_dbg_puts("LOGGER|INFO: Log entry added\n");
    } else if (ch == SERVER_CH) {
        microkit_dbg_puts("LOGGER|INFO: Received notification from server\n");
        append_log("Server notification");
        microkit_dbg_puts("LOGGER|INFO: Log entry added\n");
    } else {
        microkit_dbg_puts("LOGGER|WARN: Received notification on unexpected channel\n");
    }

    /* Print current log buffer */
    microkit_dbg_puts("LOGGER|INFO: Current log buffer:\n");
    for (int i = 0; i < log_index && i < LOG_BUFFER_SIZE; i++) {
        microkit_dbg_putc(log_buffer[i]);
    }
    microkit_dbg_puts("\n");
}


