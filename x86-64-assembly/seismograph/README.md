# Seismograph

Welcome to Seismograph on Exercism's x86-64 Assembly Track.
If you need help running the tests or submitting your code, check out `HELP.md`.
If you get stuck on the exercise, check out `HINTS.md`, but try and solve it without using those first :)

## Introduction

## SIMD: Bitwise

There are packed variants for most scalar bitwise operations.
They follow the same general syntax as SIMD integer operations, but they have no size suffix:

| instruction | description                       |
|-------------|-----------------------------------|
| `pand`      | bitwise AND of two 128-bit values |
| `por`       | bitwise OR of two 128-bit values  |
| `pxor`      | bitwise XOR of two 128-bit values |

Note that there is no packed `NOT`.
However, there is an ANDN operation, which negates the **destination** operand and then calculates the AND between both operands.
It can be thought of as a NOT combined with an AND:

| instruction | description                                                |
|-------------|------------------------------------------------------------|
| `pandn`     | bitwise AND of the **negated** destination with the source |

Note that a bitwise operation combines bits at the same position in two different operands, so lane boundaries cannot change the result.
This is why these instructions do not have a size suffix, the register behaves as a single 128-bit lane:

```x86asm
pand xmm0, xmm1   ; xmm0 = xmm0 AND xmm1
por  xmm2, xmm3   ; xmm2 = xmm2 OR xmm3
pxor xmm4, xmm5   ; xmm4 = xmm4 XOR xmm5
pandn xmm6, xmm7  ; xmm6 = (NOT xmm6) AND xmm7
```

~~~~exercism/note
All instructions in this concept compute bits but set no flags.
A later concept will address conditionals with packed values.
~~~~

### Per-Lane Shifts

Shifts, unlike the pure bitwise operations, do move bits across positions, so they need a lane size to set a boundary.
Within each lane they behave like their scalar counterparts, and bits never cross from one lane into a neighbor:

| instruction               | description                         |
|---------------------------|-------------------------------------|
| `psllw`, `pslld`, `psllq` | shift left logical, per lane        |
| `psrlw`, `psrld`, `psrlq` | shift right logical, per lane       |
| `psraw`, `psrad`          | shift right arithmetic, per lane    |

Note that these instructions follow the syntax for packed integer operations, including a size suffix.
There is no byte shift, only word, dword and, with the exception of shift right arithmetic, qword.

One difference between packed shifts and their scalar counterparts is in the operation name:

- Instead of `shl` and `shr`, we have `sll` and `srl`, for **s**hift **l**eft (**r**ight) **l**ogical.
- Instead of `sar`, we have `sra`, for **s**hift **r**ight **a**rithmetic.

Although the name is different, the operation is the same:

- A logical right shift fills the uppermost bits with zero.
  It is equivalent to an unsigned division by a power of two.
- An arithmetic right shift fills the uppermost bits with the value of the sign bit.
  It is equivalent to a signed division by a power of two, rounding toward negative infinity.
- A shift to the left always fills with zero (this is why there is no need for a shift left arithmetic).

The shift count is the same for every lane.
It can be an immediate, or the low 64 bits of an `xmm` register:

```x86asm
pslld xmm0, 4      ; each 32-bit lane shifted left by 4
psrlw xmm1, 1      ; each 16-bit lane shifted right by 1, zero-filled
psrad xmm2, xmm3   ; each 32-bit lane shifted right by the count in xmm3, sign-filled
```

~~~~exercism/note
A shift count larger than the lane width does not wrap around like the scalar `shl`/`shr` family.
It simply produces zero (or all sign bits, for shift right arithmetic).
~~~~

### Floating-Point Bitwise Operations

Each bitwise instruction also has float-named twins, following the same syntax we have seen for packed floating-point operations:

| integer name | float names          |
|--------------|----------------------|
| `pand`       | `andps`, `andpd`     |
| `pandn`      | `andnps`, `andnpd`   |
| `por`        | `orps`, `orpd`       |
| `pxor`       | `xorps`, `xorpd`     |

Since bitwise operations act on bits, in practice integer and floating-point operations compute the same result.
The different names exist for two reasons:

1. Documenting the intent, in the same way as we would prefer `movdqa`, `movaps` or `movapd` according to the nature of the bytes being copied.
2. Integer and floating-point operations often have different execution domains.
   Operations within the same execution domain can usually be sequenced faster.

There is no shift operation for floating-point values.

### Floating-Point Bit Representation

An IEEE floating-point number has a very different bit representation from an integer.

In an unsigned integer, each bit has a uniform meaning: it represents a power of two corresponding to the bit index.
The integer is the sum of the powers of two corresponding to the set bits.
This is why shifting the bits can multiply or divide the number by a power of two: we are just changing the index of each set bit.

In a signed integer, most bits are interpreted in the same way as in an unsigned integer.
However, the uppermost bit is special.
If it is set, instead of being added to the others, we have to subtract the corresponding power of two, which results in a negative number.
In practice, to change the sign of a number, we would conceptually need two steps: flipping all bits (a `not`) and then adding 1 to the result (an `inc`).

