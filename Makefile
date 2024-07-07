
arch ?= x86_64

output_dir = out
grub_dir = boot/grub
kernel_dir = boot
iso_dir = isofiles

grub_cfg = grub/grub.cfg

assembly_ld = src/arch/$(arch)/linker.lds
assembly_dir = src/arch/$(arch)
assembly_source = $(wildcard src/arch/$(arch)/*.asm)
assembly_object = $(patsubst src/arch/$(arch)/%.asm, $(output_dir)/arch/$(arch)/%.o, $(assembly_source))

c_src = $(wildcard src/arch/$(arch)/*.c)
c_obj = $(patsubst src/arch/$(arch)/%.c, $(output_dir)/arch/$(arch)/%.o, $(c_src))

kernel = $(output_dir)/kernel.bin
iso = $(output_dir)/os-$(arch).iso

.PHONY:all clean

all: $(kernel) $(iso)


mkdir:
	mkdir -p $(output_dir)/$(grub_dir)
	mkdir -p $(output_dir)/arch/$(arch)

grub: $(grub_cfg)
	cp ./$(grub_cfg) $(output_dir)/$(grub_dir)

$(kernel): $(assembly_object) $(c_obj)
	ld -n -T $(assembly_ld) -o $(kernel) $(assembly_object) $(c_obj)


$(iso): $(kernel) $(grub_cfg)
	mkdir -p $(output_dir)/$(iso_dir)
	mkdir -p $(output_dir)/$(iso_dir)/$(grub_dir)

	cp -r $(grub_cfg) $(output_dir)/$(iso_dir)/$(grub_dir)
	cp -r $(kernel) $(output_dir)/$(iso_dir)/$(kernel_dir)

	grub-mkrescue -o $(iso) $(output_dir)/$(iso_dir)

run:
	qemu-system-x86_64 -cdrom $(iso) -m 8G -enable-kvm

clean:
	rm -rf $(output_dir)

# compile assembly file
$(output_dir)/arch/$(arch)/%.o: $(assembly_dir)/%.asm
	mkdir -p $(shell dirname $@)
	nasm -f elf64 $< -o $@

$(output_dir)/arch/$(arch)/%.o: src/arch/$(arch)/%.c
	mkdir -p $(shell dirname $@)
	clang -c -fno-builtin -O $< -o $@