; file with only the necessary components for timestart and timeend, to get an accurate overhead measurement

section .data
  onechar db "1"
  zerchar db "0"
  nlchar db 10


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
%%shift:  shl r8,1   ; shift rightmost bit into carry flag
  jc %%one     ; if bit is 1, jump

; print 0
%%zer:   mov rax, 4
  mov rbx, 1
  mov rcx, zerchar
  mov rdx, 1
  int 80h
  jmp %%cloop              ; jump to loop check

; print 1
%%one    mov rax, 4
  mov rbx, 1
  mov rcx, onechar
  mov rdx, 1
  int 80h
  jmp %%cloop              ; jump to loop check

; loop check
%%cloop: dec r9                 ; dec bit counter
  cmp r9,0               ; compare bit counter with 0
  jge %%shift               ; if (signed) greater, equal 0, loop

; print newline
  mov rax, 4
  mov rdx, 1
  mov rcx, nlchar
  mov rdx, 1
  int 80h
%endmacro

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

  timestart r8
  timeend r8

  mov rax, 1
  mov rbx, 0
  int 80h

