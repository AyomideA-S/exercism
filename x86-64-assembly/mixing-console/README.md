# Mixing Console

Welcome to Mixing Console on Exercism's x86-64 Assembly Track.
If you need help running the tests or submitting your code, check out `HELP.md`.
If you get stuck on the exercise, check out `HINTS.md`, but try and solve it without using those first :)

## Introduction

## SIMD: Integers

A previous concept introduced packed floating-point values: multiple numbers held in one `xmm` register, operated on lane-wise and in parallel.
The same `xmm` registers can also hold packed _integers_.

### Syntax

Most of the SIMD floating-point model carries over unchanged to packed integer:

- A 128-bit register is divided into lanes
- Instructions act on lanes at the same position in parallel
- Memory operands follow the same 16-byte alignment rules

However, the syntax is slightly different:

1. A _prefix_ `p` to indicate that the instruction operates on _packed_ data.
2. The operation being performed, with the same name as their non-SIMD (also called _scalar_) counterpart (e.g., `add`, `mul`, etc.).
3. A suffix to indicate the size of each lane.

Packed integers have four lane sizes, and each has its own suffix:

| lane width | bytes | lanes in 128 bits | suffix |
|------------|-------|-------------------|--------|
| byte       | 1     | 16                | b      |
| word       | 2     | 8                 | w      |
| dword      | 4     | 4                 | d      |
| qword      | 8     | 2                 | q      |

For example:

| instruction | meaning                              |
|-------------|--------------------------------------|
| `paddb`     | packed `add`, 8-bit lanes (16 lanes) |
| `paddw`     | packed `add`, 16-bit lanes (8 lanes) |
| `paddd`     | packed `add`, 32-bit lanes (4 lanes) |
| `paddq`     | packed `add`, 64-bit lanes (2 lanes) |

Some instructions take lanes with one size as input, but another size as output.
They follow the same general convention, but with _two_ size suffixes.
The first indicates the size of the input lane, the second indicates the size of the output lane:

| instruction  | meaning                                           |
|--------------|---------------------------------------------------|
| `pmovsxwd`   | packed `movsx`, from 16-bit lanes to 32-bit lanes |
| `pmuldq`     | packed `mul`, from 32-bit lanes to 64-bit lanes   |

### Memory Moves

Two integer-named instructions copy 128 bits between an `xmm` register and memory:

| instruction | description                                             |
|-------------|---------------------------------------------------------|
| `movdqa`    | copy packed integers to or from an _aligned_ location   |
| `movdqu`    | copy packed integers to or from an _unaligned_ location |

They behave like `movaps` and `movups`: `movdqa` faults on a misaligned address, while `movdqu` accepts any.
All four copy 128 bits without interpreting them.
The integer-named pair is used with integer data by convention, not by requirement.

~~~~exercism/note
`dq` here stands for `double-qword`, i.e., 128 bits (16 bytes).
~~~~

### Addition/Subtraction

Addition and subtraction follow the naming rule:

```x86asm
paddb xmm0, xmm1 ; 16 lanes: each  8-bit, xmm0 += xmm1
paddw xmm2, xmm3 ;  8 lanes: each 16-bit, xmm2 += xmm3

psubd xmm4, xmm5 ;  4 lanes: each 32-bit, xmm4 -= xmm5
psubq xmm6, xmm7 ;  2 lanes: each 64-bit, xmm6 -= xmm7
```

There is no separate signed and unsigned form.
In two's complement, addition and subtraction produce the same bits whether the lanes are read as signed or unsigned, so one instruction serves both.
The interpretation is yours to make, exactly as with scalar `add` and `sub`.

These instructions **wrap around** on overflow, like their scalar counterparts.
An 8-bit lane holds values modulo 256, so a `paddb` of `200 + 100` produces `300 - 256 = 44`, discarding the bits that do not fit.

Note that those extra bits do not carry over to the next lane.
Each lane is operated on separately from the other, even though they share the same register.

### Saturating Addition/Subtraction

