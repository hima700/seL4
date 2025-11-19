/*
 * Copyright 2025
 * Linux IPC Logger Component (equivalent to seL4 Microkit logger)
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <signal.h>
#include <time.h>

#define LOGGER_SOCKET_PATH "/tmp/sel4_linux_logger.sock"
#define LOG_BUFFER_SIZE 256

static int logger_socket = -1;
static char log_buffer[LOG_BUFFER_SIZE];
static int log_index = 0;
static volatile int running = 1;

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

static void signal_handler(int sig __attribute__((unused)))
{
    running = 0;
}

int main(void)
{
    struct sockaddr_un addr;
    char buffer[256];
    ssize_t n;
    
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    printf("LOGGER|INFO: Initializing logger component\n");
    printf("LOGGER|INFO: Logger has minimal capabilities (notifications only)\n");
    printf("LOGGER|INFO: No memory access to client or server components\n");
    
    append_log("Logger initialized");
    
    /* Create logger socket */
    logger_socket = socket(AF_UNIX, SOCK_DGRAM, 0);
    if (logger_socket < 0) {
        perror("socket");
        exit(1);
    }
    
    /* Remove existing socket file */
    unlink(LOGGER_SOCKET_PATH);
    
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, LOGGER_SOCKET_PATH, sizeof(addr.sun_path) - 1);
    
    if (bind(logger_socket, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("bind");
        exit(1);
    }
    
    printf("LOGGER|INFO: Logger ready to capture events\n");
    
    while (running) {
        n = recv(logger_socket, buffer, sizeof(buffer) - 1, 0);
        if (n > 0) {
            buffer[n] = '\0';
            
            if (strstr(buffer, "Client") != NULL) {
                printf("LOGGER|INFO: Received notification from client\n");
                append_log("Client notification");
            } else if (strstr(buffer, "Server") != NULL) {
                printf("LOGGER|INFO: Received notification from server\n");
                append_log("Server notification");
            } else {
                printf("LOGGER|INFO: Received notification: %s\n", buffer);
                append_log(buffer);
            }
            
            printf("LOGGER|INFO: Log entry added\n");
            
            /* Print current log buffer */
            printf("LOGGER|INFO: Current log buffer:\n");
            for (int i = 0; i < log_index && i < LOG_BUFFER_SIZE; i++) {
                putchar(log_buffer[i]);
            }
            printf("\n");
        } else if (n < 0 && running) {
            perror("recv");
        }
    }
    
    /* Cleanup */
    close(logger_socket);
    unlink(LOGGER_SOCKET_PATH);
    
    return 0;
}