Bits in floating-point numbers do not have a uniform meaning and they need to be interpreted in very different ways according to their position:

| field    | indexes (32-bit) | indexes (64-bit) |
|----------|------------------|------------------|
| sign     | 31               | 63               |
| exponent | 30-23            | 62-52            |
| fraction | 22-0             | 51-0             |

The resulting number is calculated by `(-1)^sign * 1.fraction * 2^(exponent - bias)`.
The bias depends on the precision:

| size   | bias |
|--------|------|
| 32-bit | 127  |
| 64-bit | 1023 |

In both formats, the sign of the number is exclusively determined by the sign bit.
Changing the sign of a floating-point number is achieved by just flipping this bit (an XOR operation).
Getting the absolute value is achieved by just clearing it (an AND where the bit is cleared):

```x86asm
section .rodata
align 16
abs_mask:  dd 0b0_11111111_11111111111111111111111, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF ; same number in binary and hexadecimal
sign_mask: dd 0b1_00000000_00000000000000000000000, 0x80000000, 0x80000000, 0x80000000 ; same number in binary and hexadecimal

section .text
fn:
  andps xmm0, [rel abs_mask]  ; absolute value: clear the sign bit of all 4 floats
  xorps xmm1, [rel sign_mask] ; negation: flip the sign bit of all 4 floats
  ...
```

Note that in this bit representation, shifting bits does not have a predictable and uniform result.
The fraction can "spill" into the exponent and the exponent, into the sign.

However, it is sometimes convenient to isolate the different parts of the representation to operate on them.

For example, the bits in the exponent should first be interpreted as an unsigned number, before the bias is subtracted from it.
This means we can produce a 32-bit or 64-bit integer whose underlying bit representation corresponds to some power of two in the corresponding floating-point format.
Then this raw bit representation can be used to multiply or divide some other floating-point number.

For example:

```x86asm
mov eax, 210             ; in the exponent position, this would be 2^(210 - 127) = 2^83 in a 32-bit floating-point number
shl eax, 23              ; the bits are now in the correct position for the exponent of a 32-bit floating-point number
movd xmm0, eax           ; we move the raw bits to xmm0
mulss xmm1, xmm0         ; we are multiplying a 32-bit floating-point number in xmm1 by 2^83
```

Conversely, we could extract the exponents of packed floating-point numbers by performing an AND with a mask where the exponent bits are set and all others are cleared.
Combined with a shift and a subtraction, this produces the unbiased exponent of every lane as a signed integer:

```x86asm
section .rodata
align 16
exp_mask: dd 0b0_11111111_00000000000000000000000, 0x7F800000, 0x7F800000, 0x7F800000 ; same number in binary and hexadecimal
bias: dd 127, 127, 127, 127

section .text
fn:
  movdqa xmm0, [rel values]   ; 4 packed 32-bit floating-point numbers
  pand   xmm0, [rel exp_mask] ; keep bits 30-23
  psrld  xmm0, 23             ; slide the exponent field to the bottom of each lane
  psubd  xmm0, [rel bias]     ; remove the bias
  ...
```

~~~~exercism/caution
Operating on the raw bits of floating-point numbers, while useful in some situations, should be done with caution.
Adding to, or subtracting from, the exponent field is only safe if there is no over or underflow and if the input number is normal.
Also, adding a valid `x` to the exponent field of `0.0` results in `2^(x - bias)`, not in `0.0 * 2^x`.
~~~~

## Instructions

You maintain the processing station of a seismograph array, a network of sensors that record how the ground moves.

Readings arrive as blocks of values.
Some are ground displacements stored as 32-bit floating-point numbers, others are raw counts and status words stored as 32-bit integers.
The station processes a whole block at once, applying the same operation to each value.

You have six tasks, each operating on a block of values held in memory.
You receive the operands through memory addresses and write your answer through a result address.
All memory addresses in this exercise are 16-byte aligned.

~~~~exercism/note
The computations in this exercise should be performed using SIMD bitwise operations and shifts, not scalar operations.
~~~~

## 1. Rectify the trace

For magnitude analysis, only the size of each ground displacement matters, not its direction.
The first processing step folds every reading to a non-negative value.

Implement the `rectify_trace` function, which computes the absolute value of each reading.
A block holds 4 readings, each a 32-bit floating-point number.

This function takes as arguments, in this order:

- `result`: memory address for a buffer where the 4 rectified readings are written.
- `trace`: memory address of the recorded readings, with 4 values, each a 32-bit floating-point number.

```c
trace  = {1.5, -2.25, 0.0, -135.75}
result = {1.5,  2.25, 0.0,  135.75}
```

This function has no return value.

## 2. Read the scale of a tremor

Analysts grade tremors by their power of two: a reading near `8.0` sits at scale `3`, a reading near `0.25` sits at scale `-2`.
That scale is already stored inside each floating-point number, as its exponent field.

