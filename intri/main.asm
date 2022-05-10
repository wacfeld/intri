;------------------------------------------------------------------------------
; NAME:         intri
; TYPE:         main
; DESCRIPTION:  determines whether a point is a triangle on a sphere
; BUILD:        nasm -f elf64 -g -F dwarf main.asm -l main.lst
;               ld -o main main.o
;------------------------------------------------------------------------------
section .data

num dt -6.0

x dt 5.0
y dt 3.0
z dt 2.0

a dt 4.0
b dt 2.0
c dt 1.0

origin dt 0.0, 0.0, 0.0

v1 dt 1.0, 0.0, 0.0
v2 dt 0.0, 1.0, 0.0
v3 dt 0.0, 0.0, 1.0

p dt 1.0, 1.0, 1.0

msg1 db "less", 10
len1 equ $ - msg1
msg2 db "eq", 10
len2 equ $ - msg2
msg3 db "great", 10
len3 equ $ - msg3

; section .bss

; ; 3 vectors defining a triangle
; p1 rest 3
; p2 rest 3
; p3 rest 3

section .text
global _start

;------------------------------------------------------------------------------
; PROCEDURE:    norm
; IN:           st0, st1, st2: x, y, z
; OUT:          st0: |(x,y,z)|
; MODIFIES:     st0-7
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
; MODIFIES:     st0-7
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
; PROCEDURE:    vsub
; IN:           st0-2: v, st3-5: w
; OUT:          st0-2: v-w
; MODIFIES:     st0-7
; CALLS:        none
; DETAILS:      
vsub:
  ; x y z a b c
  fsubrp st3 ; y z x-a b c
  fsubrp st3 ; z x-a y-b c
  fsubrp st3 ; x-a y-b z-c

  ret

;------------------------------------------------------------------------------
; PROCEDURE:    vadd
; IN:           st0-2: v, st3-5: w
; OUT:          st0-2: v+w
; MODIFIES:     st0-7
; CALLS:        none
; DETAILS:      
vadd:
  ; x y z a b c
  faddp st3
  faddp st3
  faddp st3

  ret

;------------------------------------------------------------------------------
; PROCEDURE:    vmul
; IN:           st0: c, st1-3: v
; OUT:          st0-2: cv
; MODIFIES:     st0-7
; CALLS:        none
; DETAILS:      
vmul:
  ; c x y z
  fmul to st1
  fmul to st2

  fmulp st3

  ret

;------------------------------------------------------------------------------
; PROCEDURE:    finv
; IN:           st0: c
; OUT:          st0: 1/c
; MODIFIES:     st0-7
; CALLS:        none
; DETAILS:      
finv:
  fld1 ; 1 c
  fdiv st1
  
  ret

;------------------------------------------------------------------------------
; PROCEDURE:    cross
; IN:           st0-2: v, st3-5: w
; OUT:          st0-2: v x w
; MODIFIES:     st0-7
; CALLS:        none
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

;------------------------------------------------------------------------------
; PROCEDURE:    vload
; IN:           rax: address of vector
; OUT:          st0-2: components of vector
; MODIFIES:     st0-7
; CALLS:        none
; DETAILS:      
vload:
  fld tword [rax + 20]
  fld tword [rax + 10]
  fld tword [rax]

  ret

;------------------------------------------------------------------------------
; PROCEDURE:    vpush
; IN:           st0-2: vector
; OUT:          vector on stack
; MODIFIES:     st0-7, stack
; CALLS:        none
; DETAILS:      pushes st0-2 onto stack and pops st0-2
%macro vpush 0
  sub rsp, 30 ; allocate 3 doubles on stack
  fstp tword [rsp]
  fstp tword [rsp+10]
  fstp tword [rsp+20]
%endmacro

;------------------------------------------------------------------------------
; PROCEDURE:    vpop
; IN:           vector on stack
; OUT:          st0-2: vector
; MODIFIES:     st0-7, stack
; CALLS:        none
; DETAILS:      pops vector off stack, pushes into st0-2
%macro vpop 0
  fld tword [rsp+20]
  fld tword [rsp+10]
  fld tword [rsp]

  add rsp, 30 ; free 3 twords on stack
%endmacro

;------------------------------------------------------------------------------
; PROCEDURE:    normal
; IN:           rax-rcx: addresses of 3 vectors
; OUT:          st0-2: normal vector to plane defined by 3 vectors
; MODIFIES:     st0-7
; CALLS:        
; DETAILS:      
normal:
  call vload ; v1 . .
  mov rax, rbx
  call vload ; v2 . . v1 . .

  call vsub  ; v2-v1 . .

  mov rax, rcx ; v3 . . v2-v1 . .
  

_start:
  finit ; reset fpuregs
  
  mov rax, x
  call vload
  vpush

  mov rax, a
  call vload
  vpop

  call vsub

  fldz
  
  
  fcomi st1     ; 0 ? dotp
  jb .less
  je .eq
  ja .great
  jmp .exit
  
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

