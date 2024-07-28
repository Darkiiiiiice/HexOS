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
    mov ecx, 0x200
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
    
    KERNEL_SETUP_ADDR equ 0x10000
    KERNEL_SIZE equ 0x780
    KERNEL_BASE_ADDR equ 0xFFFF8000_00100000
    
    
_entry_64:
    mov rax, SELECTOR_DATA64
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax

    mov esp, LOADER_BASE_ADDR
    
    ; read kernel
    mov rax, 0x06
    mov rdi, KERNEL_SETUP_ADDR
    mov rcx, KERNEL_SIZE
    
    call _read_kernel
    
    call _kernel_init
    
    jmp KERNEL_BASE_ADDR
    
    hlt

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
    

_kernel_init:
    
    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    
    ; mapping 0xFFFF8000_00000000 to phy 0x00000000_00000000
    mov rdi, 0x1000
    lea rax, [rdi + 0x1000]
    or eax, 0x3
    mov [rdi + 0x100 * 8], rax
    
    
    mov rdi, KERNEL_SETUP_ADDR
    mov rdx, [rdi]
    
    ; check ELF Magic 0x7F
    cmp dl, 0x7F
    jne _not_elf
    
    call _is_elf

    ; print 'E'
    shr rdx, 8
    mov al, dl
    mov bx, 11 * 80 * 2 + 2 * 0
    call _print_char

    ; print 'L'
    shr rdx, 8
    mov al, dl
    mov bx, 11 * 80 * 2 + 2 * 1
    call _print_char

    ; print 'F'
    shr rdx, 8
    mov al, dl
    mov bx, 11 * 80 * 2 + 2 * 2
    call _print_char
    
    ; check elf64 or elf32
    shr rdx, 8
    cmp dl, 0x2
    jnz _is_32bit
    
    call _is_64bit
    
    ; e_ident = 16
    ; e_type = 2
    ; e_machine = 2
    ; e_version = 4
    ; e_entry = 8
    ; e_phoff = 8
    ; e_shoff = 8
    ; e_flags = 4
    ; e_ehsize = 2
    ; e_phentsize = 2
    ; e_phnum = 2
    ; e_shentsize = 2
    ; e_shnum = 2
    ; e_shstrndx = 2

    ; dx = e_phentsize
    xor rdx, rdx
    mov dx, [rdi + 16 + 2 + 2 + 4 + 8 + 8 + 8 + 4 + 2]
    ; rbx = e_phoff + KERNEL_SETUP_ADDR
    xor rbx, rbx
    mov rbx, [rdi + 16 + 2 + 2 + 4 + 8]
    add rbx, KERNEL_SETUP_ADDR
    ; cx = e_phnum
    xor rcx, rcx
    mov cx, [rdi + 16 + 2 + 2 + 4 + 8 + 8 + 8 + 4 + 2 + 2]
    
    .iter_segemnt:
        cmp byte [rbx + 0], 0x0
        je  .PTNULL
    
        ; dst
        push rcx
        ; p_filesz
        mov ecx, [rbx + 32]
        ; src p_offset
        mov rax, [rbx + 8]
        add rax, KERNEL_SETUP_ADDR
        mov rsi, rax
        ; dst p_vaddr
        mov rax, [rbx + 16]
        mov rdi, rax
    
        
        call _mem_cpy
        pop rcx

        .PTNULL:
            add rbx, rdx
        loop .iter_segemnt
    
    ret

_is_32bit:
    mov al, '3'
    mov bx, 12 * 80 * 2 + 2 * 0
    call _print_char
    mov al, '2'
    mov bx, 12 * 80 * 2 + 2 * 1
    call _print_char
    
    hlt
    
_is_64bit:
    mov al, '6'
    mov bx, 12 * 80 * 2 + 2 * 0
    call _print_char
    mov al, '4'
    mov bx, 12 * 80 * 2 + 2 * 1
    call _print_char

_is_elf:
    push rdi
    
    mov ah, 0x07
    mov al, 'E'
    mov rdi, 0xB8000
    mov [rdi + 10 * 80 * 2  ], ax
    
    pop rdi
    ret
    

_not_elf:
    mov ah, 0x07
    mov al, 'N'
    mov rdi, 0xB8000
    mov [rdi + 10 * 80 * 8 ], ax
    
    hlt

    
_print_char:
    push rdi
    
    mov rdi, 0xB8000
    mov ah, 0x07
    
    mov [rdi + rbx], ax

    pop rdi
    ret
    

_setup_kernel:

    ret

    not_elf db "Not ELF Kernel ..."
    not_elf_len equ $ - not_elf
    is_elf db "ELF Kernel ..."
    is_elf_len equ $ - is_elf
    
_mem_cpy:
    push rbp
    mov rbp, rsp

    cld
    rep movsb
    
    mov rsp, rbp
    pop rbp
    ret
    