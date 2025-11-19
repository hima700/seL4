/*
 * Copyright 2025
 * Linux IPC Server Component (equivalent to seL4 Microkit server)
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <time.h>
#include <stdint.h>
#include <limits.h>

#define SOCKET_PATH "/tmp/sel4_linux_server.sock"
#define SHARED_MEM_NAME "/sel4_linux_shared"
#define SHARED_MEM_SIZE 4096
#define LOGGER_SOCKET_PATH "/tmp/sel4_linux_logger.sock"

static int server_socket = -1;
static int logger_socket = -1;
static void *shared_mem = NULL;
static int shared_mem_fd = -1;
static volatile int running = 1;

/* High-resolution timestamp for measurements */
static uint64_t get_timestamp_ns(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

static void notify_logger(const char *msg)
{
    if (logger_socket >= 0) {
        struct sockaddr_un addr;
        memset(&addr, 0, sizeof(addr));
        addr.sun_family = AF_UNIX;
        strncpy(addr.sun_path, LOGGER_SOCKET_PATH, sizeof(addr.sun_path) - 1);
        
        if (connect(logger_socket, (struct sockaddr *)&addr, sizeof(addr)) == 0) {
            send(logger_socket, msg, strlen(msg), 0);
            close(logger_socket);
            logger_socket = socket(AF_UNIX, SOCK_DGRAM, 0);
        }
    }
}

static void handle_client_message(int client_fd, uint32_t label, uint64_t timestamp __attribute__((unused)))
{
    uint64_t start_time = get_timestamp_ns();
    
    switch (label) {
    case 1:
        printf("SERVER|INFO: Processing request type 1\n");
        /* Echo back with label 10 */
        label = 10;
        break;
    
    case 2:
        printf("SERVER|INFO: Processing request type 2\n");
        /* Echo back with label 20 */
        label = 20;
        break;
    
    default:
        printf("SERVER|ERROR: Unknown message label\n");
        label = 0;
        break;
    }
    
    uint64_t end_time = get_timestamp_ns();
    uint64_t latency = end_time - start_time;
    
    /* Send reply */
    send(client_fd, &label, sizeof(label), 0);
    send(client_fd, &latency, sizeof(latency), 0);
    
    printf("SERVER|METRIC: IPC latency=%lu ns\n", latency);
}

static void handle_shared_memory_notification(void)
{
    printf("SERVER|INFO: Received notification from client\n");
    printf("SERVER|INFO: Reading from shared memory: ");
    
    /* Read and print shared memory content */
    char *buf = (char *)shared_mem;
    printf("%s\n", buf);
    
    /* Write response back to shared memory */
    const char *response = "Server response via shared memory!";
    strncpy(buf, response, SHARED_MEM_SIZE - 1);
    buf[SHARED_MEM_SIZE - 1] = '\0';
    
    printf("SERVER|INFO: Wrote response to shared memory\n");
    
    /* Notify logger */
    notify_logger("Server processed shared memory");
}

static void signal_handler(int sig __attribute__((unused)))
{
    running = 0;
}

int main(void)
{
    struct sockaddr_un addr;
    int client_fd;
    uint32_t label;
    uint64_t client_timestamp;
    
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    printf("SERVER|INFO: Initializing server component\n");
    
    /* Create shared memory */
    shared_mem_fd = shm_open(SHARED_MEM_NAME, O_CREAT | O_RDWR, 0666);
    if (shared_mem_fd < 0) {
        perror("shm_open");
        exit(1);
    }
    
    if (ftruncate(shared_mem_fd, SHARED_MEM_SIZE) < 0) {
        perror("ftruncate");
        exit(1);
    }
    
    shared_mem = mmap(NULL, SHARED_MEM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, shared_mem_fd, 0);
    if (shared_mem == MAP_FAILED) {
        perror("mmap");
        exit(1);
    }
    
    /* Create logger socket */
    logger_socket = socket(AF_UNIX, SOCK_DGRAM, 0);
    
    /* Create server socket */
    server_socket = socket(AF_UNIX, SOCK_STREAM, 0);
    if (server_socket < 0) {
        perror("socket");
        exit(1);
    }
    
    /* Remove existing socket file */
    unlink(SOCKET_PATH);
    
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);
    
    if (bind(server_socket, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("bind");
        exit(1);
    }
    
    if (listen(server_socket, 5) < 0) {
        perror("listen");
        exit(1);
    }
    
    printf("SERVER|INFO: Server ready to receive messages\n");
    
    while (running) {
        client_fd = accept(server_socket, NULL, NULL);
        if (client_fd < 0) {
            if (running) {
                perror("accept");
            }
            continue;
        }
        
        /* Receive message */
        if (recv(client_fd, &label, sizeof(label), 0) == sizeof(label)) {
            if (label == 0xFFFFFFFF) {
                /* Special notification label for shared memory */
                handle_shared_memory_notification();
            } else {
                if (recv(client_fd, &client_timestamp, sizeof(client_timestamp), 0) == sizeof(client_timestamp)) {
                    handle_client_message(client_fd, label, client_timestamp);
                }
            }
        }
        
        close(client_fd);
    }
    
    /* Cleanup */
    close(server_socket);
    close(logger_socket);
    if (shared_mem != MAP_FAILED) {
        munmap(shared_mem, SHARED_MEM_SIZE);
    }
    if (shared_mem_fd >= 0) {
        shm_unlink(SHARED_MEM_NAME);
        close(shared_mem_fd);
    }
    unlink(SOCKET_PATH);
    
    return 0;
}

