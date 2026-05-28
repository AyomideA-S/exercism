; %include "debug.mac"

C2 equ 2
C3 equ 3
C4 equ 4
C5 equ 5
C6 equ 6
C7 equ 7
C8 equ 8
C9 equ 9
C10 equ 10
CJ equ 11
CQ equ 12
CK equ 13
CA equ 14

TRUE equ 1
FALSE equ 0

section .text

global value_of_card
; value_of_card function
; Arguments:
;   rdi: The number representing a card, as an 8-bit non-negative integer
; Return:
;   the numerical value of the passed-in card, as an 8-bit non-negative integer
value_of_card:
    mov rax, rdi    ; Move the card number into rax for comparison
    call .main_logic   ; Call the main logic to resolve the value of the card
    ret

.main_logic:    ; Main logic for resolving the value of a card
    cmp rax, CA     ; Compare the card number to 14 (the value of an ace)
    je .ace         ; If it's an ace, jump to the .ace label
    cmp rax, CJ     ; Compare the card number to 11 (the value of a jack)
    jae .face_card  ; If it's 11 or higher (jack, queen, king), jump to the .face_card label
    ret     ; If it's a number card (2-10), return its value (which is the same as the card number) in rax

.ace:   ; Return the value of an ace, which is 1
    mov rax, 1  ; Move the value of an ace into rax
    ret

.face_card: ; Return the value of a face card, which is 10
    mov rax, 10 ; Move the value of a face card into rax
    ret

global higher_card
; higher_card function
; Arguments:
;   rdi: The number representing the first card, as an 8-bit non-negative integer
;   rsi: The number representing the second card, as an 8-bit non-negative integer
; Return:
;   rax: the value of the higher card, as an 8-bit non-negative integer
;   rdx:
;       - 0 for the lower card, else
;       - the value of the card, if both cards have equal value, as an 8-bit non-negative integer
higher_card:
    mov rbx, 0              ; Clear rbx to prepare for usage
    mov rdx, 0              ; Clear rdx to prepare for usage
    mov r12, 0              ; Clear r12 to prepare for usage
    mov r13, 0              ; Clear r13 to prepare for usage
    mov rax, rdi            ; Move the first card number into rax for comparison
    call .resolve_card_one  ; Resolve the value of the first card if it's a non-number card
    mov r15, rax            ; Temporarily store the resolved value of the first card in r15
    mov rax, rsi            ; Move the second card number into rax for comparison
    call .resolve_card_two  ; Resolve the value of the second card if it's a non-number card
    mov rdx, rax            ; Temporarily store the resolved value of the second card in rdx
    mov rax, r15            ; Move the resolved value of the first card back into rax for comparison
    ;-------------------------------------
    ;  Debug block
    ;-------------------------------------
    ; debugs msg_home  ; "Home stretch..."
    ; debugd64 rdi
    ; debugd64 rsi
    ; debugd64 rax
    ; debugd64 rdx
    ; debugx16 bx
    ; debugd64 r12
    ; debugd64 r13
    ;--------------------------------------
    cmp rax, rdx            ; Compare the first card to the second card
    ja .card_one            ; If the first card is higher, jump to .card_one
    jb .card_two            ; If the second card is higher, jump to .card_two
    mov rax, rdi            ; If both cards are equal, move the first card number into rax to return it
    mov rdx, rsi            ; Move the second card number into rdx to return it
    ret

.resolve_card_one:  ; Resolve the value of the first card if it's a non-number card
    cmp rax, C10                    ; Compare the first card number to 10 (the value of a 10)
    jbe .bail_out                   ; If it's 10 or lower, it's a number card, so we can bail out of resolving
    mov bl, al                      ; Move the card number (which is 14 for an ace) into bl
    mov r12, 1                      ; Set r12 to 1 to indicate that we are resolving a non-number card
+    cmp rax, CA                     ; Compare the first card number to 14 (the value of an ace)
+    je value_of_card.ace            ; Tail-call into value_of_card.ace; it returns directly to the caller of higher_card
+    call value_of_card.face_card    ; Call the value_of_card.face_card function to get the value of the face card, then return below
+    ret

