default rel

section .text

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           TASK 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global sum_yields
; sum_yields function
; Description:
;   This function takes two 128-bit vectors (each containing four 32-bit floating-point numbers)
;   as input and computes the lane-wise sum of these vectors, storing the result in a third vector
; Arguments:
;   rdi: address of the first input vector (line_a) as 16-byte aligned memory address holding 4 32-bit floating-point numbers
;   rsi: address of the second input vector (line_b) as 16-byte aligned memory address holding 4 32-bit floating-point numbers
;   rdx: address where the result should be stored (result) as 16-byte aligned memory address holding 4 32-bit floating-point numbers
; Returns:
;   None (the result is stored in the memory address pointed to by rdx)
sum_yields:
    movaps xmm0, [rdi]          ; Load the first vector (line_a) into xmm0
    movaps xmm1, [rsi]          ; Load the second vector (line_b) into xmm1
    vaddps xmm2, xmm0, xmm1     ; Compute the lane-wise sum of xmm0 and xmm1, storing the result in xmm2
    movaps oword [rdx], xmm2    ; Store the result from xmm2 into the memory address pointed to by rdx
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           TASK 2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global scaled_deviation
; scaled_deviation function
; Description:
;   This function computes the lane-wise scaled deviation of two vectors of 64-bit floating-point numbers
;   The scaled deviation is defined as (measured - target) * sensitivity
; Arguments:
;   rdi: address of the first input vector (measured) as 16-byte aligned memory address holding 2 64-bit floating-point numbers
;   rsi: address of the second input vector (target) as memory address holding 2 64-bit floating-point numbers (alignment not guaranteed)
;   rdx: address of the third input vector (sensitivity) as memory address holding 2 64-bit floating-point numbers (alignment not guaranteed)
;   rcx: address where the result should be stored (result) as memory address for a buffer where the function will write 2 64-bit floating-point numbers (alignment not guaranteed)
; Returns:
;   None (the result is stored in the memory address pointed to by rcx)
scaled_deviation:
    movapd xmm0, [rdi]          ; Load the first vector (measured) into xmm0
    movupd xmm1, [rsi]          ; Load the second vector (target) into xmm1
    movupd xmm2, [rdx]          ; Load the third vector (sensitivity) into xmm2
    subpd xmm0, xmm1            ; Compute the lane-wise difference (measured - target) and store the result in xmm0
    mulpd xmm0, xmm2            ; Compute the lane-wise product of the difference and sensitivity, storing the result in xmm0
    movupd oword [rcx], xmm0    ; Store the result from xmm0 into the memory address pointed to by rcx
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           TASK 3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section .rodata

align 16
factor: dq 0.5, 0.5

section .text

global calibrate_batch
; calibrate_batch function
; Description:
;   This function performs a calibration on a batch of raw measurements using reference and offset values.
;   The function processes two rows of raw measurements, applying a series of operations to produce calibrated results.
; Arguments:
;   rdi: address of the raw measurements (raw) as memory address holding 4 32-bit floating-point numbers (alignment not guaranteed)
;   rsi: address of the reference values (reference) as 16-byte aligned memory address holding 2 64-bit floating-point numbers
;   rdx: address of the offset values (offset) as 16-byte aligned memory address holding 2 64-bit floating-point numbers
;   rcx: address where the calibrated results should be stored (result) as 16-byte aligned memory address where the function will write 4 64-bit floating-point numbers (32 bytes total)
; Returns:
;   None (the calibrated results are stored in the memory address pointed to by rcx)
calibrate_batch:
    cvtps2pd xmm0, [rdi]        ; Convert the first two raw measurements from 32-bit floating-point to 64-bit floating-point and store in xmm0
    movapd xmm1, [rsi]          ; Load the reference values into xmm1
    movapd xmm2, [rdx]          ; Load the offset values into xmm2
    call .calibrate             ; Call the calibration subroutine to process the first two measurements
    movapd [rcx], xmm0          ; Store the calibrated results of the first two measurements into the memory address pointed to by rcx
    cvtps2pd xmm0, [rdi + 8]    ; Convert the next two raw measurements from 32-bit floating-point to 64-bit floating-point and store in xmm0
    call .calibrate             ; Call the calibration subroutine to process the next two measurements
    movapd [rcx + 16], xmm0     ; Store the calibrated results of the next two measurements into the memory address pointed to by rcx
    ret

.calibrate:
    subpd xmm0, xmm2        ; Compute the lane-wise difference (raw - offset) and store the result in xmm0
    vdivpd xmm0, xmm1, xmm0 ; Compute the lane-wise division (reference / difference) and store the result in xmm0
    mulpd xmm0, [factor]    ; Compute the lane-wise product with the factor and store the result in xmm0
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           TASK 4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global normalize_scores
; normalize_scores function
; Description:
;   This function normalizes a batch of scores using gains and scale values.
; Arguments:
;   rdi: address of the scores (scores) as 16-byte aligned memory address holding `n` 64-bit floating-point numbers (modified in place)
;   rsi: address of the gains (gains) as 16-byte aligned memory address holding `n` 64-bit floating-point numbers
;   rdx: address of the scale values (scale) as 16-byte aligned memory address holding 2 64-bit floating-point numbers
;   rcx: number of scores to normalize (n) as a 64-bit positive even integer (minimum `2`)
; Returns:
;   None (the normalized scores are stored in the memory address pointed to by rdi)
normalize_scores:
    movapd xmm2, [rdx]  ; Load the scale values into xmm2
    xor r8, r8          ; Initialize the loop counter to 0
.normalize:
    cmp rcx, 0                          ; Check if there are no more scores to process
    je .end                             ; If no more scores, jump to the end of the function
    movapd xmm0, [rdi + (r8 * 8)]       ; Load the next 2 scores into xmm0
    movapd xmm1, [rsi + (r8 * 8)]       ; Load the corresponding gains into xmm1
    mulpd xmm0, xmm1                    ; Multiply the scores by their gains
    divpd xmm0, xmm2                    ; Divide by the scale values
    movapd oword [rdi + (r8 * 8)], xmm0 ; Store the normalized scores back into memory
    add r8, 2                           ; Increment the loop counter by 2 (since we're processing 2 scores at a time)
    sub rcx, 2                          ; Decrement the remaining score count by 2
    jmp .normalize                      ; Jump back to the beginning of the loop
.end:
    ret

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
