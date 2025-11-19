CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11
LDFLAGS = -lrt -lpthread

CLIENT_DIR = client
SERVER_DIR = server
LOGGER_DIR = logger

CLIENT_TARGET = $(CLIENT_DIR)/client
SERVER_TARGET = $(SERVER_DIR)/server
LOGGER_TARGET = $(LOGGER_DIR)/logger

all: $(CLIENT_TARGET) $(SERVER_TARGET) $(LOGGER_TARGET)

$(CLIENT_TARGET): $(CLIENT_DIR)/client.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

$(SERVER_TARGET): $(SERVER_DIR)/server.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

$(LOGGER_TARGET): $(LOGGER_DIR)/logger.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(CLIENT_TARGET) $(SERVER_TARGET) $(LOGGER_TARGET)
	rm -f /tmp/sel4_linux_*.sock
	rm -f /dev/shm/sel4_linux_shared

.PHONY: all clean


