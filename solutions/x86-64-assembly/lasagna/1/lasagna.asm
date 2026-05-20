; Everything that comes after a semicolon (;) is a comment

; Assembler-time constants may be defined using 'equ'
OVEN_TIME equ 40    ; The expected oven time in minutes is 40

section .text

; You should implement functions in the .text section

; the global directive makes a function visible to the test files
global expected_minutes_in_oven
; expected_minutes_in_oven function
; Arguments:
;   none
; Return:
;   the expected number of minutes the lasagna should be in the oven
expected_minutes_in_oven:
    ; TODO: This function has no arguments
    ; and must return a number
    mov rax, OVEN_TIME  ; Move the expected oven time into rax to return it
    ret ; Return from the function, with the expected oven time in rax

global remaining_minutes_in_oven
; remaining_minutes_in_oven function
; Arguments:
;   rdi: the number of minutes the lasagna has been in the oven
; Return:
;   the number of minutes remaining in the oven
remaining_minutes_in_oven:
    ; TODO: define the 'remaining_minutes_in_oven' function
    ; This function takes one number as argument and must return a number
    call expected_minutes_in_oven   ; Get the expected oven time into rax
    sub rax, rdi    ; Subtract minutes spent in oven from expected time
    ret

global preparation_time_in_minutes
; preparation_time_in_minutes function
; Arguments:
;   rdi: the number of layers in the lasagna
; Return:
;   the total preparation time in minutes
preparation_time_in_minutes:
    ; TODO: define the 'preparation_time_in_minutes' function
    ; This function takes one number as argument and must return a number
    mov rax, 2      ; Each layer takes 2 minutes to prepare
    imul rax, rdi   ; Multiply number of layers by 2 to get the total prep time
    ret

global elapsed_time_in_minutes
; elapsed_time_in_minutes function
; Arguments:
;   rdi: the number of layers in the lasagna
;   rsi: the number of minutes the lasagna has been in the oven
; Return:
;   the total elapsed time in minutes
elapsed_time_in_minutes:
    ; TODO: define the 'elapsed_time_in_minutes' function
    ; This function takes two numbers as arguments and must return a number
    mov rax, 2    ; Each layer takes 2 minutes to prepare
    imul rax, rdi   ; Calculate preparation time based on the number of layers
    add rax, rsi    ; Add the time spent in the oven to the preparation time
    ret

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
