default rel

section .rodata
    drink_times db 1, 3, 3, 4, 5, 4, 7, 10  ; Time to prepare each juice, indexed by juice ID

section .text

global time_to_make_juice
; time_to_make_juice function
; Arguments:
;   edi: The ID for a juice as a 32-bit number
; Returns:
;   eax: The time to prepare this juice, as a 32-bit number
time_to_make_juice:
    lea rax, qword [drink_times]    ; Load the address of the drink_times array into rax
    movzx eax, byte [rax + rdi - 1] ; Load the time for the juice with ID in rdi (adjusted for 0-based index) into eax
    ret

global time_to_prepare
; time_to_prepare function
; Arguments:
;   rdi: An array with the IDs for ordered juices, each ID a 32-bit number
;   esi: The number of ordered juices, as a 32-bit number
; Returns:
;   eax: The total time to prepare all ordered juices, as a 32-bit number
time_to_prepare:
    mov r8, rdi     ; Store the pointer to the array of juice IDs in r8
    mov eax, 0      ; Initialize eax to 0 to accumulate the total time
    mov edx, 0      ; Initialize edx to 0 to accumulate the total time (using edx for addition to avoid overflow)
    mov ecx, esi    ; Load the number of ordered juices into ecx for the loop counter
.id_loop:
    mov edi, dword [r8 + (rcx * 4) - 4]     ; Load the juice ID from the array (adjusting for 0-based index) into edi
    call time_to_make_juice                 ; Call time_to_make_juice to get the time for this juice, result in eax
    add edx, eax                            ; Add the time for this juice to edx
    loop .id_loop                           ; Loop until all juice IDs have been processed
    mov eax, edx                            ; Move the total time from edx to eax for the return value
    ret

global limes_to_cut
; limes_to_cut function
; Arguments:
;   edi: The number of wedges needed, as a 32-bit number
;   rsi: An array with the current supply of limes, each represented by a 8-bit number
;   edx: The number of limes in the supply, as a 32-bit number
; Returns:
;   eax: The number of limes that need to be cut, as a 32-bit number
limes_to_cut:
    mov eax, 0      ; Initialize eax to 0 to count the number of limes cut
    mov ecx, edx    ; Load the number of limes in the supply into ecx for the loop counter
    mov rdx, 0      ; Initialize edx to 0 to count the number of wedges cut
.lime_loop:
    cmp ecx, 0                  ; Check if we have any limes left in the supply
    je .end_loop                ; If we have no limes left, exit the loop
    cmp edx, edi                ; Compare the number of wedges cut (edx) with the number of wedges needed (edi)
    jae .end_loop               ; If we have cut enough wedges, exit the loop
    mov r8b, byte [rsi + rax]   ; Load the size of the current lime into r8b
    inc eax                     ; Increment the number of limes cut
    dec ecx                     ; Decrement the number of limes left in the supply
    cmp r8b, 'S'                ; Compare the size with 'S' (small)
    je .small                   ; If it's small, jump to the small lime handling section
    cmp r8b, 'M'                ; Compare the size with 'M' (medium)
    je .medium                  ; If it's medium, jump to the medium lime handling section
    jmp .large                  ; If it's not small or medium, it must be large, jump to the large lime handling section
.small:
    add edx, 6      ; Add 6 wedges for a small lime
    jmp .lime_loop  ; Jump back to the start of the loop to check if we need more wedges
.medium:
    add edx, 8      ; Add 8 wedges for a medium lime
    jmp .lime_loop  ; Jump back to the start of the loop to check if we need more wedges
.large:
    add edx, 10     ; Add 10 wedges for a large lime
    jmp .lime_loop  ; Jump back to the start of the loop to check if we need more wedges
.end_loop:
    ret

global remaining_orders
; remaining_orders function
; Arguments:
;   edi: The time left in the shift, as a 32-bit number
;   rsi: An array with the IDs for ordered juices still not prepared, each ID a 32-bit number
; Returns:
;   eax: The number of juices made before the shift ends, as a 32-bit number
remaining_orders:
    mov r8d, edi    ; Load the time left in the shift into r8d
    mov ecx, 0      ; Initialize ecx to 0 to count the number of juices made
    mov edx, 0      ; Initialize edx to 0 to accumulate the total time
.order_loop:
    cmp ecx, r8d                        ; Compare the accumulated time with the time left
    jae .end_loop                       ; If we have exceeded the time left, exit the loop
    mov edi, dword [rsi + (rdx * 4)]    ; Load the ID of the next juice into edi
    call time_to_make_juice             ; Call time_to_make_juice to get the time for this juice
    add ecx, eax                        ; Add the time for this juice to the accumulated time
    inc edx                             ; Increment the number of juices made
    jmp .order_loop                     ; Jump back to the start of the loop to check if we can make another juice
.end_loop:
    mov eax, edx    ; Move the number of juices made to eax for the return value
    ret

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
