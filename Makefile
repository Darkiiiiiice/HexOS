OS_ARCH := x86_64

BUILD_DIR := output
KERNEL_DIR := kernel
OBJECT_DIR := $(BUILD_DIR)/obj
BIN_DIR := $(BUILD_DIR)/bin
ISO_DIR := $(BUILD_DIR)/iso
ISO_BOOT_DIR := $(ISO_DIR)/boot
ISO_GRUB_DIR := $(ISO_BOOT_DIR)/grub

INCLUDES_DIR := src/include
INCLUDES := $(patsubst %, -I%, $(INCLUDES_DIR))

OS_NAME = hexos
OS_BIN = $(OS_NAME).bin
OS_ISO = $(OS_NAME).iso

LINKER_SCRIPT := src/arch/$(OS_ARCH)/linker.lds

CC := clang
# AS := as
AS := nasm

O := -O3
W := -Wall -Wextra
CFLAGS := -std=c23 -ffreestanding -mno-red-zone $(O) $(W)
LDFLAGS := -ffreestanding $(O) -nostdlib -lgcc 

SOURCE_FILES := $(shell find -name "*.[cs]")
SRC := $(patsubst ./%, $(OBJECT_DIR)/%.o, $(SOURCE_FILES))

# QEMU_DBG_FLAGS := -s -S -no-reboot -no-shutdown -d cpu,int  
QEMU_DBG_FLAGS := -s -S 

echo:
	echo $(BUILD_DIR)
	echo $(BIN_DIR)

$(OBJECT_DIR):
	mkdir -p $(OBJECT_DIR)
	
$(BIN_DIR):
	echo $(BIN_DIR)
	mkdir -p $(BIN_DIR)
	
$(ISO_DIR):
	mkdir -p $(ISO_DIR)
	mkdir -p $(ISO_BOOT_DIR)
	mkdir -p $(ISO_GRUB_DIR)
	
$(OBJECT_DIR)/%.s.o: %.s
	mkdir -p $(@D)
	$(AS) -f elf64 $< -o $@

$(OBJECT_DIR)/%.c.o: %.c
	mkdir -p $(@D)
	$(CC) $(INCLUDES) -c -fno-builtin $(CFLAGS) -O $< -o $@ 
	
$(BIN_DIR)/$(OS_BIN): $(OBJECT_DIR) $(BIN_DIR) $(SRC)
	ld.lld -n -T $(LINKER_SCRIPT) -o $(BIN_DIR)/$(OS_BIN) $(SRC)
	
$(BUILD_DIR)/$(OS_ISO): $(ISO_DIR) $(BIN_DIR)/$(OS_BIN) 
	cp grub/grub.cfg $(ISO_GRUB_DIR)/grub.cfg
	cp $(BIN_DIR)/$(OS_BIN) $(ISO_BOOT_DIR)/kernel.bin
	grub-mkrescue -o $(BUILD_DIR)/$(OS_ISO) $(ISO_DIR)
	
all: clean $(BUILD_DIR)/$(OS_ISO)

all-debug: O := -O0
all-debug: CFLAGS := -g -std=c23 -ffreestanding $(O) $(W) -fomit-frame-pointer
all-debug: LDFLAGS := -ffreestanding $(0) -nostdlib -lgcc
all-debug: clean $(BUILD_DIR)/$(OS_ISO)
	objdump -M intel -D $(BIN_DIR)/$(OS_BIN) > dump

clean:
	rm -rf $(BUILD_DIR)

run: $(BUILD_DIR)/$(OS_DIR)
	qemu-system-x86_64 -cdrom $(BUILD_DIR)/$(OS_ISO) -bios bios/OVMF.fd

debug-qemu: all-debug
	objcopy --only-keep-debug $(BIN_DIR)/$(OS_BIN) $(BUILD_DIR)/kernel.dbg
	qemu-system-x86_64 $(QEMU_DBG_FLAGS) -cdrom $(BUILD_DIR)/$(OS_ISO) 
	
debug-qemu-gdb: all-debug
	objcopy --only-keep-debug $(BIN_DIR)/$(OS_BIN) $(BUILD_DIR)/kernel.dbg
	qemu-system-x86_64 $(QEMU_DBG_FLAGS) -cdrom $(BUILD_DIR)/$(OS_ISO) & \
	gdb -s $(BUILD_DIR)/kernel.dbg -ex "target remote localhost:1234"
	
debug-bochs: all-debug
	bochs -q -f bochs.cfg
	
