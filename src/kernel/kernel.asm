%include "src/include/kernel.inc"

[bits 64]
    align 8
    
[segment .text]
_start:
    ; set new gdt
    mov rdi, 0x6000
    mov word [rdi], 0x17
    mov rax, 0x6010
    mov [rdi + 0x2], rax
    mov rax, 0x00
    mov [rdi + 0x10],  rax
    mov rax, KERNEL_GDT_CODE64
    mov [rdi + 0x18], rax
    mov rax, KERNEL_GDT_DATA64
    mov [rdi + 0x20], rax
    
    lgdt [rdi]

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