; boot.asm
; Date: 2024-07-07
; Author: Darkiiiiiice

global _start

HEX_4k equ 0x1000
    
MB_MAGIC equ 0xE85250D6
MB_BOOTLOADER_MAGIC equ 0x36d76289

MB_ARCHITECTURE equ 0x0

MB_HEADER_TAG_INFORMATION_REQUEST equ 0x1
MB_HEADER_TAG_ADDRESS equ 0x2
MB_HEADER_TAG_ENTRY_ADDRESS equ 0x3
MB_HEADER_TAG_FRAMEBUFFER equ 0x5
MB_HEADER_TAG_END equ 0x0
    
TEMPLATE_PAGE_TABLE equ 0x00000
    
PML4_PRE_PHY_ADDR equ TEMPLATE_PAGE_TABLE; 0x1000
PDPT_PRE_PHY_ADDR equ PML4_PRE_PHY_ADDR + HEX_4k ; 0x2000
PD_PRE_PHY_ADDR equ PDPT_PRE_PHY_ADDR + HEX_4k ; 0x3000
PT_PRE_PHY_ADDR equ PD_PRE_PHY_ADDR + HEX_4k ; 0x4000

    
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



extern _long_entry
[section .data]
    align 8

    magic dd 0
    mbi dd 0
    


[section .text]
BITS 32

    align 4
    _start:

    LABEL_GDT64       dq 0x00000000_00000000
    LABEL_DESC_CODE64 dq 0x00209A00_00000000
    LABEL_DESC_DATA64 dq 0x00009200_00000000

    GdtLen64 equ $-LABEL_GDT64  
    
    GdtPtr64 dw GdtLen64 -1
            dd LABEL_GDT64 
    IDT:
        .LENGTH dw 0
        .BASE dd 0
    
    SelectorCode64 equ LABEL_DESC_CODE64 - LABEL_GDT64
    SelectorData64 equ LABEL_DESC_DATA64 - LABEL_GDT64

        mov esp, stack_top
    
        cmp eax, MB_BOOTLOADER_MAGIC
    
        mov ebp, ebx
        mov ecx, [ebp]
    
        ; save 
        mov [magic], eax,
        mov [mbi], ebx,

        call check_long_mode
    
        push di
        mov ecx, 0x1000
        xor eax, eax
        cld 
        rep stosd
        pop di
    
        lea eax, [es:di + 0x1000]
        or eax, 7
        mov [es:di], eax

        lea eax, [es:di + 0x2000]
        or eax, 7
        mov [es:di + 0x1000], eax
        
        lea eax, [es:di + 0x3000]
        or eax, 7
        mov [es:di + 0x2000], eax
    
        push di
        lea di, [di + 0x3000]
        mov eax, 7

        .loop_page_table:
        mov [es:di], eax
        add eax, 0x1000
        add di, 8
        cmp eax, 0x200000
        jb .loop_page_table        
    
        pop di
    
        ; disable IRQs
        mov al, 0xFF
        out 0xA1, al
        out 0x21, al
    
        nop
        nop
        
        lidt [IDT]
        
        ; set cr4 PAE enable
        mov eax, cr4
        bts eax, 5
        bts eax, 7
        mov cr4, eax
    
        ; set template table addr to cr3
        mov eax, edi
        mov cr3, eax
        
        ; enable long mode
        mov ecx, 0x0C0000080 ; IA32_EFER
        rdmsr 
        bts eax, 8 ; enable LME
        wrmsr 
    
        ; open PE and PG
        mov eax, cr0
        bts eax, 0
        bts eax, 0x1F
        mov cr0, eax
    
        mov eax, [magic]
        mov ebx, [mbi]

        lgdt [GdtPtr64]
        jmp SelectorCode64:_long_entry

    check_long_mode:
        mov eax, 0x80000000
        cpuid
        cmp eax, 0x80000001
        setnb al
        jb .no_long_mode
        mov eax, 0x80000001
        cpuid
        test edx, 1 << 29
        jz .no_long_mode
        ret
    
    .no_long_mode:
        hlt
    
[section .bss]
stack_bottom:
    resb 64
stack_top: