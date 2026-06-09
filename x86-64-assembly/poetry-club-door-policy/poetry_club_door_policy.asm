default rel

section .data
    please db ", please.", 0
    please_len equ $ - please

section .text

global front_door_response
; front_door_response function
; Description:
;   This function takes the address in memory for a line of the poem as an argument.
;   It returns the first letter of that line, as a ASCII-encoded character.
; Arguments:
;   rdi: address in memory for a line of the poem
; Returns:
;   al: first letter of the line, as a ASCII-encoded character
front_door_response:
    lea rsi, [rdi]  ; Load the address of the string into rsi
    lodsb           ; Load the first byte of the string into al
    ret

global front_door_password
; front_door_password function
; Description:
;   This function modifies the string in-place, making it correctly capitalized.
; Arguments:
;   rdi: address in memory for a string containing the combined letters you found in task
; Returns:
;   None
front_door_password:
    lea rsi, [rdi]  ; Load the address of the string into rsi
    cld             ; Clear the direction flag to ensure we process the string forward
    lodsb           ; Load the first byte of the string into al
    cmp al, 'a'     ; Compare the first character to 'a' (ASCII 97)
    jae .capitalize ; If it's greater than or equal to 'a', it's already lowercase, so we can capitalize it
    stosb           ; Otherwise, it's already uppercase, so we can just store it as is
    mov rcx, -1     ; Set rcx to -1 for the loop
.rest_of_word:
    lodsb               ; Load the next byte of the string into al
    cmp al, 0           ; Check if we've reached the null terminator
    je early_exit       ; If we reach the null terminator, we're done
    cmp al, 'a'         ; Compare the character to 'a'
    jb .lower_case      ; If it's less than 'a', it's not a lowercase letter, so we can convert it to lowercase
    stosb               ; Otherwise, it's already lowercase, so we can just store it as is
    loop .rest_of_word  ; Loop back to process the next character
.capitalize:    ; Capitalization logic
    sub al, 32          ; Convert the character to uppercase by subtracting 32 from its ASCII value
    stosb               ; Store the capitalized character back to the string
    jmp .rest_of_word   ; Continue processing the rest of the word
.lower_case:    ; Lowercase conversion logic
    add al, 32          ; Convert the character to lowercase by adding 32 to its ASCII value
    stosb               ; Store the lowercase character back to the string
    jmp .rest_of_word   ; Continue processing the rest of the word

global back_door_response
; back_door_response function
; Description:
;   This function takes the address in memory for a line of the poem as an argument.
;   It returns the last letter of that line that is not a whitespace character, as a ASCII-encoded character.
; Arguments:
;   rdi: address in memory for a line of the poem
; Returns:
;   al: last letter of the line that is not a whitespace character, as a ASCII-encoded character
back_door_response:
    mov rax, 0          ; Set rax to 0 to check for the null terminator
    mov rcx, -1         ; Set rcx to -1 for the loop
    cld                 ; Clear the direction flag to ensure we process the string forward
    repne scasb         ; Scan for the null terminator, rcx will be decremented for each character until we find it
    add rcx, 2          ; Adjust rcx to point to the last character before the null terminator
    neg rcx             ; Negate rcx to get the correct offset for backtracking through the string
    lea rsi, [rdi - 2]  ; Load the address of the last character before the null terminator into rsi
    std                 ; Set the direction flag to process the string backward
.backtrack:
    lodsb           ; Load the current byte of the string into al
    cmp al, 0x41    ; Compare the character to 'A' (ASCII 65)
    jb .backtrack   ; If it's less than 'A', it's not a letter, so we can continue backtracking
    ret

global back_door_password
; back_door_password function
; Description:
;   This function modifies the string in-place, making it correctly capitalized and adding ", please." at the end.
; Arguments:
;   rdi: address in memory for a buffer to store the modified string
;   rsi: address in memory for a string containing the combined letters found in task 3
; Returns:
;   None
back_door_password:
    mov rax, 0  ; Set rax to 0 to check for the null terminator
    mov rcx, -1 ; Set rcx to -1 for the loop
    cld         ; Clear the direction flag to ensure we process the string forward
.copy:
    cmp al, byte [rsi]  ; Compare the current character in rsi to the null terminator
    je .process_string  ; If we reach the null terminator, we're done copying and can start processing the string
    movsb               ; Copy the current character from rsi to rdi
    loop .copy          ; Loop back to copy the next character
.process_string:
    stosb                       ; Store the null terminator at the end of the copied string
    add rcx, 1                  ; Adjust rcx to point to the correct position for processing the string
    neg rcx                     ; Negate rcx to get the correct offset for processing the string
    call .string_start          ; Call the .string_start function to adjust rdi to point to the start of the string we just copied
    push rcx                    ; Push rcx to save the length of the string for later use
    call front_door_password    ; Call the front_door_password function to capitalize the first letter and lowercase the rest
.add_please:
    pop rcx             ; Pop rcx to restore the length of the string
    lea rsi, [please]   ; Load the address of the ", please." string into rsi
    mov rcx, please_len ; Load the length of the ", please." string into rcx
    dec rcx             ; Adjust rcx to account for the null terminator in the ", please." string
    rep movsb           ; Copy the ", please." string to the end of the modified string
    stosb               ; Store the null terminator at the end of the modified string
    ret

.string_start:
    sub rdi, rcx    ; Adjust rdi to point to the start of the string we just copied
    dec rdi         ; Adjust rdi to point to the start of the string we just copied (plus the null terminator)
    ret

early_exit:
    ret

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
