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
_mbr_start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov ss, ax
    mov ax, stack_bottom
    mov sp, ax
    
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
    
    ; Read Cursor position INT 0x10
    ; AH 0x03 
    ; BH Display page
    ; CH starting line of the blinking cursor
    ; CL ending line of the blinking curor
    ; DH screen line which cursor located
    ; DL screen column which cursor located
    mov ax, READ_CURSOR_POS_INT << 8
    mov bh, 0x00

    int VIDEO_INTERRUPT
    
    ; Write Character String INT 0x10
    ; AH 0x13
    ; AL Output mode
    ; BH Display page number
    ; BL Attribute byte of character
    ; BP Offset address of number
    ; CX Number of characters to be displayed
    ; DH Display line
    ; DL Display Column
    ; ES Segment address of buffer
    mov ax, message
    mov bp, ax
    mov cx, 0x0D
    mov ax, (WRITE_STRING_INT << 8) | 0x01
    mov bx, 0x0002

    int VIDEO_INTERRUPT
    
    
    message db "Hello, World!", 0x0
    times 510 - ($ - $$) db 0
    dw 0xaa55