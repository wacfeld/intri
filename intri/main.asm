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
  

.exit:
  mov rax, 1
  mov rbx, 0
  int 80h

