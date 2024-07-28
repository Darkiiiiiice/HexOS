%include "src/include/kernel.inc"

[bits 64]
    align 8

[segment .data]
    hello db "HelloWor"
    
[segment .text]

    ; mapping 0xFFFF8000_00000000 to phy 0x00000000_00000000
    mov rax, cr3
    mov rdi, rax
    lea rax, [rdi + 0x1000]
    or eax, 0x3
    mov [rdi + 0x100 * 8], rax

    mov ax, SELECTOR_DATA64
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    mov rsp, _kernel_stack_top
    
    mov rax, 0x123456789
    


    jmp $
    
[segment .bss]
    _kernel_stack_bottom:
    resq 0x1000 ; 32k stack
    _kernel_stack_top: