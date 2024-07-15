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
    
    LOADER_START_SECTOR equ 0x01
    LOADER_BASE_ADDR equ 0x8000
    
    ; I/O resgiter
    ATA_SECTOR_PRIMARY equ 0x1F2
    ATA_SECTOR_SECONDARY equ 0x172
    ATA_LBA_LOW_PRIMARY equ 0x1F3
    ATA_LBA_LOW_SECONDARY equ 0x173
    ATA_LBA_MID_PRIMARY equ 0x1F4
    ATA_LBA_MID_SECONDARY equ 0x174
    ATA_LBA_HIGH_PRIMARY equ 0x1F5
    ATA_LBA_HIGH_SECONDARY equ 0x175
    ATA_DEVICE_PRIMARY equ 0x1F6
    ATA_DEVICE_SECONDARY equ 0x176
    ATA_STATUS_PRIMARY equ 0x1F7
    ATA_STATUS_SECONDARY equ 0x177
    ATA_COMMAND_PRIMARY equ 0x1F7
    ATA_COMMAND_SECONDARY equ 0x177
    ATA_COMMAND_IDENTIFY equ 0xEC
    ATA_COMMAND_READ equ 0x20
    ATA_COMMAND_WRITE equ 0x30
    ATA_DATA_PRIMARY equ 0x1F0
    ATA_DATA_SECONDARY equ 0x170
section _mbr_start:
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
    
    
    ; print message
    mov ah, 0x07
    mov bx, message
    call _print
    
    ; print read_loader
    mov ah, 0x07
    mov bx, str_read_loader
    call _print
    
    mov ax, LOADER_START_SECTOR
    mov bx, LOADER_BASE_ADDR
    mov dx, 0x00
    mov cx, 0x01
    
    call _read_loader
    
    
    jmp LOADER_BASE_ADDR

    ; Read number of sector from ATA disk
    ; AX start sector  LBA_MID | LBA_LOW   15~8|7~0
    ; BX load address
    ; CX number of sector
    ; DX start sector Device:4 | LBA_HIGH  27~15|24~-16
_read_loader:
    push ds
    
    push cx
    push dx
    push ax


    ; 0x1F2 set sector
    mov dx, ATA_SECTOR_PRIMARY
    mov al, cl 
    out dx, al
    
    pop ax
    
    ; 0x1F3 set LBA low address
    mov dx, ATA_LBA_LOW_PRIMARY
    out dx, al
    
    ; 0x1F4 set LBA middle address
    mov dx, ATA_LBA_MID_PRIMARY
    shr ax, 0x8
    out dx, al
    
    ; 0x1F5 set LBA high address
    pop ax
    mov dx, ATA_LBA_HIGH_PRIMARY
    out dx, al
    
    ; 0x1F6 set LBA high 4bit address
    pop ax
    mov cx, ax
    mov dx, ATA_DEVICE_PRIMARY
    shr ax, 0x8
    or al, 0xE0
    out dx, al
    
    ; 0x1F7 set command read
    mov dx, ATA_COMMAND_PRIMARY
    mov al, ATA_COMMAND_READ
    out dx, al
    
    .not_ready:
        in al, dx
        and al, 0x88
        cmp al, 0x08
        jnz .not_ready
    
    mov ax, cx
    mov dx, 256
    mul dx
    mov cx, ax

    mov dx, ATA_DATA_PRIMARY
    .go_on_read:
        in ax, dx
        mov [bx], ax
        add bx, 0x02

        loop .go_on_read

    pop ds
    ret
    ; AH backgroud color and frontground color
    ; BX string address
_print:
    push es
    mov dx, 0xB800
    mov es, dx
    
    _print_loop:
    mov byte al, [bx]
    
    cmp al, 0x0
    je _print_end
    
    cmp al, 0xA
    je _print_lf

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
    jge _print_lf

    add dh, 0x1
    
    mov [cursor], dx

    mov [es:di], ax
    inc bx
    
    jmp _print_loop
    
    _print_lf:
        add dl, 0x1
        mov dh, 0x0
    
        mov [cursor], dx
    
        inc bx
    jmp _print_loop
    
    _print_end:
    pop es
    ret

    cursor dw 0x0
    message db "Real Mode ...",0xA, 0x0
    str_read_loader db "Reading loader ......",0xA, 0x0
    times 510 - ($ - $$) db 0
    dw 0xaa55