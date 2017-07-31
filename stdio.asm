;stdio lib will include the following functions
;exit : xors rdi movs 60 to rax andn exits
global exit, strlen, print_string, print_char, print_uint, print_int, get_word, flush_stdin, parse_uint, parse_int, string_equals, string_copy
section .text

;providereturn value in rdi
exit:
  mov rax , 60
  syscall

;rdi will hold the string's base address
;rsi will be our accumulator
;we will return the result in the rax register
strlen:
  mov rsi, 0
  .loop:
    cmp byte [rdi + rsi], 0
    je .end
    inc rsi
    jmp .loop
  .end:
    mov rax,rsi;  here we return the accumulator
    ret

;rdi provides the string base pointer
print_string:
  call strlen; will return rhe length in rax
  mov  rdx, rax; moving the string length to rdx
  mov  rsi, rdi; the string
  mov  rdi, 1; stdout
  mov rax, 1; write syscall
  syscall
  ret

;char supplied in rdx(dl)
print_char:
  push rbp
  mov rbp, rsp
  sub rsp, 1
  mov [rbp - 1], dl
  lea rsi, [rbp - 1]
  mov rax, 1
  mov rdi, 1
  mov rdx, 1
  syscall
  add rsp, 1
  pop rbp
  ret

print_newline:
  mov rdx, 10
  jmp print_char
 

print_uint:;number supplied by rdi
    push rbp
    mov rbp, rsp;

    jmp int_to_string

;number supplied in rdi
print_int:
    push rbp
    mov rbp, rsp
    cmp rdi, 0
    jge .print_uint

    neg rdi
    push rdi

    mov dl, '-'
    call print_char

    pop rdi

  .print_uint:
    jmp int_to_string

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int_to_string:
    sub rsp, 21; clearing space
    mov rsi, 1; offset
    mov rcx, 10; first divisor
    mov r9, 1; second divisor

    mov byte[rbp - 1], 0;terminating the string
    cmp rdi, 0
    jne .loop

    mov byte [rbp - 2], '0'
    lea r8, [rbp - 2]
    jmp .print

 .loop:
    mov rax, rdi
    inc rsi
    mov rdx, 0; holds the remainder
    div rcx;divide by the first divisor

    sub rdi, rdx;subtract the remainder from the number

    mov rax, rdx;move the remainder to rax
    mov rdx, 0
    div r9;divide by the second divider

    add al, 48;add 48 to make it an ascii

    mov r8, rbp
    sub r8, rsi
    mov [r8], al;move into the cleared space

    cmp rdi, 0
    je .print

    mov rax, 10
    mul rcx;multiply the first divisor by 10
    mov rcx, rax

    mov rax, 10
    mul r9
    mov r9, rax

    jmp .loop

  .print:
    mov rdi, r8
    call print_string
  .exit:
    add rsp, 21
    pop rbp
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_stdin:
    sub rsp, 1
  .loop:
    mov rax, 0
    mov rdi, 0
    mov rdx, 1
    mov rsi, rsp
    syscall
   
    cmp byte [rsi], 10
    jne .loop

    inc rsp
    ret


get_char:
    push rbp
    mov rbp, rsp

    sub rsp, 2
    ;get a chr from stdin
    mov rax, 0
    mov rdi, 0
    lea rsi, [rbp - 2]
    mov rdx, 2
    syscall

  .check_new_line:
    mov al, byte[rbp - 1]
    cmp al, 10
    je .exit

    mov rax, 0
    mov rdi, 0
    lea rsi, [rbp-1]
    mov rdx, 1
    syscall
    jmp .check_new_line

  .exit:
    mov rax, 0
    mov al, byte[rbp - 2]
    add rsp, 2
    pop rbp
    ret


get_word:
    push rbp
    mov rbp, rsp
    mov rsi, [rbp + 3 * 8];the base address
    mov rbx, 0 ;offset
  
  .loop:
    cmp rbx, [rbp + 2 * 8];the size 
    je .ret_zero
    
    ;read a char
    mov rax, 0 ;read
    mov rdi, 0 ;stdin
     ;buffer + offset
    mov rdx, 1 ;how amny bytes
    syscall

    mov al, [rsi]; move the char to the reigster
    cmp al, 20;space
    je .null_terminate
    cmp al, 9;tab
    je .null_terminate
    cmp al, 10  ; newline
    je .null_terminate

    inc rsi;
    inc rbx;increment the index
    jmp .loop
  
  .ret_zero:
    mov rax, 0
    jmp .exit


  .null_terminate:
    mov byte[rsi], 0
    mov rax, [rbp + 3 * 8];in this case we return the buffer address
    
  .exit:
    pop rbp
    ret

parse_uint:
   
   push rbp
   mov rbp, rsp

   mov rdi, 5 ;the index
   mov rbx, 0 ;the number
   mov rcx, 0 ;digits count
   mov rsi, 1 ;multiplier

  .loop:
   cmp rdi, 0
   je .exit
   dec rdi ;decrement the index

   ;make sure that the letter is between 0-9
   add rdi, 16
   mov rax, 0
   mov al, byte[rbp + rdi]
   
   cmp al, 48 
   jl .exit

   cmp al, 57
   jg .exit

   ;multiply the currnet digit by the miltiplier
   sub rax, 48
   mul rsi
   add rbx, rax

   ;multiply the multiplier by 10
   mov rax, 10
   mul rsi
   mov rsi, rax

   sub rdi, 16
   inc rcx
   jmp .loop

  .exit:
   mov rdx, rcx
   mov rax, rbx
   pop rbp
   ret

parse_int:
   
   push rbp
   mov rbp, rsp

   mov rdi, 5 ;the index
   mov r8, 0 ;the number
   mov rcx, 0 ;digits count
   mov rsi, 1 ;multiplier

  .loop:
   cmp rdi, 0
   je .exit
   dec rdi ;decrement the index

   ;make sure that the letter is between 0-9
   add rdi, 16
   mov rax, 0
   mov al, byte[rbp + rdi]
   cmp al, 48 
   jl .checkout

   cmp al, 57
   jg .exit

   ;multiply the currnet digit by the miltiplier
   sub rax, 48
   mul rsi
   add r8, rax

   ;multiply the multiplier by 10
   mov rax, 10
   mul rsi
   mov rsi, rax

   sub rdi, 16
   inc rcx
   jmp .loop

   .checkout:
     cmp byte[rbp + 16], '-'
     jne .exit
     neg r8

  .exit:
   mov rdx, rcx
   mov rax, r8
   pop rbp
   ret

;string will be provided in rdi and rsi respectively
string_equals:
    push rbp
    mov rbp, rsp
    mov rcx, 0
    mov rdx, 1
   .loop:
    mov bl, byte[rdi + rcx]
    
    cmp bl, byte[rsi + rcx]
    jne .not_equal
    
    cmp bl, 0
    je .exit
    
    inc rcx
    jmp .loop
    
   .not_equal:
    mov rdx, 0
    
   .exit:
    mov rax, rdx
    pop rbp
    ret

;rdi: source string
;rsi: destination buffer
;rdx: buffer size
string_copy:
   push rbp
   mov rbp, rsp

   push rsi
   call strlen
   pop rsi
   cmp rdx, rax
   jl .ret_zero
   
   mov rax, rdi

   mov byte[rsi + rdx], 0

  .loop:
   dec rdx
   mov cl, byte[rdi + rdx]
   mov byte[rsi + rdx], cl
   
   cmp rdx, 0
   je .exit

   jmp .loop

  .ret_zero:
    mov rax, 0

  .exit:
   pop rbp
   ret











 












