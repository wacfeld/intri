; vim:nowrap
;------------------------------------------------------------------------------
; NAME:         intri
; TYPE:         main
; DESCRIPTION:  determines whether a point is a triangle on a sphere
; BUILD:        nasm -f elf64 -g -F dwarf main.asm -l main.lst
;               ld -o main main.o
;------------------------------------------------------------------------------
section .data

; num dt -6.0

; x dt 5.0
; y dt 3.0
; z dt 2.0

; a dt 4.0
; b dt 2.0
; c dt 1.0

; d dt 6.0
; e dt 3.0
; f dt -1.0

origin dt 0.0, 0.0, 0.0
; G=(-0.93,0.22,-0.29)
v1 dt -0.93, 0.22, -0.29
v2 dt -0.76, -0.41, -0.51
v3 dt -0.67, 0.1, -0.74

p dt -0.92, 0.16, -0.37

msg1 db "less", 10
len1 equ $ - msg1
msg2 db "eq", 10
len2 equ $ - msg2
msg3 db "great", 10
len3 equ $ - msg3

failmsg db "fails test", 10
faillen equ $ - failmsg

successmsg db "passes test", 10
successlen equ $ - successmsg

onechar db "1"
zerchar db "0"
nlchar db 10

section .bss
c rest 3
temp111 rest 300
n1 rest 3
n2 rest 3
n3 rest 3
temp222 rest 300

; ; 3 vectors defining a triangle
; p1 rest 3
; p2 rest 3
; p3 rest 3

section .text

;------------------------------------------------------------------------------
; PROCEDURE:    unpack
; IN:           edx:eax: qword
; OUT:          rax:qword
; MODIFIES:     rax, rdx
; CALLS:        
; DETAILS:      
%macro unpack 0
  shl rdx, 32 ; edx -> left half of rdx
  ; and rax, 0FFFF_FFFFH ; zero left half of rax
  ; zero left half of rax
  shl rax, 32
  shr rax, 32
  add rax, rdx ; whole number in rdx now
%endmacro

;------------------------------------------------------------------------------
; PROCEDURE:    bin_str
; IN:           rax: qword binary number
; OUT:          none
; MODIFIES:     registers
; CALLS:        system call
; DETAILS:      checks each bit, then prints corresponding ascii 0 or 1, followed by newline at very end
%macro bin_str 0
        mov r8, rax ; we need rax, so store elsewhere

        mov r9,63  ; run 63+1 = 64 times
shift:  shl r8,1   ; shift rightmost bit into carry flag
        jc .one     ; if bit is 1, jump

; print 0
.zer:   mov rax, 4
        mov rbx, 1
        mov rcx, zerchar
        mov rdx, 1
        int 80h
        jmp .cloop              ; jump to loop check

; print 1
.one    mov rax, 4
        mov rbx, 1
        mov rcx, onechar
        mov rdx, 1
        int 80h
        jmp .cloop              ; jump to loop check

; loop check
.cloop: dec r9                 ; dec bit counter
        cmp r9,0               ; compare bit counter with 0
        jge shift               ; if (signed) greater, equal 0, loop

; print newline
        mov rax, 4
        mov rdx, 1
        mov rcx, nlchar
        mov rdx, 1
        int 80h
%endmacro

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
; PROCEDURE:    vdot
; IN:           st0-2: v, st3-5: w
; OUT:          st0: v . w
; MODIFIES:     st0-7
; CALLS:        none
; DETAILS:      dot product
vdot:
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
  fdivrp st1
  
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
; IN:           address of vector
; OUT:          st0-2: components of vector
; MODIFIES:     st0-7
; CALLS:        none
; DETAILS:      
%macro vload 1
  fld tword [%1 + 20]
  fld tword [%1 + 10]
  fld tword [%1]

%endmacro

;------------------------------------------------------------------------------
; PROCEDURE:    vstore
; IN:           address
; OUT:          vector in address
; MODIFIES:     
; CALLS:        
; DETAILS:      stores in address, pops from fpu stack
%macro vstore 1
  fstp tword [%1]
  fstp tword [%1+10]
  fstp tword [%1+20]
%endmacro


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
; IN:           3 addresses of vectors
; OUT:          st0-2: normal vector to plane defined by 3 vectors
; MODIFIES:     st0-7
; CALLS:        
; DETAILS:      
%macro normal 3
  vload %1   ; v1 . .
  vload %2   ; v2 . . v1 . .

  call  vsub  ; v2-v1 . .

  vpush       ; 

  vload %1   ; v1 . .
  vload %3   ; v3 . .

  call  vsub  ; v3-v1 . .

  vpop        ; v2-v1 . . v3-v1 . .

  call  cross ; n
  
