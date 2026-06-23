default rel

section .rodata
align 16
abs_mask: dd 0b0_11111111_11111111111111111111111, 0o17777777777, 0x7FFFFFFF, 2147483647    ; Mask to clear the sign bit of a 32-bit float, repeated 4 times for SIMD
exp_mask: dd 0b0_11111111_00000000000000000000000, 0o17740000000, 0x7F800000, 2139095040    ; Mask to extract the exponent bits of a 32-bit float, repeated 4 times for SIMD
bias: dd 0b01111111, 0o177, 0x7F, 127   ; The bias for the exponent of a 32-bit float, repeated 4 times for SIMD

section .text

global rectify_trace
; rectify_trace function
; Description:
;   This function computes the absolute value of each reading, by clearing its sign bit.
; Arguments:
;   rdi — `result`: 16-byte aligned memory address where the 4 rectified readings are written
;   rsi — `trace`: 16-byte aligned memory address of the readings, with 4 32-bit floating-point numbers
; Returns:
;   None
rectify_trace:
    movdqa xmm0, [rsi]          ; Load the 4 readings into xmm0
    pand xmm0, [abs_mask]       ; Clear the sign bit of each reading using a bitwise AND with the absolute value mask
    movdqa oword [rdi], xmm0    ; Store the rectified readings back to memory
    ret

global reading_scale
; reading_scale function
; Description:
;   This function extracts the unbiased exponent of each reading as a signed 32-bit integer.
;   The exponent field sits at bits 30-23 and is biased by 127.
; Arguments:
;   rdi — `result`: 16-byte aligned memory address where the 4 scales are written, as signed 32-bit integers
;   rsi — `trace`: 16-byte aligned memory address of the readings, with 4 32-bit floating-point numbers
; Returns:
;   None
reading_scale:
    movdqa xmm0, [rsi]      ; Load the 4 readings into xmm0
    pand xmm0, [exp_mask]   ; Clear all bits except the exponent bits using a bitwise AND with the exponent mask
    psrld xmm0, 23          ; Shift the exponent bits down to the least significant bits
    psubd xmm0, [bias]      ; Subtract the bias (127) from each exponent to get the unbiased exponent
    movdqa [rdi], xmm0      ; Store the unbiased exponents back to memory
    ret

global coarsen_displacements
; coarsen_displacements function
; Description:
;   This function divides each signed count by 2^shift, rounding toward negative infinity.
; Arguments:
;   rdi — `result`: 16-byte aligned memory address where the 4 coarsened counts are written
;   rsi — `counts`: 16-byte aligned memory address of the counts, with 4 signed 32-bit integers
;   rdx — `shift`: the power of two to divide by, as a 64-bit unsigned integer between 0 and 31
; Returns:
;   None
coarsen_displacements:
    movdqa xmm0, [rsi]      ; Load the 4 readings into xmm0
    movd xmm1, edx          ; Load shift count into xmm1 low 32 bits (psrad only reads low 32)
    psrad xmm0, xmm1        ; Arithmetic right shift each signed 32-bit lane by shift count, rounding toward negative infinity
    movdqa [rdi], xmm0      ; Store the coarsened counts back to memory
    ret

global gate_channels
; gate_channels function
; Description:
;   This function ORs the two enable masks together, then clears the channels marked faulty.
; Arguments:
;   rdi — `result`: 16-byte aligned memory address where the 4 gated masks are written
;   rsi — `enable_a`: 16-byte aligned memory address of the first enable masks, with 4 unsigned 32-bit integers
;   rdx — `enable_b`: 16-byte aligned memory address of the second enable masks, with 4 unsigned 32-bit integers
;   rcx — `faulty`: 16-byte aligned memory address of the faulty-channel masks, with 4 unsigned 32-bit integers
; Returns:
;   None
gate_channels:
    movdqa xmm0, [rsi]  ; Load the first enable masks into xmm0
    por xmm0, [rdx]     ; OR the two enable masks together
    movdqa xmm1, xmm0   ; Copy the result to xmm1
    pand xmm1, [rcx]    ; AND the result with the faulty-channel masks to isolate the bits that need to be cleared
    pxor xmm0, xmm1     ; Flip the bits in the cleared channels
    movdqa [rdi], xmm0  ; Store the updated enable masks back to memory
    ret

global toggle_calibration
; toggle_calibration function
; Description:
;   This function flips, in each status word, exactly the bits set in the matching toggle mask and not set in the matching lock mask, leaving every other bit untouched.
; Arguments:
;   rdi — `result`: 16-byte aligned memory address where the 4 updated status words are written
;   rsi — `status`: 16-byte aligned memory address of the status words, with 4 unsigned 32-bit integers
;   rdx — `toggle`: 16-byte aligned memory address of the toggle masks, with 4 unsigned 32-bit integers
;   rcx — `locked`: 16-byte aligned memory address of the lock masks, with 4 unsigned 32-bit integers
; Returns:
;   None
toggle_calibration:
    movdqa xmm0, [rsi]  ; Load the status words into xmm0
    movdqa xmm1, [rcx]  ; Load the lock masks into xmm1
    pandn xmm1, [rdx]   ; AND NOT the lock masks with the toggle masks to isolate the bits that can be toggled
    pxor xmm0, xmm1     ; Flip the bits in the toggled channels
    movdqa [rdi], xmm0  ; Store the updated status words back to memory
    ret

global amplify_trace
; amplify_trace function
; Description:
;   Multiplies each reading by 2^gain by adding the gain directly to the exponent field
;   of each float's bit pattern. Sign and mantissa bits are preserved by masking.
; Arguments:
;   rdi — `result`: 16-byte aligned memory address where the 4 amplified readings are written
;   rsi — `trace`:  16-byte aligned memory address of the readings, with 4 32-bit floats
;   rdx — `gains`:  16-byte aligned memory address of the gains, with 4 signed 32-bit integers
; Returns:
;   None
amplify_trace:
    movdqa xmm0, [rsi]           ; Load the 4 readings
    movdqa xmm1, [rdx]           ; Load the 4 gains
    pslld  xmm1, 23              ; Shift gains into the exponent field position

    movdqa xmm2, [exp_mask]      ; Load the exponent mask (bits 30-23)
    pand   xmm2, xmm0            ; xmm2 = exponent bits of each reading, isolated
    paddd  xmm2, xmm1            ; xmm2 = adjusted exponent bits only (gain added safely)

    pand   xmm0, [sign_man_mask] ; xmm0 = sign + mantissa bits of each reading, isolated
    por    xmm0, xmm2            ; xmm0 = recombined: adjusted exponent + original sign/mantissa

    movdqa [rdi], xmm0           ; Store the amplified readings
    ret

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
