section .text

global add_bonus
; add_bonus function
; Description:
;   This function takes a current score total and a bonus, and returns the new total after adding the bonus.
; However, if the new total exceeds 999999, it should return 999999 instead.
; Arguments:
;   rdi: total (current score total, always between 0 and 999999)
;   rsi: bonus (bonus to add, always non-negative)
; Returns:
;   rax: total + bonus if that sum is less than or equal to 999999, and 999999 otherwise
add_bonus:
    mov rax, 999999 ; Load the maximum allowed score into rax
    add rdi, rsi    ; Add the bonus to the total
    cmp rdi, 999999 ; Compare the new total with 999999
    cmovl rax, rdi  ; If the new total is less than 999999, move it into rax
    ret

global compare_scores
; compare_scores function
; Description:
;   This function takes two 64-bit signed integers as arguments
; Arguments:
;   rdi: score1 (the first score to compare)
;   rsi: score2 (the second score to compare)
; Returns:
;   rax: +1 if the first score is higher, -1 if the first score is lower, 0 if equal (as a 64-bit signed integer)
compare_scores:
    xor rax, rax    ; Clear rax to prepare for setting the return value
    sub rdi, rsi    ; Subtract score2 from score1 to determine their relationship
    setg al         ; Set al to 1 if score1 > score2
    setl dl         ; Set dl to 1 if score1 < score2
    neg dl          ; Negate dl to get -1 if score1 < score2
    or al, dl       ; Combine the results
    movsx rax, al   ; Sign-extend the result to 64-bit
    ret

global validate_score
; validate_score function
; Description:
;   This function takes three 64-bit signed integers as arguments: score, min, and max.
;   It should clamp score between min and max, returning min if score < min, max if score > max, and score otherwise.
; Arguments:
;   rdi: score (the raw score to validate)
;   rsi: min (the smallest allowed score)
;   rdx: max (the largest allowed score)
; Returns:
;   rax: the clamped score (as a 64-bit signed integer)
validate_score:
    mov rax, rdi    ; Start with the original score in rax
    cmp rdi, rsi    ; Compare score with min
    cmovl rax, rsi  ; If score < min, move min into rax
    cmp rdi, rdx    ; Compare score with max
    cmovg rax, rdx  ; If score > max, move max into rax
    ret

global top_two
; top_two function
; Description:
;   This function finds the top two non-negative values in the input array and stores them in the output buffer.
;   Those values are 64-bit signed integers and must be stored in descending order.
; Arguments:
;   rdi: memory address for an output buffer where the top two non-negative scores will be stored in descending order
;   rsi: input array of 64-bit signed integers
;   rdx: the number of elements in the array, as a 64-bit unsigned integer
; Returns:
;   None (the function has no return value)
top_two:
    ; Initialization
    ; Do not modify!
    xor r8d, r8d                   ; first  = 0
    xor r9d, r9d                   ; second = 0
    xor ecx, ecx                   ; index = 0
    test rdx, rdx
    jz .done

.loop:
    xor r10b, r10b                  ; Assume candidate is not greater than first
    xor r11b, r11b                  ; Assume candidate is not greater than second
    cmp qword [rsi + rcx*8], r9     ; Compare candidate with second
    setg r11b                       ; If candidate > second, set r11b to 1
    cmp qword [rsi + rcx*8], r8     ; Compare candidate with first
    setge r10b                      ; If candidate >= first, set r10b to 1
    add r10b, r11b                  ; r10b = 1 if candidate >= first, 0 otherwise; add r11b to account for candidate > second
    cmp r10b, 1                     ; Check if candidate is greater than or equal to first and greater than second
    cmove r9, qword [rsi + rcx*8]   ; If candidate >= first, move candidate into second
    cmovg r9, r8                    ; If candidate > second, move first into second
    cmovg r8, qword [rsi + rcx*8]   ; If candidate > first, move candidate into first
    inc rcx                         ; Increment index
    cmp rcx, rdx                    ; Compare index with the number of elements
    jb .loop                        ; If index < number of elements, continue looping

    ; Conclusion
    ; Do not modify!
.done:
    mov qword [rdi], r8            ; save first
    mov qword [rdi + 8], r9        ; save second
    ret

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
