%include "debug.mac"
default rel
section .text

global create_item_entry
; create_item_entry function
; Description:
;   This function creates an item entry in memory with the provided parameters.
; Arguments:
;   rdi: The address for a location in memory where the item should be stored.
;   rsi: The ID for the item, as a 64-bit unsigned integer.
;   rdx: The address for a string with the item's description.
;   rcx: The day it was found, as a 64-bit unsigned integer.
;   r8: The month it was found, as a 64-bit unsigned integer.
;   r9: The number of categories for the item, as a 64-bit unsigned integer.
; Returns:
;   This function has no return value.
create_item_entry:
    mov [rdi], rsi      ; Store the ID at the beginning of the item entry
    mov [rdi + 8], rdx  ; Store the address of the description string
    mov [rdi + 16], rcx ; Store the day it was found
    mov [rdi + 24], r8  ; Store the month it was found
    mov [rdi + 32], r9  ; Store the number of categories
    mov rcx, r9         ; Store the number of categories in rcx for the loop
    xor r11, r11        ; Initialize r11 to 0 for the category counter
.categories:
    inc r11                     ; Increment the category counter
    mov rax, [rsp + r11*8]      ; Load the address of the category string from the stack
    mov [rdi + r11*8 + 32], rax ; Store the address of the category string in the item entry
    loop .categories            ; Loop until all categories are stored
    ret


global create_monthly_list
; create_monthly_list function
; Description:
;   This function creates a monthly list in memory with the provided capacity and allocator function.
; Arguments:
;   rdi: The capacity of the array in bytes, as a 64-bit unsigned integer.
;   rsi: An allocator function that takes the capacity as an argument and returns the address of the allocated space.
; Returns:
;   The address for the space allocated with the allocator function.
create_monthly_list:
    push rbp        ; Save the base pointer (to 16-byte align the stack for the allocator function)
    mov rbp, rdi    ; Store the capacity in rbp (to preserve it for the zeroing loop)
    call rsi        ; Call the allocator function to allocate space for the monthly list
    ; rax holds the return value of the called function (address of the allocated space)
    xor rcx, rcx    ; Initialize rcx to 0 for the zeroing loop
.zero:
    cmp rcx, rbp               ; Compare the current index (rcx) with the capacity (rbp)
    jae .done                  ; Stop once rcx >= capacity
    mov byte [rax + rcx], 0    ; Set the byte at the current index to 0
    inc rcx                    ; Increment the index
    jmp .zero                  ; Repeat the loop to zero the next byte
.done:
    pop rbp ; Restore the base pointer
    ret


global insert_found_item
; insert_found_item function
; Description:
;   This function inserts a new item entry into the monthly list at the appropriate position based on the current number of entries.
; Arguments:
;   rdi: The address for a space in memory where the monthly list is located.
;   rsi: The current number of entries already stored in the list, as a 64-bit unsigned integer.
;   A new entry to be added to the list.
; Note:
;   Each entry takes up 120 bytes, which is too large to pass in a register (per the
;   System V ABI), so it is passed on the stack instead. At function entry, it sits
;   at [rsp + 8], immediately above the return address.
; Returns:
;   This function has no return value.
insert_found_item:
    ; No prologue/epilogue: this function makes no calls and never modifies
    ; rsp, so [rsp + 8] stays valid throughout, and there are no callee-saved
    ; registers to preserve.
    imul rcx, rsi, 120  ; Calculate the offset for the new entry based on the current number of entries (rsi) and the size of each entry (120 bytes)
    add rdi, rcx        ; Calculate the address for the new entry in the monthly list by adding the offset to the base address (rdi)
    mov rcx, 15         ; Set rcx to the number of 8-byte chunks to copy (120 / 8 = 15)
    lea rsi, [rsp + 8]  ; Load the address of the new entry from the stack
    rep movsq           ; Copy the new entry to the monthly list, 8 bytes at a time
    ret


global print_item
; print_item function
; Description:
;   This function prints an item entry from the monthly list using a provided printing function.
; Arguments:
;   rdi: The address for a buffer where an introductory ASCII NUL-terminated string may be stored,
;        or 0 if no intro string is used. Passed straight through to the printing function unchanged.
;   rsi: The address for a space in memory where the monthly list is located.
;   rdx: The index of the entry in the array for the item that should be printed, as a 64-bit unsigned integer.
;   rcx: A printing function
; Returns:
;   This function has no return value.
print_item:
    mov rax, rcx        ; Store the printing function in rax for later use
    imul r10, rdx, 120  ; Calculate the offset for the item entry based on the index (rdx) and the size of each entry (120 bytes)
    add r10, rsi        ; Calculate the address for the item entry in the monthly list by adding the offset to the base address (rsi)
    push rbp            ; Dummy push, purely for 16-byte stack alignment before the call (rbp's value is never used or modified)
    mov rsi, rdx        ; Store the index in rsi (rdi already holds the intro string arg unchanged — no mov needed)
    mov rdx, [r10]      ; Load the ID of the item into rdx
    mov rcx, [r10+8]    ; Load the description address of the item into rcx
    mov r8, [r10+16]    ; Load the day of the item into r8
    mov r9, [r10+24]    ; Load the month of the item into r9
    lea r11, [r10+40]   ; Load the address of the first category string into r11
    push r11            ; Push the address of the first category string onto the stack
    push qword [r10+32] ; Push the number of categories for the item onto the stack
    call rax            ; Call the printing function
    add rsp, 24         ; Clean up the stack
    ret


%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