.resolve_card_two:  ; Resolve the value of the first card if it's a non-number card
    cmp rax, C10                    ; Compare the first card number to 10 (the value of a 10)
    jbe .bail_out                   ; If it's 10 or lower, it's a number card, so we can bail out of resolving
    mov bh, al                      ; Move the card number (which is 14 for an ace) into bl
    mov r13, 1                      ; Set r12 to 1 to indicate that we are resolving a non-number card
    cmp rax, CA                     ; Compare the first card number to 14 (the value of an ace)
    je value_of_card.ace          ; Call the value_of_card.ace function to get the value of an ace
    call value_of_card.face_card    ; Call the value_of_card.face_card function to get the value of the face card
    ret

.card_one:  ; If the first card is higher, move its value to rax and set rdx to 0
    mov rdx, 0              ; Set rdx to 0 for the lower card
    cmp r12, 1              ; Check if the first card was a non-number card that we resolved
    je .restore_card_one    ; If it was, restore the original card number for the first card in rax before returning
    ret

.card_two:  ; If the second card is higher, move its value to rax and set rdx to 0
    mov rdx, 0              ; Set rdx to 0 for the lower card
    cmp r13, 1              ; Check if the second card was a non-number card that we resolved
    je .restore_card_two    ; If it was, restore the original card number for the second card in rax before returning
    mov rax, rsi            ; Move the second card number into rax to return it
    ret

.restore_card_one:  ; Restore the original card number for the first card in rax before returning
    movzx rax, bl   ; Move the original card number for the first card from bl into rax, zero-extending it to 64 bits
    ret

.restore_card_two:  ; Restore the original card number for the second card in rax before returning
    mov rax, 0  ; Clear rax to prepare for moving the original card number for the second card from bh into rax
    mov al, bh  ; Move the original card number for the second card from bh into al (the lower 8 bits of rax)
    ret

.bail_out:  ; Do nothing and return to the caller since the card is a number card and doesn't need resolving
    ret

global value_of_ace
; value_of_ace function
; Arguments:
;   rdi: The number representing the first card, as an 8-bit non-negative integer
;   rsi: The number representing the second card, as an 8-bit non-negative integer
; Return:
;   the value of an upcoming ace, as an 8-bit non-negative integer
value_of_ace:
    mov rdx, 21                     ; Set rdx to 21, which is the maximum value of a hand in blackjack
    mov rax, rdi                    ; Move the first card number into rax for comparison
    call value_of_card.main_logic   ; Call the main logic to resolve the value of the first card
    call .ace_in_hand               ; Check if the first card is an ace, and if so, return 1 in rax to indicate that there is an ace in hand, else return to the caller
    sub rdx, rax                    ; Subtract the value of the first card from 21 to get the maximum value that the ace can take without busting
    mov rax, rsi                    ; Move the second card number into rax for comparison
    call value_of_card.main_logic   ; Call the main logic to resolve the value of the second card
    call .ace_in_hand               ; Check if the second card is an ace, and if so, return 1 in rax to indicate that there is an ace in hand, else return to the caller
    sub rdx, rax                    ; Subtract the value of the second card from the remaining value in rdx to get the maximum value that the ace can take without busting
    cmp rdx, 11                     ; Compare the value of the second card to 11 (the value of an ace)
    jae .high_ace                   ; If the second card is 11 or higher (an ace or a face card), the ace can only take the value of 1 without busting, so jump to the .high_ace label
    mov rax, 1                      ; If the second card is lower than 11, the ace can take the value of 11 without busting, so move 1 into rax to return it
    ret

.ace_in_hand: ; Check if either of the two cards in hand is an ace, and if so, return 1 in rax to indicate that there is an ace in hand, else return to the caller
    cmp rax, 1      ; Compare the value of the first card to 1 (the value of an ace)
    je .high_ace    ; If the first card is an ace, it can take the value of 11 without busting, so jump to the .high_ace label
    ret

.high_ace:  ; If the second card is 11 or higher (an ace or a face card), the ace can only take the value of 1 without busting, so move 1 into rax to return it
    mov rax, 11 ; Move 11 into rax to return it as the value of the ace since it can take the value of 11 without busting
    ret

