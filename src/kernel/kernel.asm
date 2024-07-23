%include "src/include/kernel.inc"

[bits 64]
    align 8

[section .data]
    
[section .text]

    mov ax, SELECTOR_DATA64
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    mov rsp, _kernel_stack_top
    


    jmp $
    
[section .bss]
    _kernel_stack_bottom:
    resq 0x100000 ; 8M stack
    _kernel_stack_top: