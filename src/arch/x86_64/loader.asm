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
                dd 0x00C0_920B
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
    
    mov byte [gs:100], 'A'
    
    
    
    
    ; clean table 
    mov edi, 0x1000
    xor eax, eax
    mov ecx, 1024 * 4
    rep stosd


    ; set temp PML4
    xor edi, edi
    lea eax, [edi + 0x1000]
    or eax, 0x3
    mov [edi], eax
    
    ; set PDPTE
    lea eax, [edi + 0x2000]
    or eax, 0x3
    mov [edi + 0x1000], eax
    
    ; set PDE
    lea eax, [edi + 0x3000]
    or eax, 0x3
    mov [edi + 0x2000], eax
    
    ;set PTE
    lea eax, [edi + 0x4000]
    or eax, 0x3
    mov [edi + 0x3000], eax

    
    push edi
    lea edi, [edi + 0x4000]
    mov eax, 0x3
    mov ecx, 512
    .loop_set_2m_table:
        mov [edi], eax
        add eax, 0x1000
        add edi, 0x08
        loop .loop_set_2m_table
    
    pop edi
    
    lidt [IDT]
    
    ; set PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; load PML4
    lea edi, [edi + 0x1000]
    mov cr3, edi
    
    ; set LME
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr
    
    ; set page table
    mov eax, cr0
    or eax, 1
    or eax, 1 << 31
    mov cr0, eax 
    
    lgdt [GDT_PTR64]
    
    jmp SELECTOR_CODE64:_entry_64

    ; set temp gdt 64 
    GDT_BASE64 dq 0x0
    GDT_CODE64_DESC dq 0x0020_9800_0000_FFFF
    GDT_DATA64_DESC dq 0x0000_9200_0000_FFFF
    
    GDT_SIZE64 equ $ - GDT_BASE64
    GDT_LIMIT64 equ GDT_SIZE64 - 1
    
    SELECTOR_CODE64 equ 0x08
    SELECTOR_DATA64 equ 0x10
    SELECTOR_VIDEO64 equ 0x18

    GDT_PTR64 dw GDT_LIMIT64
            dd GDT_BASE64
    
    IDT dd 0x0
        dd 0x0

    
[bits 64]
    align 8
    
_entry_64:
    mov rax, SELECTOR_DATA64
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax

    mov esp, LOADER_BASE_ADDR
    
    ; read kernel
    mov eax, 0x06
    mov edi, 0x6000
    mov ecx, 200
    
    call _read_kernel
    
    jmp $
    

    ; Read number of sector from ATA disk
    ; RAX start sector LBA_HIGH | LBA_MID | LBA_LOW   32~0  
    ; RDI load address
    ; RCX number of sector
_read_kernel:
    
    mov r8, rax
    mov r9, rcx
    mov r10, rdx


    ; 0x1F2 set sector
    mov dx, ATA_SECTOR_PRIMARY
    mov rax, rcx 
    out dx, al
    
    
    mov rax, r8
    ; 0x1F3 set LBA low address
    mov dx, ATA_LBA_LOW_PRIMARY
    out dx, al
    
    ; 0x1F4 set LBA middle address
    mov dx, ATA_LBA_MID_PRIMARY
    shr rax, 0x8
    out dx, al
    
    ; 0x1F5 set LBA high address
    mov dx, ATA_LBA_HIGH_PRIMARY
    shr rax, 0x8
    out dx, al
    
    ; 0x1F6 set LBA high 4bit address
    mov dx, ATA_DEVICE_PRIMARY
    shr rax, 0x8
    or al, 0xE0
    out dx, al
    
    ; 0x1F7 set command read
    mov dx, ATA_COMMAND_PRIMARY
    mov al, ATA_COMMAND_READ
    out dx, al
    
    .kernel_not_ready:
        nop
        in al, dx
        test al, 0x08
        jz .kernel_not_ready
    
    mov rax, rcx
    mov rdx, 512 / 4
    mul rdx
    mov rcx, rax


    mov dx, ATA_DATA_PRIMARY
    rep insd

    ret
    
