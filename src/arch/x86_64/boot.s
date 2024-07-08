; boot.asm
; Date: 2024-07-07
; Author: Darkiiiiiice

global _start

    
MB_MAGIC equ 0xE85250D6
MB_ARCHITECTURE equ 0x0

MB_HEADER_TAG_INFORMATION_REQUEST equ 0x1
MB_HEADER_TAG_ADDRESS equ 0x2
MB_HEADER_TAG_ENTRY_ADDRESS equ 0x3
MB_HEADER_TAG_FRAMEBUFFER equ 0x5
MB_HEADER_TAG_END equ 0x0

    
[section .multiboot2_header]
    align 8
    
header_start:
    dd MB_MAGIC
    dd MB_ARCHITECTURE
    dd header_end - header_start
    dd -(MB_MAGIC + MB_ARCHITECTURE +(header_end - header_start))
header_end:

entry_address_start:
    align 8
    dw MB_HEADER_TAG_ENTRY_ADDRESS
    dw 0x0
    dd entry_address_end - entry_address_start
    dd _start
entry_address_end:
    
frame_buffer_start:
    align 8
    dw MB_HEADER_TAG_FRAMEBUFFER
    dw 0x0
    dd frame_buffer_end - frame_buffer_start
    dd 0x400
    dd 0x300
    dd 0x20
frame_buffer_end:
    
tags_end:
    align 8
    dw MB_HEADER_TAG_END
    dw 0x0
    dw 0x0
    dd 0x8

BITS 32

extern _kernel_init
extern _kernel_main

[section .bss]
stack_bottom:
    resb 64
stack_top:

[section .text]

    _start:
        mov esp, stack_top

        mov eax, 0x80000001
        cpuid

        test edx, (1<<29) 
        jz error
    
    
        call _kernel_init
        call _kernel_main


        call check_multiboot
    

    check_multiboot:
        cmp eax,0x36D76289
        jne .no_multiboot
        ret
    .no_multiboot:
        mov al, '0'
        jmp error
    error:
        mov dword [0xB8000], 0x4F524F45
        mov dword [0xB8004], 0x4F324F52
        mov dword [0xB8008], 0x4F204F20
        mov byte [0xB800a], al

        hlt
    
    print_message:
        mov ebx, 0
        mov esi, message
        mov ecx, message_len
        mov edx, 0
        call print_string
        ret
    
    print_string:
        mov eax, 0x36d76289
        mov edi, 1
        int 0x80
        ret

[section .data]
align 4

message db "Hello, Multiboot2!", 0x0
message_len equ $-message