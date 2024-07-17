%include "src/arch/x86_64/boot.inc"
[bits 16]
    org LOADER_BASE_ADDR
    jmp _loader_start
    ; Global Descriptor Table
    GDT_BASE32  dd 0x0
                dd 0x0
    GDT_CODE32_DESC  dd 0x0000_FFFF
                    dd 0x00CF_9800
    GDT_DATA32_DESC  dd 0x0000FFFF
                    dd 0x00CF_9200
    VIDEO_DESC dd 0x8000_0007
                dd 0x00C0_9200
    GDT_SIZE32 equ $ - GDT_BASE32
    GDT_LIMIT32 equ GDT_SIZE32 - 1
    
    times 8 dq 0x0 ;64 * 8 Byte space
    
    SELECTOR_CODE equ 0x0008
    SELECTOR_DATA equ 0x0010
    SELECTOR_VIDEO equ 0x0018
    
    gdt_ptr dw GDT_LIMIT32
            dd GDT_BASE32
    
    loader_msg db 'Loading in real...'
    
_loader_start:
    mov sp, LOADER_BASE_ADDR
    mov bp, loader_msg
    mov cx, 17
    mov ax, 0x1301
    mov bx, 0x001f
    mov dx, 0x1800
    int 0x10
    

    ; open A20
    in al, 0x92
    or al, 0x2
    out 0x92, al
    
    ; load gdt_ptr
    lgdt [gdt_ptr]
    
    ; set PE 
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax
    
    jmp dword SELECTOR_CODE:_entry_32
    
[bits 32]

_entry_32:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, LOADER_BASE_ADDR
    mov ax, SELECTOR_VIDEO
    mov gs, ax
    
    mov byte [gs:160], 'P'
    
    jmp $

    
    
