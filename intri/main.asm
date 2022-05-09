section .data
sqrt2 dt 1.414
x dt 4.1
y dt 2.0
z dt 0.0

a dt -2.0
b dt 4.0
c dt 0.0

msg1 db "less", 10
len1 equ $ - msg1
msg2 db "eq", 10
len2 equ $ - msg2
msg3 db "great", 10
len3 equ $ - msg3

section .text
global _start

;------------------------------------------------------------------------------
; PROCEDURE:    norm
; IN:           st0, st1, st2: x, y, z
; OUT:          st0: |(x,y,z)|
; MODIFIES:     st0-3
; CALLS:        none
; DETAILS:      sqrt(x*x + y*y + z*z)
norm:
  fst   st3 ; x y z x
  fmulp st3 ; y z x*x
  fst   st3 ; y z x*x y
  fmulp st3 ; z x*x y*y
  fst   st3 ; z x*x y*y z
  fmulp st3 ; x*x y*y z*z
  faddp st1 ; x*x+y*y z*z
  faddp st1 ; x*x+y*y+z*z
  fsqrt     ; sqrt(...)

  ret       ; leave

;------------------------------------------------------------------------------
; PROCEDURE:    dotp
; IN:           st0-2: v, st3-5: w
; OUT:          st0: v . w
; MODIFIES:     st0-5
; CALLS:        none
; DETAILS:      dot product
dotp:
  ; x y z a b c
  fmulp st3 ; y z x*a b c
  fmulp st3 ; z x*a y*b c
  fmulp st3 ; x*a y*b z*c
  faddp st1 ; x*a+y*b z*c
  faddp st1 ; x*a+y*b+z*c

  ret

;------------------------------------------------------------------------------
; PROCEDURE:    cross
; IN:           st0-2: v, st3-5: w
; OUT:          st0-2: v x w
; MODIFIES:     
; CALLS:        
; DETAILS:      cross product
cross:
  ; x y z a b c

  ; calculate x*b
  fst st6 ; x y z a b c x
  fmul  st4 ; x*b y z a b c x
  fstp  st7 ; y z a b c x x*b

  ; calculate y*a
  fst   st7 ; y z a b c x x*b y
  fmul  st2 ; y*a z a b c x x*b y

  ; calculate u3 = x*b-y*a
  fsubp st6 ; z a b c x x*b-y*a y

  ; calculate z*a then discard a
  fmul to st1 ; z z*a b c x u3 y

  ; calculate x*c then discard x
  

_start:
  finit ; reset fpuregs
  fld tword [x]
  fld tword [y]
  fld tword [z]
  fld tword [a]
  fld tword [b]
  fld tword [c] ; c b a z y x
  call dotp     ; dotp

  fldz          ; 0 dotp
  
  fcomi st1     ; 0 ? dotp
  jb .less
  je .eq
  ja .great
  
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
  mov ecx, msg2
  mov edx, len2
  int 80h
  jmp .exit

.great:
  mov eax, 4
  mov ebx, 1
  mov ecx, msg3
  mov edx, len3
  int 80h
  jmp .exit


.exit:
  mov rax, 1
  mov rbx, 0
  int 80h

