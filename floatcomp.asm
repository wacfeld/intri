section .data
x dt 3.14
y dt 3.14
msg1 db "less", 10
len1 equ $ - msg1
msg2 db "greater", 10
len2 equ $ - msg2
msg3 db "equal", 10
len3 equ $ - msg3

section .text
global _start

;------------------------------------------------------------------------------
; PROCEDURE:    norm
; IN:           eax, ebx, ecx: x, y, z
; OUT:          
; MODIFIES:     
; CALLS:        
; DETAILS:      
; norm:


_start:
  finit ; reset fpregs
  
  fld tword [y]  ; y
  fld tword [x] ; x y
  fcomi st1      ; comp x with y
  jb .less       ; x < y
  ja .great      ; x > y
  je .eq         ; x == y

.less:
  mov eax, 4
  mov ebx, 1
  mov ecx, msg1
  mov edx, len1
  int 80h
  jmp .exit

.eq:
  mov eax, 4
  mov ebx, 1
  mov ecx, msg3
  mov edx, len3
  int 80h
  jmp .exit

.great:
  mov eax, 4
  mov ebx, 1
  mov ecx, msg2
  mov edx, len2
  int 80h
  jmp .exit

.exit:
  mov rax, 1
  mov rbx, 0
  int 80h

