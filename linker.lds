OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(x86-64)

ENTRY(_start)

SECTIONS {
    . = 0xFFFF800000100000;

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

    .bss ALIGN (0x1000) :
    {
        sbss = .;
        *(.bss)
        ebss = .;
    }
    
    .shstrtab ALIGN (0x1000) :
    {
        *(.shstrtab)
    }

    /DISCARD/ : {
        *(.comment)
        *(.eh_frame)
        *(.symtab)
        *(.strtab)
    }
}