Integer SIMD adds an operation that floating-point SIMD does not have: **saturating** addition and subtraction, which _clamp_ instead of wrapping.
A result above the lane's range becomes the largest value the lane can hold; a result below the range becomes the smallest.

The saturating forms insert `s` (signed) or `us` (unsigned) before the size suffix:

| instruction | meaning                                    |
|-------------|--------------------------------------------|
| `paddsb`    | `add`, saturating, signed 8-bit lanes      |
| `paddusb`   | `add`, saturating, unsigned 8-bit lanes    |
| `psubsw`    | `sub`, saturating, signed 16-bit lanes     |
| `psubusw`   | `sub`, saturating, unsigned 16-bit lanes   |

The clamp range is the full representable range for an integer of the corresponding size and signedness.
For a byte:

- Unsigned bytes clamp to `[0, 255]`: a `paddusb` of `200 + 100` gives `255`, and a `psubusb` of `5 - 10` gives `0`.
- Signed bytes clamp to `[-128, 127]`: a `paddsb` of `100 + 50` gives `127`.

Saturation matters when a lane holds a bounded quantity, such as a pixel channel or an audio sample.
Wrap-around would turn a too-bright pixel dark, whereas clamping keeps it at maximum brightness, which is the result you want.

~~~~exercism/note
Saturating add and subtract exist only for byte and word lanes, not for dword or qword.
~~~~

### Multiplication

Multiplying two N-bit values can produce a 2N-bit product, but the destination lane is only N bits wide.
SIMD operations resolve this by specifying which half of the product to keep, either the low N bits, or the upper N bits.

For 16-bit lanes, three instructions are used:

| instruction | meaning                                                       |
|-------------|---------------------------------------------------------------|
| `pmullw`    | `mul`, 16-bit lanes, keep the low 16 bits of each product     |
| `pmulhw`    | `mul`, 16-bit lanes, keep the high 16 bits, signed operands   |
| `pmulhuw`   | `mul`, 16-bit lanes, keep the high 16 bits, unsigned operands |

The low 16 bits of a product are the same whether the operands are read as signed or unsigned, so there is a single `pmullw`.

The upper 16 bits, however, vary according to the signedness of the result.
This is why the high-half multiply has separate forms for signed and unsigned multiplication:

1. `pmulhw`, for signed multiplication.
2. `pmulhuw`, with an extra `u`, for unsigned multiplication.

Note the syntax:

1. A `p`, for packed integer.
2. The operation being performed, `mul`.
3. A `h`, to indicate that the upper ("high") bits of the result are being selected.
4. An optional `u` if the result should be interpreted as unsigned (i.e., it is not sign extended).
5. Finally, the size suffix `w`, to indicate it is a word (16-bit) operation.

Packed multiplication for words follows the rule above exactly.
Dword (32-bit) multiplication also follows the rule, but there is only the variant which selects the low half: `pmulld`.

There is no variant for dword multiplication that selects the high bits.
However, there are variants that _widen_ the multiplication, storing the full 64-bit product of _even-indexed_ lanes (i.e., the lanes at position 0 and 2):

| instruction | meaning                                                                          |
|-------------|----------------------------------------------------------------------------------|
| `pmuludq`   | multiply the even-indexed 32-bit elements, unsigned, into 2 full 64-bit products |
| `pmuldq`    | multiply the even-indexed 32-bit elements, signed, into 2 full 64-bit products   |

Note the syntax uses `dq`, possibly with an `u` before it for unsigned multiplication.
This is because the instructions take `dword` lanes and output `qword` lanes.

### Division

There is no packed integer division.
Code that needs it converts the values to floating-point, divides, and converts back.

### Widening Integers

There are packed equivalents for `movsx` and `movzx`.
They follow the same syntax we mentioned for instructions that take inputs with a different lane size than their output:

```x86asm
pmovsxwd xmm0, xmm1   ; 4 words -> 4 dwords, sign-extended
pmovzxbw xmm0, xmm1   ; 8 bytes -> 8 words, zero-extended
```

Note that the number of lanes is set by the larger (output) width.
The instruction reads that many lanes from the low part of the source.
This is the same semantics we have already seen for packed `cvt` instructions between single and double-precision floats.

