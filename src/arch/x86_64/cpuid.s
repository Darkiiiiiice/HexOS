[bits 64]

[section .text]
    global cpu_id
cpu_id:
    push rbp
    mov rbp, rsp
    mov rax, 0x80000008 
    cpuid
    
    mov rsp, rbp
    pop rbp
    ret
