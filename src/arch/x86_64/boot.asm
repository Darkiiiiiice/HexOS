; boot.asm
; Date: 2024-07-07
; Author: Darkiiiiiice

global _start
    
MB_MAGIC equ 0xE85250D6
MB_ARCHITECTURE equ 0x0

MB_HEADER_TAG_ENTRY_ADDRESS equ 0x3
MB_HEADER_TAG_FRAMEBUFFER equ 0x5
MB_HEADER_TAG_END equ 0x0

    
[section .multiboot2_header]
    
header_start:
    dd MB_MAGIC
    dd MB_ARCHITECTURE
    dd header_end - header_start
    dd -(MB_MAGIC + MB_ARCHITECTURE +(header_end - header_start))
header_end:

[section .bss]
stack_bottom:
    resb 64
stack_top:

[section .text]

    _start:
        mov esp, stack_top