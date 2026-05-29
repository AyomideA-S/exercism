default rel

section .rodata

global RED
global GREEN
global BLUE
RED dd 0xFF000000
GREEN dd 0x00FF0000
BLUE dd 0x0000FF00

section .data

global base_color
base_color dd 0xFFFFFF00

section .text

global get_color_value
; get_color_value function
; Arguments:
;   rdi: address of the color in the color table
; Return:
;   eax: 32-bit value associated with the color
get_color_value:
    mov eax, dword [rdi]    ; Load the 32-bit value from the address in rdi into eax
    ret

global add_base_color
; add_base_color function
; Arguments:
;   rdi: address of the color to add to the base color
; Return:
;   None (the result is stored in the variable 'base_color')
add_base_color:
    call get_color_value        ;
    mov dword [base_color], eax ;
    ret

extern combining_function   ;

global make_color_combination
; make_color_combination function
; Arguments:
;   rdi: address where the 32-bit value for the combined color should be stored
;   rsi: address of a secondary color in the color table, to be combined with the primary color
; Return:
;   None (the result is stored in the address passed as the first argument)
make_color_combination:
    mov r12, rdi                ;
    mov edi, dword [base_color] ;
    mov esi, dword [rsi]        ;
    call combining_function     ;
    mov dword [r12], eax        ;
    ret

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
