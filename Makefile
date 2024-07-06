BUILD_DIR = build
IMAGE_DIR = ${BUILD_DIR}/hardware
IMAGE_FILE = ${IMAGE_DIR}/hardware.img

BIOS_DIR = bios
BIOS_IMAGE = ${BIOS_DIR}/OVMF.fd


TARGET_DIR = ${BUILD_DIR}/kernel
TARGET = ${TARGET_DIR}/kernel.bin

.PHONY: init

echo:
	@echo "BIOS_DIR: "${BIOS_DIR}
	@echo "BIOS_IMAGE: "${BIOS_IMAGE}
	@echo "BUILD_DIR: "${BUILD_DIR}
	@echo "IMAGE_DIR: "${IMAGE_DIR}
	@echo "IMAGE_FILE: "${IMAGE_FILE}
	@echo "TARGET_DIR: "${TARGET_DIR}
	@echo "TARGET: "${TARGET}

run: 
	qemu-system-x86_64 -bios ${BIOS_IMAGE} -m 4G -enable-kvm -hda ${IMAGE_FILE}

debug: 
	qemu-system-x86_64 -bios ${BIOS_IMAGE} -m 4G -enable-kvm -hda ${IMAGE_FILE} -s -S

init:
	mkdir -p ${IMAGE_DIR}
	mkdir -p ${TARGET_DIR}

modprobe:
	sudo modprobe nbd

load:
	echo loading kernel ......
	make mount
	sudo cp ${TARGET} /mnt/boot/
	make unmout

mount: modprobe
	@echo mount image ...
	sudo qemu-nbd --connect=/dev/nbd0 ${IMAGE_FILE}
	sudo mount /dev/nbd0p2 /mnt
	sudo mount -m /dev/nbd0p1 /mnt/boot

unmount:
	@echo umount image ...
	@sync
	sudo umount /dev/nbd0p1
	sudo umount /dev/nbd0p2
	sudo qemu-nbd -d /dev/nbd0

clean:
	@echo cleaning ...
	@rm -rf ${TARGET_DIR}

clean_image:
	@echo clean image files...
	@rm -rf ${IMAGE_FILE}

clean_all: 
	@echo cleaning all files...
	rm -rf ${BUILD_DIR}
	
	
	
	


