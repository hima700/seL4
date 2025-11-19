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

/* Simple cycle counter read for ARM */
static inline uint64_t read_cycle_counter(void)
{
    uint64_t val;
    /* Use physical counter (CNTPC_EL0) which is exported to EL0 */
    __asm__ volatile("mrs %0, cntpct_el0" : "=r" (val));
    return val;
}

/* Convert cycles to nanoseconds */
static uint64_t cycles_to_ns(uint64_t cycles)
{
    uint64_t freq;
    __asm__ volatile("mrs %0, cntfrq_el0" : "=r" (freq));
    return (cycles * 1000000000ULL) / freq;
}

void init(void)
{
    microkit_dbg_puts("CLIENT|INFO: Initializing client component\n");
    
    /* Wait a bit to ensure server is ready - simple delay loop */
    for (volatile int i = 0; i < 2000000; i++) {
        /* Empty loop - compiler won't optimize away volatile */
    }

    /* Send initial message to server with timing */
    uint64_t start_cycles = read_cycle_counter();
    microkit_msginfo msg = microkit_msginfo_new(1, 1); /* label=1, count=1 */
    microkit_dbg_puts("CLIENT|INFO: Sending message to server (label=1)\n");
    microkit_msginfo reply = microkit_ppcall(SERVER_CH, msg);
    uint64_t end_cycles = read_cycle_counter();
    
    uint64_t latency_ns = cycles_to_ns(end_cycles - start_cycles);
    
    /* Output latency metric - CRITICAL for metrics extraction */
    microkit_dbg_puts("CLIENT|METRIC: latency=");
    /* Simple number printing for latency */
    char buf[32];
    uint64_t val = latency_ns;
    int pos = 0;
    do {
        buf[pos++] = '0' + (val % 10);
        val /= 10;
    } while (val > 0 && pos < 31);
    buf[pos] = '\0';
    for (int i = pos - 1; i >= 0; i--) {
        microkit_dbg_putc(buf[i]);
    }
    microkit_dbg_puts(" ns\n");
    
    uint64_t reply_label = microkit_msginfo_get_label(reply);
    microkit_dbg_puts("CLIENT|INFO: Received reply from server (label=");
    microkit_dbg_putc('0' + reply_label);
    microkit_dbg_puts(")\n");

    /* Test shared memory communication - use shared_buffer directly */
    /* Microkit tool patches shared_buffer with correct address */
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

