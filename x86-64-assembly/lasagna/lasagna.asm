OVEN_TIME equ 40        ; The expected oven time in minutes is 40
LAYER_PREP_TIME equ 2   ; Each layer takes 2 minutes to prepare

section .text

global expected_minutes_in_oven
; expected_minutes_in_oven function
; Arguments:
;   none
; Return:
;   the expected number of minutes the lasagna should be in the oven
expected_minutes_in_oven:
    mov rax, OVEN_TIME  ; Move the expected oven time into rax to return it
    ret ; Return from the function, with the expected oven time in rax

global remaining_minutes_in_oven
; remaining_minutes_in_oven function
; Arguments:
;   rdi: the number of minutes the lasagna has been in the oven
; Return:
;   the number of minutes remaining in the oven
remaining_minutes_in_oven:
    ; This function takes one number as argument and must return a number
    mov rax, OVEN_TIME  ; Load the fixed expected oven time
    sub rax, rdi        ; Subtract minutes spent in oven from expected time
    ret

global preparation_time_in_minutes
; preparation_time_in_minutes function
; Arguments:
;   rdi: the number of layers in the lasagna
; Return:
;   the total preparation time in minutes
preparation_time_in_minutes:
    ; This function takes one number as argument and must return a number
    imul rax, rdi, LAYER_PREP_TIME    ; Multiply number of layers by the preparation time per layer
    ret

global elapsed_time_in_minutes
; elapsed_time_in_minutes function
; Arguments:
;   rdi: the number of layers in the lasagna
;   rsi: the number of minutes the lasagna has been in the oven
; Return:
;   the total elapsed time in minutes
elapsed_time_in_minutes:
    ; This function takes two numbers as arguments and must return a number
    imul rax, rdi, LAYER_PREP_TIME  ; Multiply number of layers by the preparation time per layer
    add rax, rsi                    ; Add the time spent in the oven to the preparation time
    ret

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