A 32-bit floating-point number is laid out as a sign bit at bit 31, an 8-bit exponent at bits 30 to 23, and a 23-bit fraction at bits 22 to 0.
The stored exponent is biased by 127, so the value of the number is `(-1)^sign * 1.fraction * 2^(exponent - 127)`.

Implement the `reading_scale` function, which extracts the unbiased exponent of each reading as a signed 32-bit integer.

This function takes as arguments, in this order:

- `result`: memory address for a buffer where the 4 scales are written, each a signed 32-bit integer.
- `trace`: memory address of the rectified readings, with 4 values, each a 32-bit floating-point number.

```c
trace  = {8.0, 0.25, 1.0, 13.5}
result = {  3,   -2,   0,   3}
```

This function has no return value.
All readings are normal, non-zero floating-point numbers.

## 3. Coarsen the resolution

For long-term storage, raw displacement counts are kept at a coarser resolution: each count is divided by a power of two.

Displacement counts are signed: the ground can move both ways.
Dividing them correctly takes the shift that preserves the sign.

Implement the `coarsen_displacements` function, which divides each signed count by `2^shift`, rounding toward negative infinity.

This function takes as arguments, in this order:

- `result`: memory address for a buffer where the 4 coarsened counts are written, each a signed 32-bit integer.
- `counts`: memory address of the raw counts, with 4 signed 32-bit integers.
- `shift`: the power of two to divide by, as a 64-bit unsigned integer between `0` and `31`.

```c
counts = {1024, -1024, 25, -25}
shift  = 3
result = { 128,  -128,  3,  -4}
```

~~~~exercism/note
The instruction `movq` may be used to copy a 64-bit integer from a general-purpose register to an `xmm` register without changing the underlying bit representation.
~~~~

This function has no return value.

## 4. Gate the channels

Each station merges two recording campaigns and then silences the channels its hardware report marks as faulty.
Each block holds 4 channel masks, each an unsigned 32-bit integer, where every bit represents one channel: `1` enabled, `0` disabled.

Implement the `gate_channels` function, which combines the channels enabled in either campaign, then clears every channel marked faulty.

This function takes as arguments, in this order:

- `result`: memory address for a buffer where the 4 gated masks are written, each an unsigned 32-bit integer.
- `enable_a`: memory address of the first campaign's enable masks, with 4 unsigned 32-bit integers.
- `enable_b`: memory address of the second campaign's enable masks, with 4 unsigned 32-bit integers.
- `faulty`: memory address of the faulty-channel masks, with 4 unsigned 32-bit integers.

```c
enable_a = {0b1100, 0b0001, 0b1111, 0b0000}
enable_b = {0b0110, 0b0001, 0b0000, 0b0000}
faulty   = {0b0100, 0b0011, 0b1001, 0b1111}
result   = {0b1010, 0b0000, 0b0110, 0b0000}
```

This function has no return value.

## 5. Toggle the calibration bits

Once a day the station runs a calibration pass, flipping a chosen set of configuration bits in each status word and leaving every other bit untouched.
But some bits are locked by the hardware and must never change, no matter what the pass requests.
Running the same pass twice restores the original configuration.

Implement the `toggle_calibration` function, which flips, in each status word, exactly the bits that are set in the matching toggle mask and not set in the matching lock mask.

This function takes as arguments, in this order:

- `result`: memory address for a buffer where the 4 updated status words are written, each an unsigned 32-bit integer.
- `status`: memory address of the current status words, with 4 unsigned 32-bit integers.
- `toggle`: memory address of the toggle masks, with 4 unsigned 32-bit integers.
- `locked`: memory address of the lock masks, with 4 unsigned 32-bit integers.

```c
status = {0b1100, 0b0001, 0b1111, 0b1010}
toggle = {0b0110, 0b0011, 0b1111, 0b1010}
locked = {0b0010, 0b0001, 0b1100, 0b0000}
result = {0b1000, 0b0011, 0b1100, 0b0000}
```

This function has no return value.

## 6. Amplify the trace

Each channel of the array has its own gain trim, expressed as a power of two: a gain of `3` multiplies the channel's reading by `8`, a gain of `-5` divides it by `32`.

The station applies these gains without a single multiplication, by manipulating the exponent field of each floating-point number.

Implement the `amplify_trace` function, which multiplies each reading by `2` raised to its channel's gain, operating only on the raw bits.

This function takes as arguments, in this order:

- `result`: memory address for a buffer where the 4 amplified readings are written.
- `trace`: memory address of the readings, with 4 values, each a 32-bit floating-point number.
- `gains`: memory address of the per-channel gains, with 4 signed 32-bit integers.

```c
trace  = {1.5, -2.0, 0.25, 96.0}
gains  = {  2,    1,    3,   -5}
result = {6.0, -4.0,  2.0,  3.0}
```

This function has no return value.
All readings are normal, non-zero floating-point numbers, and every amplified result is also normal.

## Source

### Created by

- @oxe-i