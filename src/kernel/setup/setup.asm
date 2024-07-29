%include "src/include/kernel.inc"

[bits 64]
    
    
    global _setup_gdt
    global _setup_high_mem_mapping
[section .text]

_setup_gdt:
    ; set new gdt
    mov rdi, KERNEL_GDT_ADDR
    mov word [rdi], KERNEL_GDT_LIMIT64
    mov rax, KERNEL_GDT_ADDR + 0x10
    mov [rdi + 0x2], rax
    mov rax, 0x00
    mov [rdi + 0x10],  rax
    mov rax, KERNEL_GDT_CODE64
    mov [rdi + 0x18], rax
    mov rax, KERNEL_GDT_DATA64
    mov [rdi + 0x20], rax
    
    lgdt [rdi]
    
    ret
    
_setup_high_mem_mapping:
    ; mapping 0xFFFF8000_00000000 to phy 0x00000000_00000000
    mov rax, cr3
    mov rdi, rax
    lea rax, [rdi + 0x1000]
    or eax, 0x3
    mov [rdi + 0x100 * 8], rax
    
    ret