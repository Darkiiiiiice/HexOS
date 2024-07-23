OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)

ENTRY(_start)

SECTIONS {
    . = 0xFFFF800000000000;

    .text ALIGN (0x1000):
    {
        *(.text)
    }

    .rodata ALIGN (0x1000) :
    {
        *(.rodata*)
    }

    .data ALIGN (0x1000) :
    {
        *(.data)
    }

    .bss :
    {
        sbss = .;
        *(COMMON)
        *(.bss)
        ebss = .;
    }

    /DISCARD/ : {
        *(.commet)
        *(.eh_frame)
    }
}