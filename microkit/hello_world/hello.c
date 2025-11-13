/*
 * Copyright 2025
 * seL4 Microkernel Hello World Baseline
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */
#include <stdint.h>
#include <microkit.h>

void init(void)
{
    microkit_dbg_puts("=== seL4 Microkit Hello World ===\n");
    microkit_dbg_puts("Baseline verification successful\n");
    microkit_dbg_puts("System initialized and running\n");
}

void notified(microkit_channel ch)
{
    /* No notifications expected in hello world */
}

