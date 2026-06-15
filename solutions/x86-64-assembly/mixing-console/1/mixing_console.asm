section .text

global mix_tracks
; mix_tracks function
; Description:
;   This function adds two tracks together, sample by sample, clamping on overflow.
;   A sum outside the signed 16-bit range saturates instead of wrapping.
; Arguments:
;   rdi — `result`: 16-byte aligned memory address where the 8 mixed samples are written
;   rsi — `track_a`: 16-byte aligned memory address of the first track, with 8 signed 16-bit samples
;   rdx — `track_b`: 16-byte aligned memory address of the second track, with 8 signed 16-bit samples
; Returns:
;   None
mix_tracks:
    movdqa xmm0, [rsi]          ; Load 8 signed 16-bit samples from track_a into xmm0
    paddsw xmm0, [rdx]          ; Add the corresponding samples in xmm0 and rdx, with saturation
    movdqa oword [rdi], xmm0    ; Write the result to the output memory location
    ret

global remove_bleed
; remove_bleed function
; Description:
;   This function subtracts the bleed block from the track block, sample by sample, clamping on overflow.
;   A difference outside the signed 16-bit range saturates instead of wrapping.
; Arguments:
;   rdi — `result`: memory address where the 8 cleaned samples are written (alignment not guaranteed)
;   rsi — `track`: 16-byte aligned memory address of the recorded track, with 8 signed 16-bit samples
;   rdx — `bleed`: memory address of the bleed to remove, with 8 signed 16-bit samples (alignment not guaranteed)
; Returns:
;   None
remove_bleed:
    movdqa xmm0, [rsi]          ; Load 8 signed 16-bit samples from track into xmm0
    psubsw xmm0, [rdx]          ; Subtract the corresponding samples in xmm0 and rdx, with saturation
    movdqa oword [rdi], xmm0    ; Write the result to the output memory location
    ret

global combine_meters
; combine_meters function
; Description:
;   This function adds two meter blocks together, value by value, clamping on overflow.
;   A sum outside the unsigned 8-bit range saturates instead of wrapping.
; Arguments:
;   rdi — `result`: 16-byte aligned memory address where the 16 combined values are written
;   rsi — `meter_a`: 16-byte aligned memory address of the first meter block, with 16 unsigned 8-bit values
;   rdx — `meter_b`: 16-byte aligned memory address of the second meter block, with 16 unsigned 8-bit values
; Returns:
;   None
combine_meters:
    movdqu xmm0, [rsi]          ; Load 16 unsigned 8-bit values from meter_a into xmm0
    paddusb xmm0, [rdx]         ; Add the corresponding values in xmm0 and rdx, with saturation
    movdqa oword [rdi], xmm0    ; Write the result to the output memory location
    ret

global apply_fade
; apply_fade function
; Description:
;   This function scales each sample by its gain coefficient.
;   Each coefficient is a fraction over `65536`, so the scaled sample is the high 16 bits of the signed product `sample * gain`.
; Arguments:
;   rdi — `result`: 16-byte aligned memory address where all the scaled samples are written
;   rsi — `track`: 16-byte aligned memory address of the track, with `n` signed 16-bit samples
;   rdx — `gains`: 16-byte aligned memory address of the gain coefficients, with `n` signed 16-bit values
;   rcx — `n`: the number of samples, always a multiple of `8`, as a 64-bit unsigned integer
; Returns:
;   None
apply_fade:
    xor r8, r8  ; Initialize the loop counter to 0
.fade:
    cmp r8, rcx                     ; Compare the loop counter with the number of samples
    je end                          ; If equal, exit the loop
    movdqa xmm0, [rsi + r8*2]       ; Load 8 signed 16-bit samples from track into xmm0
    pmulhw xmm0, [rdx + r8*2]       ; Multiply the corresponding samples in xmm0 and rdx, keeping the high 16 bits of each product
    movdqa oword [rdi + r8*2], xmm0 ; Write the result to the output memory location
    add r8, 8                       ; Increment the loop counter
    jmp .fade                       ; Jump back to the beginning of the loop

global attenuate_track
; attenuate_track function
; Description:
;   This function divides each sample by a constant divisor.
;   Integer SIMD has no packed division, so divide in packed floating-point and convert the quotient back to a 32-bit integer, truncating toward zero.
; Arguments:
;   rdi — `result`: 16-byte aligned memory address where the results are written, as 32-bit signed integers
;   rsi — `samples`: 16-byte aligned memory address of the samples, with `n` signed 16-bit values
;   rdx — `divisor`: 16-byte aligned memory address of 4 identical copies of the divisor, as 32-bit integers
;   rcx — `n`: the number of samples, always a multiple of `4`, as a 64-bit unsigned integer
; Returns:
;   None
attenuate_track:
    xor r8, r8              ; Initialize the loop counter to 0
    cvtdq2ps xmm1, [rdx]    ; Convert the divisor from 4 32-bit integers to 4 single-precision floats, for use in the division
.attenuate:
    cmp r8, rcx                     ; Compare the loop counter with the number of samples
    je end                          ; If equal, exit the loop
    pmovsxwd xmm0, [rsi + r8*2]     ; Load 4 signed 16-bit samples from track into xmm0, extending them to 32 bits
    cvtdq2ps xmm0, xmm0             ; Convert the samples from 4 32-bit integers to 4 single-precision floats, for use in the division
    divps xmm0, xmm1                ; Divide the corresponding samples in xmm0 by the divisor in xmm1, producing 4 single-precision floats
    cvttps2dq xmm0, xmm0            ; Convert the quotient from 4 single-precision floats back to 4 signed 32-bit integers, truncating toward zero
    movdqa oword [rdi + r8*4], xmm0 ; Write the result to the output memory location
    add r8, 4                       ; Increment the loop counter
    jmp .attenuate                  ; Jump back to the beginning of the loop

end:
    ret

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
