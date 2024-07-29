%include "src/include/kernel.inc"

    extern _setup_gdt
    extern _setup_high_mem_mapping
[bits 64]
    align 8
    
    
[segment .text]
_start:
    
    call _setup_gdt
    
    call _setup_high_mem_mapping

    mov ax, SELECTOR_DATA64
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    mov rsp, _kernel_stack_top
    
    ; enable PCID
    mov rax, cr4
    bts rax, 0x11
    mov cr4, rax
    
    mov rax, 0x123456789
    


    jmp $

[segment .data]
    align 8
    hello db "HelloWor"
    
[segment .bss]
    align 8
    _kernel_stack_bottom:
    resq 0x1000 ; 32k stack
    _kernel_stack_top: