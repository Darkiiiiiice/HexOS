#include "multiboot2.h"

#define HEADER_LEN header_end - header
#define CHECKSUM -(MB_MAGIC + MB_ARCHITECTURE + HEADER_LEN)
    
.code32
.section .multiboot2
    header:
    .long MULTIBOOT2_HEADER_MAGIC	
    .long MULTIBOOT_ARCHITECTURE_I386 
    .long HEADER_LEN
    .long CHECKSUM
    header_end:
    
.section .bss
    .align 16
    stack_bottom:
        .skip 1024, 0
    stack_top:
    
.section .text
    _start:
        movl $stack_top, %esp

        call _kernel_init

        pushl %ebx
        call _kernel_main

        cli
    _j: 
        hlt
        jmp _j
