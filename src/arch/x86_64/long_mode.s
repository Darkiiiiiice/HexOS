global _long_entry

extern _kernel_main

[section .text]
[bits 64]

_long_entry:

    mov rcx, 0x19940101
    
    call _kernel_main
    
    hlt
