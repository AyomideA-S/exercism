section .text

global extract_higher_bits
; extract_higher_bits function
; Arguments:
;   di: 16-bit integer
; Returns:
;   al: higher 8-bit value of the argument
extract_higher_bits:
    mov ax, di  ; Move the 16-bit argument into ax
    call .main  ; Call the main function to extract the higher bits
    ret

.main:
    shr ax, 8   ; Shift right by 8 to get the higher 8 bits in al
    ret

global extract_lower_bits
; extract_lower_bits function
; Arguments:
;   di: 16-bit integer
; Returns:
;   al: lower 8-bit value of the argument
extract_lower_bits:
    mov ax, di  ; Move the 16-bit argument into ax
    call .main  ; Call the main function to extract the lower bits
    ret

.main:
    xor ah, ah  ; Mask out the higher 8 bits to leave only the lower 8 bits in al
    ret

global extract_redundant_bits
; extract_redundant_bits function
; Arguments:
;   di: 16-bit integer encoding the message, where the lower 8 bits are the message bits and the higher 8 bits are the mask bits
; Returns:
;   al: 8-bit integer with all bits set in both the lower and the higher 8 bits of the argument
extract_redundant_bits:
    mov ax, di  ; Move the 16-bit argument into ax
    call .main  ; Call the main function to extract the redundant bits
    ret

.main:
    and al, ah  ; Perform bitwise AND to get redundant bits
    xor ah, ah  ; Mask out the higher 8 bits to leave only the redundant bits in al
    ret

global set_message_bits
; set_message_bits function
; Arguments:
;   di: 16-bit integer encoding the message, where the lower 8 bits are the message bits and the higher 8 bits are the mask bits
; Returns:
;   al: 8-bit integer with all bits set if they are set in the higher 8 bits of the argument, the others unchanged
set_message_bits:
    mov ax, di  ; Move the 16-bit argument into ax
    call .main  ; Call the main function to set the message bits
    ret

.main:
    or al, ah   ; Perform bitwise OR to set bits in al that are set in ah
    xor ah, ah  ; Mask out the higher 8 bits to leave only the message bits in al
    ret

global rotate_private_key
; rotate_private_key function
; Arguments:
;   di: 16-bit integer encoding the message, where the lower 8 bits are the message bits and the higher 8 bits are the mask bits
; Returns:
;   ax: 16-bit integer with bits of the private key rotated to the left a number of positions equal to the redundant bits
rotate_private_key:
    mov ax, di                          ; Move the 16-bit argument into ax
    call extract_redundant_bits.main    ; Extract the redundant bits
    popcnt cx, ax                       ; Count the number of set bits in ax (redundant bits) and store the count in cx
    mov ax, 0b1011001100111100          ; Load the private key into ax
    rol ax, cl                          ; Rotate ax to the left by the number of positions in cx
    ret

global format_private_key
; format_private_key function
; Arguments:
;   di: 16-bit integer encoding the message, where the lower 8 bits are the message bits and the higher 8 bits are the mask bits
; Returns:
;   al: 8-bit integer with the private key fully formatted
format_private_key:
    call rotate_private_key         ; Rotate the private key and store the result in ax
    mov bx, ax                      ; Store the rotated private key in bx for later use
    call extract_higher_bits.main   ; Extract the higher bits of the rotated private key and store in al
    mov dl, al                      ; Store the higher bits in dl for later use
    mov ax, bx                      ; Restore the rotated private key in ax
    call extract_lower_bits.main    ; Extract the lower bits of the rotated private key and store in al
    xor al, dl                      ; XOR the lower bits with the higher bits
    not al                          ; NOT the result to get the formatted private key in al
    ret

global decrypt_message
; decrypt_message function
; Arguments:
;   di: 16-bit integer encoding the message, where the lower 8 bits are the message bits and the higher 8 bits are the mask bits
; Returns:
;   ax: 16-bit integer, of which:
;   - ah: The higher 8 bits are the formatted private key, according to 'format_private_key'
;   - al: The lower 8 bits are the message with all bits set, according to 'set_message_bits'
decrypt_message:
    call format_private_key ; Format the private key and store the result in al
    mov dl, al              ;
    call set_message_bits   ;
    mov ah, dl              ;
    ret

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
