#
# Makefile for Fault Tolerance Demo
# Demonstrates fault containment: crasher fails, others continue
#

ifeq ($(strip $(BUILD_DIR)),)
$(error BUILD_DIR must be specified)
endif

ifeq ($(strip $(MICROKIT_SDK)),)
$(error MICROKIT_SDK must be specified)
endif

ifeq ($(strip $(MICROKIT_BOARD)),)
$(error MICROKIT_BOARD must be specified)
endif

ifeq ($(strip $(MICROKIT_CONFIG)),)
$(error MICROKIT_CONFIG must be specified)
endif

BOARD_DIR := $(MICROKIT_SDK)/board/$(MICROKIT_BOARD)/$(MICROKIT_CONFIG)

ARCH := ${shell grep 'CONFIG_SEL4_ARCH  ' $(BOARD_DIR)/include/kernel/gen_config.h | cut -d' ' -f4}

ifeq ($(ARCH),aarch64)
	TOOLCHAIN := aarch64-none-elf
	CFLAGS_ARCH :=
else ifeq ($(ARCH),riscv64)
	TOOLCHAIN := riscv64-unknown-elf
	CFLAGS_ARCH := -march=rv64imafdc_zicsr_zifencei -mabi=lp64d
else
$(error Unsupported ARCH)
endif

CC := $(TOOLCHAIN)-gcc
LD := $(TOOLCHAIN)-ld
MICROKIT_TOOL ?= $(MICROKIT_SDK)/bin/microkit

SERVER_OBJS := server.o
CLIENT_OBJS := client.o
LOGGER_OBJS := logger.o
CRASHER_OBJS := crasher.o

IMAGES := server.elf client.elf logger.elf crasher.elf

CFLAGS := -mstrict-align -nostdlib -ffreestanding -g -O3 -Wall -Wno-unused-function -Werror -I$(BOARD_DIR)/include $(CFLAGS_ARCH)
LDFLAGS := -L$(BOARD_DIR)/lib
LIBS := -lmicrokit -Tmicrokit.ld

IMAGE_FILE = $(BUILD_DIR)/loader.img
REPORT_FILE = $(BUILD_DIR)/report.txt

all: $(IMAGE_FILE)

$(BUILD_DIR)/%.o: %.c Makefile
	$(CC) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/server.elf: $(addprefix $(BUILD_DIR)/, $(SERVER_OBJS))
	$(LD) $(LDFLAGS) $^ $(LIBS) -o $@

$(BUILD_DIR)/client.elf: $(addprefix $(BUILD_DIR)/, $(CLIENT_OBJS))
	$(LD) $(LDFLAGS) $^ $(LIBS) -o $@

$(BUILD_DIR)/logger.elf: $(addprefix $(BUILD_DIR)/, $(LOGGER_OBJS))
	$(LD) $(LDFLAGS) $^ $(LIBS) -o $@

$(BUILD_DIR)/crasher.elf: $(addprefix $(BUILD_DIR)/, $(CRASHER_OBJS))
	$(LD) $(LDFLAGS) $^ $(LIBS) -o $@

$(IMAGE_FILE) $(REPORT_FILE): $(addprefix $(BUILD_DIR)/, $(IMAGES)) system.system
	$(MICROKIT_TOOL) system.system --search-path $(BUILD_DIR) --board $(MICROKIT_BOARD) --config $(MICROKIT_CONFIG) -o $(IMAGE_FILE) -r $(REPORT_FILE)

.PHONY: all clean

clean:
	rm -f $(BUILD_DIR)/*.o $(BUILD_DIR)/*.elf $(IMAGE_FILE) $(REPORT_FILE)


