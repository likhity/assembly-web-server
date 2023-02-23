.intel_syntax noprefix
.globl _start

.section .text

_start:
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    mov rax, 41     # socket
    syscall
    push rax

    mov rdi, rax 
    sub rsp, 16
    mov word ptr [rsp], 2
    mov word ptr [rsp+2], 0x5000
    mov dword ptr [rsp+4], 0
    mov qword ptr [rsp+8], 8
    mov rsi, rsp
    mov rdx, 16
    mov rax, 49     # bind
    syscall
    add rsp, 16
    
    mov rdi, qword ptr [rsp]
    mov rsi, 0
    mov rax, 50     # listen
    syscall

parent:
    mov rdi, qword ptr [rsp]
    mov rdx, 0
    mov rax, 43     # accept
    syscall
    mov rbx, rax

    mov rax, 57     # fork
    syscall

    cmp rax, 0
    je child

    mov rdi, rbx
    mov rax, 3      # close
    syscall
    
    jmp parent

child:
    push rax        # push the new client fd onto stack
    mov rdi, qword ptr [rsp+8]  # load the previously stored socket fd
    mov rax, 3      # close
    syscall

    mov rdi, 4
    sub rsp, 1024
    mov rsi, rsp
    mov rdx, 1024
    mov rax, 0      # read
    syscall

    cmp byte ptr [rsp], 71
    je get_request

post_request:
    mov rcx, [rsp + 5]
    mov rbx, [rsp + 13]
    push 0
    sub rsp, 16
    mov qword ptr [rsp], rcx
    mov qword ptr [rsp + 8], rbx
    mov rdi, rsp
    mov rsi, 0b1000001
    mov rdx, 511
    mov rax, 2      # open
    syscall

    mov rdi, rax
    add rsp, 24
    mov rsi, rsp
    add rsi, 176
    cmp byte ptr [rsi], 10
    jne skip
    add rsi, 1
    skip:
    mov rdx, 1

    loop:
    cmp byte ptr [rsi + rdx], 0
    je exit_loop
    add rdx, 1
    jmp loop
    exit_loop:

    mov rax, 1      # write
    syscall

    mov rax, 3      # close
    syscall
    
    mov rdi, 4
    lea rsi, [header]
    mov rdx, 19
    mov rax, 1      # write
    syscall
    add rsp, 1032
    jmp exit

get_request:
    mov rcx, [rsp + 4]
    mov rbx, [rsp + 12]
    push 0
    sub rsp, 16
    mov qword ptr [rsp], rcx
    mov qword ptr [rsp + 8], rbx
    mov rdi, rsp
    mov rsi, 0
    mov rax, 2      # open
    syscall

    mov rdi, rax
    push 0
    sub rsp, 1024
    mov rsi, rsp
    mov rdx, 1024
    mov rax, 0      # read
    syscall

    mov rbx, rax
    mov rax, 3      # close
    syscall

    mov rdi, 4
    lea rsi, [header]
    mov rdx, 19
    mov rax, 1      # write
    syscall

    mov rsi, rsp
    mov rdx, rbx     # write
    mov rax, 1
    syscall

    mov rax, 3      # close
    syscall

    mov rdi, 3
    mov rsi, 0
    mov rdx, 0
    mov rax, 43     # accept
    syscall
    add rsp, 2080

exit:
    mov rdi, 0
    mov rax, 60     # SYS_exit
    syscall

.section .data
header:
.string "HTTP/1.0 200 OK\r\n\r\n"