### Converting Between Integers and Floats

There are instructions to convert between 32-bit signed integers and floating-point lanes.
They follow the usual syntax for `cvt` and `cvtt` instructions, but instead of `si` a packed integer is represented by `dq`:

```x86asm
cvtdq2ps xmm0, xmm1 ; convert 32-bit signed integers in xmm1 to 32-bit floats in xmm0
cvtdq2pd xmm2, xmm3 ; convert 32-bit signed integers in xmm3 to 64-bit floats in xmm2
cvtps2dq xmm4, xmm5 ; convert 32-bit floats in xmm5 to 32-bit signed integers in xmm4
```

~~~~exercism/caution
The instructions that use `pi` to represent packed integers write to legacy `mmx` registers and are effectively deprecated on x86-64.
Prefer the `dq` forms, which use `xmm` registers.
~~~~

The same comments made for scalar conversion between floating-point numbers and integers are valid here.
Floating-point numbers are rounded according to a special register called MXCSR, whose mode you cannot assume on function entry.
There is a `cvtt` variant (with an extra `t`) that always truncates the result.

It is also possible to use `round` to have packed floating-point values in a known state before converting.
The round control value is the same as the scalar `round` and the syntax is also the same for packed floating-point values:

```x86asm
roundps xmm0, xmm1, 1 ; xmm0 = floor(xmm1), packed 32-bit floats
roundpd xmm2, xmm3, 2 ; xmm2 = ceil(xmm3), packed 64-bit floats
```

## Instructions

You are writing the digital core of a small mixing console at a recording studio.

Sound arrives as a stream of samples.
Each sample is a number describing the position of a loudspeaker cone at one instant.
A console processes a whole block of samples at once, applying the same operation to each.

You have five tasks, each operating on a block of samples held in memory.
You receive the operands through memory addresses and write your answer through a result address.

~~~~exercism/note
The computations in this exercise should be performed using SIMD instructions, not scalar operations.
~~~~

## 1. Mix two tracks

The studio sometimes records instruments on different tracks.
To play them through the same speakers, you sum the two tracks into one.

Implement the `mix_tracks` function, which adds two tracks together, sample by sample.
Each track is a block of 8 signed 16-bit samples.
A sum that overflows the signed 16-bit range must clamp instead of wrapping.

This function takes as arguments, in this order:

- `result`: 16-byte aligned memory address for a buffer where the 8 mixed samples are written.
- `track_a`: 16-byte aligned memory address of the first track, with 8 signed 16-bit samples.
- `track_b`: 16-byte aligned memory address of the second track, with 8 signed 16-bit samples.

```c
track_a = {10000, 30000, 20000, -30000, -20000, -100,  100, 0}
track_b = { 5000,  5000, 20000,  -5000, -20000,  100, -100, 0}
result  = {15000, 32767, 32767, -32768, -32768,    0,    0, 0}
```

This function has no return value.

## 2. Remove bleed

When two microphones record at once, each one picks up a faint copy of the other's source.
This unwanted copy is called _bleed_.
Once this bleed is measured, it must be subtracted back out to clean up the track.

Implement the `remove_bleed` function, which subtracts the bleed block from the track block, sample by sample.
Each block is 8 signed 16-bit samples, and the subtraction must saturate.

This function takes as arguments, in this order:

- `result`: memory address where the 8 cleaned samples are written (alignment not guaranteed).
- `track`: 16-byte aligned memory address of the recorded track, 8 signed 16-bit samples.
- `bleed`: memory address of the bleed to remove, 8 signed 16-bit samples (alignment not guaranteed).

```c
track  = {10000, -30000, 5000, 32767, 0,  200, -200, 15000}
bleed  = { 2000,   5000, 5000,    -5, 0,  300,  300,  5000}
result = { 8000, -32768,    0, 32767, 0, -100, -500, 10000}
```

This function has no return value.

## 3. Combine meters

Above each channel sits a level meter, a little bar whose brightness shows how loud that channel is.
The front panel has one master meter that should glow as brightly as the two channels combined.
You add the two meter blocks to drive it.

