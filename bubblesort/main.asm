section .data
arr:  db 7, 5, 6, 7, 3, 2, 9, 5
arrlen: equ $ - arr

space:  db 32

section .text
global _start

_start:
  ;; bubble sort
  mov rcx, 0               ; rcx will loop from 0 to arrlen-1
  
loop1:  
  mov rbx, 0                    ;rbx will loop from 0 to arrlen-2 and be bubbly
loop2:  
  mov al, byte [arr+rbx]       ;arr[i]
  mov dl, byte [arr+rbx+1]     ;arr[i+1]
  cmp rax, rdx                  ;compare the two
  jl noswap                     ;if lesser, don't swap
  
  ;; swap
  mov byte [arr+rbx+1], al
  mov byte [arr+rbx], dl

noswap: 
 
  inc rbx
  cmp rbx, arrlen-1               ;if less than arrlen-1...
  jl loop2                      ;... loop
  
  inc rcx
  cmp rcx, arrlen               ;if less than arrlen
  jl loop1

  
  ;; print everything backwards
  mov r8, arrlen
top: 
  mov rax, 4
  mov rbx, 1
  mov rcx, arr
  add rcx, r8
  sub rcx, 1
  add byte [rcx], 48
  mov rdx, 1
  int 80h
  sub byte [rcx], 48

  mov rcx, space
  mov rax, 4
  mov rbx, 1
  mov rdx, 1
  int 80h

  dec r8
  jnz top

  mov rax, 1
  mov rbx, 0
  int 80h

