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
    mov es, ax
    mov fs, ax
    mov ss, ax
    mov ax, stack_bottom
    mov sp, ax
    
    mov bx, 0x00
    push bx
    mov bp, sp

    
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
    
    call _print
    
    
    jmp $
    ; AH backgroud color and frontground color
    ; BX string address
    ; CX count
_print:
    push es
    mov dx, 0xB800
    mov es, dx
    
    _print_loop:
    mov byte al, [bx]
    
    cmp al, 0x0
    je _print_end

    ; cal position with row and col
    ; position = col + 80 * 2 * row
    push ax
    push bx
    xor ax, ax
    xor bx, bx
    mov word dx, [cursor]
    mov al, 0xA0
    mul dl
    
    push ax
    
    mov al, 0x02
    mul dh
    mov bx, ax

    pop ax

    add ax, bx
    mov di, ax
    pop bx
    pop ax
    
    ; if col == 80 then row + 1
    cmp dh, 0x50
    jge _print_cmp_col
    _print_cmp_end:

    add dh, 0x1
    
    mov [cursor], dx

    mov [es:di], ax
    inc bx
    
    jmp _print_loop
    

    _print_cmp_col:
    add dl, 0x1
    mov dh, 0x0    
    
    jmp _print_cmp_end
    
    _print_end:
    add di, 0x2
    mov word [es:di], 0x8F5F ; black: wihite : blink '_'
    
    pop es
    ret

    cursor dw 0x0
    message db "Real Mode ...12345678912345678912345678912345678912345678912345678912345678912345678", 0x0
    times 510 - ($ - $$) db 0
    dw 0xaa55