Note that a bright meter stays at full brightness rather than wrapping back to dark, so the sum is saturating.

Implement the `combine_meters` function, which adds two meter blocks sample by sample.
This function takes as arguments, in this order:

- `result`: 16-byte aligned memory address where the 16 combined values are written.
- `meter_a`: 16-byte aligned memory address of the first channel's meter block, with 16 packed unsigned 8-bit values.
- `meter_b`: 16-byte aligned memory address of the second channel's meter block, with 16 packed unsigned 8-bit values.

Each block is 16 unsigned 8-bit values.
They should be added together, saturating to the unsigned range.

```c
meter_a = {200, 100,  50, 255, 0, 128, 10, 240, 1, 2, 3, 4, 5, 6, 7, 8}
meter_b = {100, 100, 200,   1, 0, 128, 10,  20, 1, 2, 3, 4, 5, 6, 7, 8}
result  = {255, 200, 250, 255, 0, 255, 20, 255, 2, 4, 6, 8, 10, 12, 14, 16}
```

This function has no return value.

## 4. Apply a fade

The song should not stop abruptly, but fade out at the end.
You have a block of _gain coefficients_, one per sample, that taper from quieter to quieter still.

Each coefficient is a fraction expressed over `65536`.
For example, if a sample has a value of `16384`, it actually expresses `16384 / 65536`, which is `1 / 4`.
The largest usable value, `32767`, is just under one half.

Since `65536` is `2^16`, multiplying a sample by its coefficient and keeping the _high half_ of the product gives `sample * gain / 65536`.

Implement the `apply_fade` function, which scales each sample by its coefficient.
This function takes as arguments, in this order:

- `result`: 16-byte aligned memory address where all the scaled samples are written.
- `track`: 16-byte aligned memory address of the track, with `n` signed 16-bit samples.
- `gains`: 16-byte aligned memory address of the gain coefficients, with `n` signed 16-bit values, each in the range `0` to `32767`.
- `n`: the number of samples, which is always non-zero and a multiple of `8`, as a 64-bit unsigned integer.

Note that the track is an array that holds `n` signed 16-bit samples, where `n` is never zero and always a multiple of `8`.
For each sample, the scaled result is the _high_ 16 bits of the signed product: `sample * gain`.

```c
track  = {20000, 20000, 20000, 20000, -20000, -20000, -20000, -20000}
gains  = {32767, 24576, 16384,  8192,  32767,  24576,  16384,   8192}
result = { 9999,  7500,  5000,  2500, -10000,  -7500,  -5000,  -2500}
```

~~~~exercism/note
Keeping the high half rounds toward negative infinity.
This is why `20000 * 32767` scales to `9999`, while `-20000 * 32767` scales to `-10000` rather than `-9999`.
~~~~

This function has no return value.

## 5. Attenuate a track

The drummer was recorded far too loud.
To bring the whole track down, you divide every sample by a constant.

Implement the `attenuate_track` function.
This function takes as arguments, in this order:

- `result`: 16-byte aligned memory address where the results are written, as 32-bit signed integers.
- `samples`: 16-byte aligned memory address of the samples, `n` signed 16-bit values.
- `divisor`: 16-byte aligned memory address of 4 identical copies of the divisor, as 32-bit integers.
- `n` is the number of samples, which is always non-zero and a multiple of `4`, as a 64-bit unsigned integer.

Note that `samples` is an array that holds `n` signed 16-bit samples, where `n` is never zero and always a multiple of `4`.

The divisor is supplied as `4` copies of the same 32-bit integer, already replicated so it can fill all four lanes at once.

Integer SIMD has no packed division, so the work is done in packed floating-point, and then converted back to packed 32-bit integers to be stored in `result`.
Convert back by truncating toward zero, so a quotient of `2.3` becomes `2` and `-2.3` becomes `-2`.

```c
samples = {300, 150, 90, -120, 100, 50, -50, 7}
divisor = {3, 3, 3, 3}
result  = {100,  50, 30,  -40,  33, 16, -16, 2}
```

This function has no return value.

## Source

### Created by

- @oxe-i