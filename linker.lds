OUTPUT_FORMAT("elf64-x86-64")
OUTPUT_ARCH(i386:x86_64)
ENTRY(_start)

SECTIONS{
	/* boot loader will load the kernel there */
	. = 0x100000
	__boot_start = .;

	/* ASM boot-state kernel */

	.boot.loader :
	{
		KEEP(*(.boot.header))
		*(.boot.*)
		arch/x86_64/boot/libBoot.a
	}

	. = ALIGN(0x1000);

	/* C boot-state kernel */
	.boot.text ALIGN(0x1000) :
	{
		arch/x86_64/boot/libBoot.a(.text)
	}

	. = ALIGN(0x1000);
	.boot.rodata ALIGN(0x1000) :
	{
		arch/x86_64/boot/libBoot.a(.rodata)
	}

	. = ALIGN(0x1000);
	.boot.data ALIGN(0x1000) :
	{
		arch/x86_64/boot/libBoot.a(.data)
		arch/x86_64/boot/libBoot.a(.*)
	}

	. = ALIGN(0x1000);

	__boot_end = .;
}
