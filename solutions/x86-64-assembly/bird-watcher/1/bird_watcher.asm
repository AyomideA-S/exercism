%include "debug.mac"
default rel

section .data
    lw_counts db 0, 2, 5, 3, 7, 8, 4    ; Last week's counts, 7 bytes for 7 days, last byte is zero

section .bss
    cw_counts resb 8    ; Current week's counts, 8 bytes to store up to 7 days and a zero byte
    cw_len resq 1       ; Current week length, 8 bytes to store the number of days filled in the current week

section .text

global last_week_counts
; last_week_counts function
; Arguments:
;   None
; Returns:
;   rax: A copy of last week's counts as an 8-byte number
last_week_counts:
    mov rax, qword [lw_counts]    ; Load last week's counts into rax
    ret

global current_week_counts
; current_week_counts function
; Arguments:
;   None
; Returns:
;   rax: A copy of current week's counts as an 8-byte number.
;   rdx: The number of days already filled in the current week, as an 8-byte number
current_week_counts:
    mov rax, qword [cw_counts]  ; Load current week's counts into rax
    mov rdx, qword [cw_len]     ; Load current week length into rdx
    ret

global save_count
; save_count function
; Arguments:
;   rdi: The most recent count, as a 1-byte number
; Returns:
;   None
save_count:
    cmp qword [cw_len], 7       ; Compare the current week length with 7
    je .new_week                ; If the current week is full, start a new week
    call .load_currents         ; Load current week's counts and length into rax and rdx respectively
    mov byte [rax + rdx], dil   ; Store the new count in the current week's counts
    inc qword [cw_len]          ; Increment the current week length
    ret

.load_currents:  ; Helper function to load current week's counts and length into rax and rdx respectively
    lea rax, [cw_counts]        ; Load the address of the current week's counts into rax
    mov rdx, qword [cw_len]     ; Load the current week length into rdx
    ret

.new_week:  ; Start a new week
    mov qword [cw_len], 0       ; Reset the current week length to 0
    mov r11, qword [cw_counts]  ; Store the current week's counts in r11 before overwriting it
    mov qword [lw_counts], r11  ; Update last week's counts with the previous current week's counts
    mov qword [cw_counts], 0    ; Reset the current week's counts
    call save_count             ; Save the new count for the current week
    ret

global today_count
; today_count function
; Arguments:
;   None
; Returns:
;   rax: A 1-byte number representing the most recent entry for the current week
today_count:
    call save_count.load_currents   ; Load current week's counts and length into rax and rdx respectively
    mov al, byte [rax + rdx - 1]    ; Load the most recent entry for the current week into rax
    ret

global update_today_count
; update_today_count function
; Arguments:
;   rdi: A 1-byte number representing the new count for the most recent entry for the current week
; Returns:
;   None
update_today_count:
    call save_count.load_currents   ; Load current week's counts and length into rax and rdx respectively
    add byte [rax + rdx - 1], dil   ; Update the most recent entry for the current week with the new count
    ret

global update_week_counts
; update_week_counts function
; Arguments:
;   rdi: An 8-byte number representing the new counts for the current week
; Returns:
;   None
update_week_counts:
    mov r11, qword [cw_counts]      ; Store the current week's counts in r11 before overwriting it
    mov qword [lw_counts], r11      ; Update last week's counts with the previous current week's counts
    mov qword [cw_counts], 0        ; Reset the current week's counts
    call save_count.load_currents   ; Load current week's counts and length into rax and rdx respectively
    mov qword [rax], rdi            ; Store the new counts for the current week in the current week's counts
    mov qword [cw_len], 7           ; Set the current week length to 7
    ret

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
