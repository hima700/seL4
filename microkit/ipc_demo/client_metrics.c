/*
 * Copyright 2025
 * seL4 Microkit IPC Client Component with Metrics
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */
#include <stdint.h>
#include <microkit.h>

#define SERVER_CH 0
#define LOGGER_CH 1
#define SHARED_MEMORY_SIZE 4096

/* Shared memory region (mapped by system) */
uintptr_t shared_buffer = 0;
#define SHARED_BUF ((char *)shared_buffer)

/* High-resolution timestamp using CPU cycle counter (RDTSC equivalent) */
static inline uint64_t read_cycle_counter(void)
{
    uint64_t val;
    __asm__ volatile("mrs %0, cntpct_el0" : "=r"(val));
    return val;
}

/* Convert cycle counter to nanoseconds (assuming 1GHz counter) */
static uint64_t cycles_to_ns(uint64_t cycles)
{
    /* For ARM, CNTVCT_EL0 frequency is typically 62.5MHz or 100MHz
     * We'll read the actual frequency from CNTFRQ_EL0 */
    uint64_t freq;
    __asm__ volatile("mrs %0, cntfrq_el0" : "=r" (freq));
    return (cycles * 1000000000ULL) / freq;
}

void init(void)
{
    microkit_dbg_puts("CLIENT|INFO: Initializing client component with metrics\n");

    uint64_t total_latency = 0;
    uint64_t min_latency = UINT64_MAX;
    uint64_t max_latency = 0;
    int iterations = 10; /* Default iterations */
    
    for (int i = 0; i < iterations; i++) {
        /* Send initial message to server */
        uint64_t start_cycles = read_cycle_counter();
        microkit_msginfo msg = microkit_msginfo_new(1, 1);
        microkit_msginfo reply = microkit_ppcall(SERVER_CH, msg);
        uint64_t end_cycles = read_cycle_counter();
        
        uint64_t latency_ns = cycles_to_ns(end_cycles - start_cycles);
        total_latency += latency_ns;
        if (latency_ns < min_latency) min_latency = latency_ns;
        if (latency_ns > max_latency) max_latency = latency_ns;
        
        uint64_t reply_label = microkit_msginfo_get_label(reply);
        
        /* Test shared memory communication */
        const char *test_data = "Hello from client via shared memory!";
        for (int j = 0; test_data[j] != '\0' && j < SHARED_MEMORY_SIZE - 1; j++) {
            SHARED_BUF[j] = test_data[j];
        }
        SHARED_BUF[SHARED_MEMORY_SIZE - 1] = '\0';
        
        microkit_notify(SERVER_CH);
        
        /* Send another message */
        start_cycles = read_cycle_counter();
        msg = microkit_msginfo_new(2, 0);
        reply = microkit_ppcall(SERVER_CH, msg);
        end_cycles = read_cycle_counter();
        
        latency_ns = cycles_to_ns(end_cycles - start_cycles);
        total_latency += latency_ns;
        if (latency_ns < min_latency) min_latency = latency_ns;
        if (latency_ns > max_latency) max_latency = latency_ns;
        
        microkit_notify(LOGGER_CH);
    }
    
    /* Print statistics */
    uint64_t avg_latency = total_latency / (iterations * 2);
    microkit_dbg_puts("CLIENT|METRIC: IPC Statistics:\n");
    microkit_dbg_puts("CLIENT|METRIC: Average latency: ");
    /* Simple number printing */
    char buf[32];
    uint64_t val = avg_latency;
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
    
    microkit_dbg_puts("CLIENT|INFO: Client initialization complete\n");
}

void notified(microkit_channel ch)
{
    if (ch == SERVER_CH) {
        microkit_dbg_puts("CLIENT|INFO: Received notification from server\n");
    } else if (ch == LOGGER_CH) {
        microkit_dbg_puts("CLIENT|INFO: Received notification from logger\n");
    }
}


