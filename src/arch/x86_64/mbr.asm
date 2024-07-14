; boot.asm
; Date: 2024-07-07
; Author: Darkiiiiiice

    org 0x7c00
    ; BIOS Entry    0xFFFF0 ~ 0xFFFFF 16B
    ; BIOS system   0xF0000 ~ 0xFFFEF 640KB
    ; I/O Mapping   0xC8000 ~ 0xEFFFF 160KB
    ; BIOS Monitor  0xC0000 ~ 0xC7FFF 32KB
    ; TextMode      0xB8000 ~ 0xBFFFF 32KB
    ; Black White   0xB0000 ~ 0xB7FFF 32kB
    ; Color Mode    0xA0000 ~ 0xAFFFF 64KB
    ; EBDA          0x9FC00 ~ 0x9FFFF 1KB
    ; loader space  0x07E00 ~ 0x9FBFF 608KB
    ; MBR           0x07C00 ~ 0x07Dff 512B
    ; stack space   0x00500 ~ 0x07BFF 30KB
    ; BIOS Data     0x00400 ~ 0x004FF 256B
    ; IVT           0x00000 ~ 0x003FF 1KB
    stack_bottom equ 0x7c00
    stack_top equ 0x500
    
    VIDEO_INTERRUPT equ 0x10

    READ_CURSOR_POS_INT equ 0x03
    CLEAR_SCREEN_INT equ 0x06
    WRITE_STRING_INT equ 0x13
section _mbr_start:
    mov ax, cs
    mov ds, ax
    mov fs, ax
    mov ss, ax
    mov ax, stack_bottom
    mov sp, ax
    mov ax, 0xB800
    mov es, ax
    
    mov bx, 0x00
    push bx
    mov bp, sp
    mov ax, [bp]

    
    ; Clear Screen INT 0x10
    ; AH 0x06 AL (Row, 0 is all)
    ; BH Row properties
    ; CH, CL left-top (X, Y)
    ; DH, DL right-bottom (X, Y)
    mov ax, CLEAR_SCREEN_INT << 8
    mov bx, 0x0700
    mov cx, 0x0000
    mov dx, 0x184f

    int VIDEO_INTERRUPT
    
    
    mov ah, 0x07
    mov bx, message
    mov cx, [message_len]
    
    call _print
    
    
    jmp $
    ; AH backgroud color and frontground color
    ; BX string address
    ; CX count
_print:
    mov byte al, [bx]
    mov di, [bp]
    mov [es:di], ax
    inc bx
    add di, 2
    mov [bp], di
    
    loop _print
    
    mov word [es:di], 0x8F5F ; black: wihite : blink '_'
    
    ret

    
    message db "Real Mode ...", 0x0
    message_len db ($ - message)
    times 510 - ($ - $$) db 0
    dw 0xaa55