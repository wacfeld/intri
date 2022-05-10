section .data

num dt -6.0

x dt 4.0
y dt 2.0
z dt 1.0

a dt -2.0
b dt 4.0
c dt 1.0

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
  fld st3 ; c z z*a b c x u3 y
  fmulp st5 ; z z*a b c x*c u3 y

  ; calculate u2 = z*a-x*c
  fld st1 ; z*a z z*a b c x*c u3 y
  fsubrp st5 ; z z*a b c z*a-x*c u3 y
  
  ; calculate z*b and discard z, b
  fmul st2 ; z*b z*a b c u2 u3 y

  ; calculate y*c and discard y, c
  fld  st6 ; y z*b z*a b c u2 u3 y
  fmulp st4 ; z*b z*a b y*c u2 u3 y

  ; calcelate y*c-z*b
  fsubp st3 ; z*a b y*c-z*b u2 u3 y

  ; _ _ u1 u2 u3 _
  ; pop twice
  fstp st0
  fstp st0
  ; u1 u2 u3

  ret

_start:
  finit ; reset fpuregs
  fld tword [c]
  fld tword [b]
  fld tword [a]
  fld tword [z]
  fld tword [y]
  fld tword [x] ; x y z a b c
  call cross     ; dotp

  fstp st0
  fld tword [num]
  ; fldz          ; 0 dotp
  
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

