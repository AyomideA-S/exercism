WEIGHT_OF_EMPTY_BOX equ 500
TRUCK_HEIGHT equ 300
PAY_PER_BOX equ 5
PAY_PER_TRUCK_TRIP equ 220

section .text

global get_box_weight
; get_box_weight function
; Arguments:
;   rdi: The number of items for the first product in the box, as a 16-bit non-negative integer
;   rsi: The weight of each item of the first product, in grams, as a 16-bit non-negative integer
;   rdx: The number of items for the second product in the box, as a 16-bit non-negative integer
;   rcx: The weight of each item of the second product, in grams, as a 16-bit non-negative integer
; Return:
;   the total weight of a box, in grams, as a 32-bit non-negative integer
get_box_weight:
    mov rax, WEIGHT_OF_EMPTY_BOX    ; Start with the weight of the empty box
    ; Calculate the weight of the first product and add it to rax
    mov rbx, rdi                    ; Move the number of items of the first product into rbx
    mov r8, rsi                     ; Move the weight of each item of the first product into r8
    imul rbx, r8                    ; Multiply to get the total weight of the first product
    add rax, rbx                    ; Add the weight of the first product to the total weight
    ; Calculate the weight of the second product and add it to rax
    mov rbx, rdx                    ; Move the number of items of the second product into rbx
    mov r8, rcx                     ; Move the weight of each item of the second product into r8
    imul rbx, r8                    ; Multiply to get the total weight of the second product
    add rax, rbx                    ; Add the weight of the second product to the total weight
    ret                             ; Return the total weight of the box in rax

global max_number_of_boxes
; max_number_of_boxes function
; Arguments:
;   rdi: The height of the box, in centimeters, as an 8-bit non-negative integer
; Return:
;   how many boxes can be stacked vertically, as an 8-bit non-negative integer
max_number_of_boxes:
    mov rax, TRUCK_HEIGHT   ; Get the truck interior height in cm into rax
    xor rdx, rdx            ; Clear rdx to prepare for unsigned division
    div rdi                 ; Divide the truck interior height by the height of the box
    ret

global items_to_be_moved
; items_to_be_moved function
; Arguments:
;   rdi: The number of items still unaccounted for a product, as a 32-bit non-negative integer
;   rsi: The number of items for the product in a box, as a 32-bit non-negative integer
; Return:
;   how many items remain to be moved, after counting those in the box, as a 32-bit integer
items_to_be_moved:
    mov rax, rdi    ; Move the number of unaccounted items into rax
    sub rax, rsi    ; Subtract the number of items in the box
    ret

global calculate_payment
; calculate_payment function
; Arguments:
;   rdi: The upfront payment, as a 64-bit non-negative integer
;   rsi: The total number of boxes moved, as a 32-bit non-negative integer
;   rdx: The number of truck trips made, as a 32-bit non-negative integer
;   rcx: The number of lost items, as a 32-bit non-negative integer
;   r8: The value of each lost item, as a 64-bit non-negative integer
;   r9: The number of other workers to split the payment/debt with you, as an 8-bit positive integer
; Return:
;   how much you should be paid, or pay, at the end, as a 64-bit integer (possibly negative)
calculate_payment:
    mov r10, rdx                    ; Move the number of truck trips made into r10
    ; Calculate the total payment for the boxes moved
    mov rax, PAY_PER_BOX            ; Move the pay per box into rax
    mov rbx, rsi                    ; Move the total number of boxes moved into rbx
    mul rbx                         ; Multiply to get the total payment for the boxes
    ; Calculate the total payment for the truck trips
    mov rbx, PAY_PER_TRUCK_TRIP     ; Move the pay per truck trip into rbx
    imul rbx, r10                   ; Multiply to get the total payment for the truck trips
    add rax, rbx                    ; Add the payment for the truck trips to the payment for the boxes
    ; Subtract the upfront payment from the total payment
    sub rax, rdi                    ; Subtract the upfront payment from the net payment
    ; Calculate the total debt for the lost items
    mov rbx, rcx                    ; Move the number of lost items into rbx
    mov r10, r8                     ; Move the value of each lost item into r10
    imul rbx, r10                   ; Multiply to get the total debt for the lost items
    sub rax, rbx                    ; Subtract the debt for the lost items from the net payment
    ; Split the net payment with the other workers
    mov rbx, r9                     ; Move the number of other workers to split the payment/debt with you into rbx
    inc rbx                         ; Increment to include yourself in the split
    cqo                             ; Sign extend rax into rdx for signed division
    idiv rbx                        ; Divide the net payment by the number of workers to split with
    add rax, rdx                    ; Add the remainder from the division to the final payment to ensure it is an integer
    ret

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