global is_blackjack
; is_blackjack function
; Arguments:
;   rdi: The number representing the first card, as an 8-bit non-negative integer
;   rsi: The number representing the second card, as an 8-bit non-negative integer
; Return:
;   TRUE if the two cards form a blackjack, and FALSE otherwise, as an 8-bit non-negative integer
is_blackjack:
    mov rax, rdi        ; Move the first card number into rax for comparison
    call .card_value    ; Call the .card_value function to get the value of the first card
    mov rdx, rax        ; Temporarily store the value of the first card in rdx
    mov rax, rsi        ; Move the second card number into rax for comparison
    call .card_value    ; Call the .card_value function to get the value of the second card
    add rax, rdx        ; Add the value of the first card (stored in rdx) to the value of the second card (in rax)
    cmp rax, 21         ; Compare the total value of the two cards to 21
    je .blackjack       ; If the total value is 21, jump to the .blackjack label
    mov rax, FALSE      ; If the total value is not 21, move FALSE into rax
    ret

.card_value:    ; Get the value of a card, resolving it if it's a non-number card
    cmp rax, CA                 ; Compare the card number to 14 (the value of an ace)
    je .ace                     ; If it's an ace, jump to the .ace label
    cmp rax, CJ                 ; Compare the card number to 11 (the value of a jack)
    jae value_of_card.face_card ; If it's 11 or higher (jack, queen, king), jump to the .face_card label
    ret

.ace:   ; Return the value of an ace to make a blackjack
    mov rax, 11  ; Move the value of an ace (11) into rax
    ret

.blackjack: ; If the total value of the two cards is 21, move TRUE into rax to indicate that the two cards form a blackjack
    mov rax, TRUE   ; Move TRUE into rax to indicate that the two cards form a blackjack
    ret

global can_split_pairs
; can_split_pairs function
; Arguments:
;   rdi: The number representing the first card, as an 8-bit non-negative integer
;   rsi: The number representing the second card, as an 8-bit non-negative integer
; Return:
;   TRUE if the two cards can be split into two pairs, and FALSE otherwise, as an 8-bit non-negative integer
can_split_pairs:
    mov rax, rdi                    ; Move the first card number into rax for comparison
    call value_of_card.main_logic   ; Call the value_of_card.main_logic function to get the value of the first card
    mov rdx, rax                    ; Temporarily store the value of the first card in rdx
    mov rax, rsi                    ; Move the second card number into rax for comparison
    call value_of_card.main_logic   ; Call the value_of_card.main_logic function to get the value of the second card
    sub rax, rdx                    ; Subtract the value of the first card (stored in rdx) from the value of the second card (in rax)
    cmp rax, 0                      ; Compare the result to 0
    je is_blackjack.blackjack       ; If the result is 0, jump to the is_blackjack.blackjack label
    mov rax, FALSE                  ; If the result is not 0, move FALSE into rax
    ret

global can_double_down
; can_double_down function
; Arguments:
;   rdi: The number representing the first card, as an 8-bit non-negative integer
;   rsi: The number representing the second card, as an 8-bit non-negative integer
; Return:
;   TRUE if the two cards form a hand that can be doubled down, and FALSE otherwise, as an 8-bit non-negative integer
can_double_down:
    mov rax, rdi                    ; Move the first card number into rax for comparison
    call value_of_card.main_logic   ; Call the value_of_card.main_logic function to get the value of the first card
    mov rdx, rax                    ; Temporarily store the value of the first card in rdx
    mov rax, rsi                    ; Move the second card number into rax for comparison
    call value_of_card.main_logic   ; Call the value_of_card.main_logic function to get the value of the second card
    add rax, rdx                    ; Add the value of the first card (stored in rdx) to the value of the second card (in rax)
    cmp rax, 9                      ; Compare the total value to 9
    jae .upper_limit                ; If the total value is 9 or higher, jump to the .upper_limit label
    mov rax, FALSE                  ; If the total value is less than 9, move FALSE into rax
    ret

.upper_limit:   ; If the total value of the two cards is 9 or higher, move TRUE into rax to indicate that the two cards form a hand that can be doubled down
    cmp rax, 11                 ; Compare the total value of the two cards to 11
    jbe is_blackjack.blackjack  ; If the total value is 11 or lower, jump to the is_blackjack.blackjack label
    mov rax, FALSE              ; If the total value is higher than 11, move FALSE into rax
    ret

;---------------------
;  Debug string literals
;---------------------
; section .rodata ; Read-only data section for string literals
;     ; Compile with `make LDFLAGS="-no-pie"`
;     msg_home: db "Home stretch...", 0x0
;     msg_success: db "Success!", 0xA, 0x0 ; 0xA is a newline character & 0x0 is a null terminator

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