%endmacro
  
;------------------------------------------------------------------------------
; PROCEDURE:    center
; IN:           addresses of 3 vectors
; OUT:          st0-2: average of 3 vectors
; MODIFIES:     st0-7
; CALLS:        
; DETAILS:      
%macro center 3
  vload %1 ; v1
  vload %2 ; v2 v1
  call vadd ; v1+v2
  vload %3 ; v3 v1+v2
  call vadd ; v1+v2+v3
  
  ; sum = v1+v2+v3

  ; obtain the number 3...
  fld1 ; 1 sum
  fadd st0 ; 2 sum
  fld1 ; 1 2 sum
  faddp st1 ; 3 sum
  call finv ; 1/3 sum ; TODO optimize by computing 1/3 beforehand
  call vmul ; 1/3*sum
%endmacro

;------------------------------------------------------------------------------
; PROCEDURE:    samesign
; IN:           st0-1: two floats
; OUT:          ZF: 1 if same sign, else 0
; MODIFIES:     st0-7, rax, rbx
; CALLS:        
; DETAILS:      considers -0.0 positive
samesign:
  ; a b
  fldz ; 0 a b
  fcomi st1 ; 0 ? a
  jb .neg1
  jmp .pos1
  
.neg1:
  mov rax, 0
  jmp .done1
.pos1:
  mov rax, 1
  jmp .done1
.done1:

  fstp st1 ; 0 n3.c
  fcomi st1 ; 0 ? b
  jb .neg2
  jmp .pos2

.neg2:
  mov rbx, 0
  jmp .done2
.pos2:
  mov rbx, 1
  jmp .done2
.done2:
  
  cmp rax, rbx ; set ZF accordingly
  ret ; according to jeff duntemann's appendix, RET does not affect flags

;------------------------------------------------------------------------------
; PROCEDURE:    echo
; IN:           msg, len
; OUT:          none
; MODIFIES:     rax-rdx
; CALLS:        
; DETAILS:      prints msg
%macro echo 2
  mov rax, 4
  mov rbx, 1
  mov rcx, %1
  mov rdx, %2
  int 80h
%endmacro
  
; TODO make everything macros
; TODO optimize

%macro timestart 1
  rdtsc
  unpack
  mov %1, rax
%endmacro

%macro timeend 1
  rdtsc
  unpack
  sub rax, %1
  bin_str
%endmacro

global _start
_start:
  ; rdtsc
  ; unpack
  ; mov r8, rax
  

  ; rdtsc
  ; unpack
  ; sub rax, r8
  ; bin_str
  ; jmp .exit

  finit ; reset fpuregs

timestart r8

  vload p ; p
  call norm ; |p|
  call finv ; 1/|p|
  fstp tword [rsp-10]
  vload p
  fld tword [rsp-10]
  call vmul
  vstore p

  normal v1, v2, origin ; n1
  vstore n1
  normal v1, v3, origin ; n2
  vstore n2
  normal v2, v3, origin ; n3
  vstore n3

; TODO optimize the memory transfers in this section
; TODO redo all with SIMD and compare
; TODO do in pure C and compare
; TODO take advantage of fdecstp and fincstp (rotating stack)
  center v1, v2, v3 ; c
  vstore c ; copy c

; compare *.n1 signs
  vload c ; copy c back
  vload n1
  call vdot ; n3.c


  vload p
  vload n1
  call vdot ; n3.p n3.c


  call samesign
  vload n2
  jnz .fail ; if not same sign, fail

  finit ;reset
; compare *.n2 signs
  vload c
  vload n2
  call vdot

  vload p
  vload n2
  call vdot

  call samesign
  jnz .fail

  finit ;reset
; compare *.n3 signs
  vload c
  vload n3
  call vdot

  vload p
  vload n3
  call vdot

  call samesign
  jnz .fail

.success:
  ; echo successmsg, successlen
  jmp .wrap
  
.fail:
  ; echo failmsg, faillen
  jmp .wrap

; .comp:
;   fcomi st1
;   jb .less
;   je .eq
;   ja .great
;   jmp .exit
  
; .less:
;   mov eax, 4
;   mov ebx, 1
;   mov ecx, msg1
;   mov edx, len1
;   int 80h
;   jmp .exit

; .eq:
;   mov eax, 4
;   mov ebx, 1
;   mov ecx, msg2
;   mov edx, len2
;   int 80h
;   jmp .exit

; .great:
;   mov eax, 4
;   mov ebx, 1
;   mov ecx, msg3
;   mov edx, len3
;   int 80h
;   jmp .exit

.wrap:
  timeend r8
.exit:
  mov rax, 1
  mov rbx, 0
  int 80h

