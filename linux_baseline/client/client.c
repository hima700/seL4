/*
 * Copyright 2025
 * Linux IPC Client Component (equivalent to seL4 Microkit client)
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
#include <time.h>
#include <stdint.h>
#include <limits.h>

#define SERVER_SOCKET_PATH "/tmp/sel4_linux_server.sock"
#define LOGGER_SOCKET_PATH "/tmp/sel4_linux_logger.sock"
#define SHARED_MEM_NAME "/sel4_linux_shared"
#define SHARED_MEM_SIZE 4096

/* High-resolution timestamp for measurements */
static uint64_t get_timestamp_ns(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

static int connect_to_server(void)
{
    int sock = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock < 0) {
        perror("socket");
        return -1;
    }
    
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, SERVER_SOCKET_PATH, sizeof(addr.sun_path) - 1);
    
    if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("connect");
        close(sock);
        return -1;
    }
    
    return sock;
}

static void notify_logger(const char *msg)
{
    int sock = socket(AF_UNIX, SOCK_DGRAM, 0);
    if (sock < 0) {
        return;
    }
    
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, LOGGER_SOCKET_PATH, sizeof(addr.sun_path) - 1);
    
    if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) == 0) {
        send(sock, msg, strlen(msg), 0);
    }
    
    close(sock);
}

static uint64_t send_message_to_server(uint32_t label)
{
    int sock = connect_to_server();
    if (sock < 0) {
        return 0;
    }
    
    uint64_t start_time = get_timestamp_ns();
    
    /* Send message with timestamp */
    send(sock, &label, sizeof(label), 0);
    send(sock, &start_time, sizeof(start_time), 0);
    
    /* Receive reply */
    uint32_t reply_label;
    uint64_t server_latency;
    recv(sock, &reply_label, sizeof(reply_label), 0);
    recv(sock, &server_latency, sizeof(server_latency), 0);
    
    uint64_t end_time = get_timestamp_ns();
    uint64_t total_latency = end_time - start_time;
    
    close(sock);
    
    printf("CLIENT|INFO: Received reply from server (label=%u)\n", reply_label);
    printf("CLIENT|METRIC: Total IPC latency=%lu ns (server processing=%lu ns)\n", 
           total_latency, server_latency);
    
    return total_latency;
}

int main(int argc, char *argv[])
{
    int iterations = 1;
    if (argc > 1) {
        iterations = atoi(argv[1]);
    }
    
    printf("CLIENT|INFO: Initializing client component\n");
    printf("CLIENT|INFO: Running %d iterations\n", iterations);
    
    /* Open shared memory */
    int shared_mem_fd = shm_open(SHARED_MEM_NAME, O_RDWR, 0666);
    if (shared_mem_fd < 0) {
        perror("shm_open");
        exit(1);
    }
    
    void *shared_mem = mmap(NULL, SHARED_MEM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, shared_mem_fd, 0);
    if (shared_mem == MAP_FAILED) {
        perror("mmap");
        exit(1);
    }
    
    /* Wait for server to be ready */
    sleep(1);
    
    uint64_t total_latency = 0;
    uint64_t min_latency = UINT64_MAX;
    uint64_t max_latency = 0;
    
    for (int i = 0; i < iterations; i++) {
        /* Send initial message to server */
        uint32_t label = 1;
        printf("CLIENT|INFO: Sending message to server (label=%u, iteration=%d)\n", label, i + 1);
        uint64_t latency = send_message_to_server(label);
        
        if (latency > 0) {
            total_latency += latency;
            if (latency < min_latency) min_latency = latency;
            if (latency > max_latency) max_latency = latency;
        }
        
        /* Test shared memory communication */
        printf("CLIENT|INFO: Writing to shared memory\n");
        const char *test_data = "Hello from client via shared memory!";
        strncpy((char *)shared_mem, test_data, SHARED_MEM_SIZE - 1);
        ((char *)shared_mem)[SHARED_MEM_SIZE - 1] = '\0';
        
        /* Notify server that data is ready (using socket) */
        printf("CLIENT|INFO: Notifying server about shared memory data\n");
        int notify_sock = connect_to_server();
        if (notify_sock >= 0) {
            uint32_t notify_label = 0xFFFFFFFF; /* Special notification label */
            send(notify_sock, &notify_label, sizeof(notify_label), 0);
            close(notify_sock);
        }
        
        struct timespec ts = {0, 100000000}; /* 100ms */
        nanosleep(&ts, NULL);
        
        /* Send another message with different label */
        label = 2;
        printf("CLIENT|INFO: Sending second message (label=%u)\n", label);
        latency = send_message_to_server(label);
        
        if (latency > 0) {
            total_latency += latency;
            if (latency < min_latency) min_latency = latency;
            if (latency > max_latency) max_latency = latency;
        }
        
        /* Notify logger */
        printf("CLIENT|INFO: Notifying logger\n");
        notify_logger("Client notification");
        
        if (i < iterations - 1) {
            struct timespec ts = {0, 500000000}; /* 500ms */
            nanosleep(&ts, NULL);
        }
    }
    
    /* Print statistics */
    if (iterations > 0) {
        uint64_t avg_latency = total_latency / (iterations * 2); /* 2 messages per iteration */
        printf("\nCLIENT|METRIC: IPC Statistics (over %d iterations, %d messages):\n", 
               iterations, iterations * 2);
        printf("CLIENT|METRIC: Average latency: %lu ns (%.3f us)\n", avg_latency, avg_latency / 1000.0);
        printf("CLIENT|METRIC: Min latency: %lu ns (%.3f us)\n", min_latency, min_latency / 1000.0);
        printf("CLIENT|METRIC: Max latency: %lu ns (%.3f us)\n", max_latency, max_latency / 1000.0);
    }
    
    printf("CLIENT|INFO: Client initialization complete\n");
    
    /* Cleanup */
    munmap(shared_mem, SHARED_MEM_SIZE);
    close(shared_mem_fd);
    
    return 0;
}

