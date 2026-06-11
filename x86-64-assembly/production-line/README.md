# Production Line

Welcome to Production Line on Exercism's x86-64 Assembly Track.
If you need help running the tests or submitting your code, check out `HELP.md`.
If you get stuck on the exercise, check out `HINTS.md`, but try and solve it without using those first :)

## Introduction

## SIMD

**Single instruction, multiple data (SIMD)** is a form of hardware-level parallelism.
The same computation is performed by the CPU over multiple elements at the same time.

Consider, for example, summing two arrays of four 32-bit floats element-wise.
A scalar implementation would issue four separate `addss` instructions, one per element.
A SIMD implementation uses a single `addps` to do all four additions in parallel.
That gives four times the work per instruction.

In x86-64 assembly, SIMD instructions are typically performed using `xmm` registers.
Some of those instructions operate on integers.
Others operate on floating-point numbers.

Those integers or floating-point numbers are called **packed**.
Each occupies a space, called a **lane**, within the same register.
SIMD instructions typically operate in parallel on values at the same lane position across two source operands.
The result of each operation is stored in the lane at the same position in the destination operand.

A lane is not a hard limit.
It is an interpretation given by each instruction to a sequence of bytes.
A 128-bit operand contains 16 bytes.
Depending on the instruction, those bytes can be interpreted as 16 _1-byte_ lanes, 8 _2-byte_ lanes, 4 _4-byte_ lanes, 2 _8-byte_ lanes, or even a single _16-byte_ lane.

For example, the instruction `addps` adds packed single-precision (4-byte) floating-point values.
For this instruction, each 4-byte chunk in an operand is a different lane.
In a 128-bit wide (16-byte) operand:

| operand     | 4th lane | 3rd lane | 2nd lane | 1st lane |
|:-----------:|:--------:|:--------:|:--------:|:--------:|
| source 1    |  1.5     |  2.1     | 6.2      | 3.4      |
|    +        |  +       |  +       | +        | +        |
| source 2    |  0.5     |  8.26    | -13.4    | 22.9     |
|    =        |  =       |  =       | =        | =        |
| result      |  2.0     |  10.36   | -7.2     | 26.3     |

On the other hand, a 128-bit operand would be interpreted as having 2 lanes in the case of `mulpd`.
This is because this instruction performs packed multiplication on double-precision (8-byte) values:

| operand     | 2nd lane | 1st lane |
|:-----------:|:--------:|:--------:|
| source 1    |  4.2     |  2.1     |
|    *        |  *       |  *       |
| source 2    |  1.0     |  92.4    |
|    =        |  =       |  =       |
| result      |  4.2     |  194.04  |

In this concept we will focus on a small selection of SIMD instructions.
They operate on packed floating-point values using `xmm` registers.

### Floating-Point SIMD Instructions

As a rule of thumb, SIMD instructions that operate on floating-point values take a two-operand form.
Their name follows a certain structure:

1. The operation being performed, with the same name as their non-SIMD (also called _scalar_) counterpart (e.g., `add`, `mul`, etc.).
2. A suffix `p` to indicate that the instruction operates on _packed_ data, in the same position previously occupied by an `s` (for _scalar_ data).
3. A suffix to indicate the size of each lane, following the same semantics as their non-SIMD counterpart (`s` for single-precision and `d` for double-precision).

The packed name is therefore obtained from the scalar name by substituting the `s` (scalar) in the middle of the mnemonic for a `p` (packed).
The operation name and the size suffix stay unchanged:

| scalar  | packed  | meaning                                |
|---------|---------|----------------------------------------|
| `addss` | `addps` | add, single-precision (32-bit lanes)   |
| `addsd` | `addpd` | add, double-precision (64-bit lanes)   |
| `mulss` | `mulps` | multiply, single-precision             |
| `mulsd` | `mulpd` | multiply, double-precision             |

#### Arithmetic

Arithmetic SIMD instructions follow the rule above.
Some examples:

```x86asm
addps xmm0, xmm1 ; xmm0 = xmm0 + xmm1 (each 32-bit float at the same position)
subpd xmm2, xmm3 ; xmm2 = xmm2 - xmm3 (each 64-bit float at the same position)
mulps xmm4, xmm5 ; xmm4 = xmm4 * xmm5 (each 32-bit float at the same position)
divpd xmm6, xmm7 ; xmm6 = xmm6 / xmm7 (each 64-bit float at the same position)
```

#### Conversion Between Precisions

There are also SIMD instructions to convert between packed single-precision and packed double-precision floating-point values.
They follow the same naming rule, with each `s` for _scalar_ replaced by a `p` for _packed_:

| scalar     | packed     | meaning                                      |
|------------|------------|----------------------------------------------|
| `cvtss2sd` | `cvtps2pd` | convert single-precision to double-precision |
| `cvtsd2ss` | `cvtpd2ps` | convert double-precision to single-precision |

These instructions illustrate the earlier point that a lane is an interpretation, not a hard limit.
The source and destination operands have different lane sizes, so they have different lane counts.

For `cvtps2pd`, the source (`ps`) has 4 single-precision lanes.
The destination (`pd`) has 2 double-precision lanes.
Only the lower 2 lanes of the source are read.
The upper 2 are ignored:

| operand              | 4th lane | 3rd lane | 2nd lane | 1st lane |
|:--------------------:|:--------:|:--------:|:--------:|:--------:|
| source as `ps`       | ignored  | ignored  | 2.5      | 1.5      |
| destination as `pd`  |          |          | 2.5      | 1.5      |

For `cvtpd2ps`, the source (`pd`) has 2 double-precision lanes.
The destination (`ps`) has 4 single-precision lanes.
Both source lanes are converted and written to the lower 2 lanes of the destination.
The upper 2 lanes of the destination are set to zero:

| operand              | 4th lane | 3rd lane | 2nd lane | 1st lane |
|:--------------------:|:--------:|:--------:|:--------:|:--------:|
| source as `pd`       |          |          | 4.0      | 3.0      |
| destination as `ps`  | 0        | 0        | 4.0      | 3.0      |

Some examples:

```x86asm
cvtps2pd xmm0, xmm1 ; xmm0 = xmm1 as 2 doubles (low 2 lanes of xmm1 are read)
cvtpd2ps xmm0, xmm1 ; xmm0 = xmm1 as 2 floats (in low 2 lanes; upper 2 zeroed)
```

#### Memory Operands

The SIMD instructions above have all been shown with register-to-register operands.
They may also take a memory operand as their source (but **not** their destination).

The number of bytes read from memory is determined by the instruction.
For example, `addps` reads 16 bytes (4 single-precision floats).
`cvtps2pd`, by contrast, reads only 8 bytes (2 single-precision floats), because that is all the input it needs.

```x86asm
addps    xmm0, [rsi]      ; xmm0 = xmm0 + 4 floats at [rsi]
mulpd    xmm1, [rsi + 16] ; xmm1 = xmm1 * 2 doubles at [rsi + 16]
cvtps2pd xmm2, [rsi + 8]  ; xmm2 = (2 floats at [rsi + 8]) converted to 2 doubles
```

When the memory operand is 16 bytes wide, it must be _16-byte aligned_.
An aligned memory location is one whose address is a multiple of the size of the operation (16 bytes in this case).

To declare aligned memory, you can use the `align` directive on section .data and .rodata, or `alignb`, on section .bss:

```x86asm
section .rodata
align 16
mem1: dd 4.0, 3.5, 2.0, -1.0

section .data
align 16
mem2: dq 6.0, 2.1

section .bss
alignb 16
mem3: resb 16

section .text
fn:
    movaps xmm0, oword [rel mem1] ; loads 4 packed 32-bit floats in xmm0
    movapd xmm1, oword [rel mem2] ; loads 2 packed 64-bit floats in xmm1
    movaps oword [rel mem3], xmm0 ; stores 4 packed 32-bit floats in mem3
    ret
```

Memory operands smaller than 16 bytes, such as the 8-byte source of `cvtps2pd`, have no alignment requirement.

#### Loading/Storing Values

There are four instructions that copy 128 bits of packed floating-point values.
They operate between two `xmm` registers, or between one `xmm` register and a memory location:

| instruction | description                                                                       |
|-------------|-----------------------------------------------------------------------------------|
| `movaps`    | copies packed single-precision data from, or to, an _aligned_ memory location     |
| `movups`    | copies packed single-precision data from, or to, an _unaligned_ memory location   |
| `movapd`    | copies packed double-precision data from, or to, an _aligned_  memory location    |
| `movupd`    | copies packed double-precision data from, or to, an _unaligned_ memory location   |

All of those instructions may be used to copy values between two `xmm` registers.

If the operation involves a memory location, `movaps` and `movapd` require that it be _aligned_.
`movaps` and `movapd` will raise a fault if given a misaligned address.
They double as a safety check that your data layout is what you think it is.

On the other hand, `movups` and `movupd` may be used with any memory location, aligned or not.

The size prefix for a 16-byte value in NASM is `oword`.

### SIMD Extensions

SIMD has been a target of active development in the x86-64 ecosystem for decades.
Each extension to the architecture brings new instructions or new uses for old instructions.

In particular, the extensions AVX and AVX2 introduce some relevant changes.

First, support for 256-bit SIMD registers, called `ymm`.
They extend corresponding `xmm` registers, much as `rax` contains `eax`.

Second, they include support for 3-operand variants for most instructions that operate on `xmm` (and `ymm`) registers.
This includes not only SIMD instructions, but also those that operate on scalar floating-point values.
Those variants follow the same notation of their SSE equivalent, with a `v` added before:

```x86asm
vaddsd xmm0, xmm1, xmm2   ; xmm0 = xmm1 + xmm2 (scalar sum of 64-bit floats)
vmulps xmm1, xmm3, xmm4   ; xmm1 = xmm3 * xmm4 (packed multiplication of 32-bit floats)
vmovupd ymm5, yword [mem] ; this copies 32 bytes from the location at mem to ymm5
```

Third, the alignment required of SIMD memory operands is relaxed.
Only explicitly aligned moves, such as `vmovaps`, require this alignment.

In this track, we have restricted ourselves to instructions and registers up to the previous SSE extensions.
This is enough to teach foundations and ensures compatibility with a wide array of CPUs.

However, the test-runner fully supports AVX and AVX2, and even the newer extensions that are part of AVX-512.
You are free to use them.

~~~~exercism/note
It is good practice to be consistent in your use of SIMD variants.
Try not to mix SSE and AVX variants for the same instructions.

If your code base mixes those variants, it is good practice to use `vzeroupper` after you have finished your work with AVX and before using SSE.
This breaks dependency chains and avoids a costly stall when the CPU transitions between AVX and SSE state.
~~~~

## Instructions

You are writing code for the data system on an automotive parts factory floor.
Engine and chassis components move through a series of machining stations.
Each station produces measurements that have to be combined, compared, calibrated, or normalized before the next stage runs.
The functions you implement here are one for each station.

~~~~exercism/note
The computations in this exercise should be performed using SIMD instructions, not scalar operations.
~~~~

## 1. Combine yields from two lines

The factory floor runs two parallel assembly lines.
At the end of each shift, both lines report their yields for 4 part bins as single-precision numbers.
The supervisor's dashboard shows the combined yield per bin, so the two reports are summed bin by bin.
All three buffers are managed by the reporting system and are always 16-byte aligned.

Define a function `sum_yields` that, given the per-bin yields from `line_a` and `line_b`, writes the bin-wise sum to `result`.
The arguments, in order, are:

1. `line_a`: 16-byte aligned memory address holding 4 32-bit floating-point numbers
2. `line_b`: 16-byte aligned memory address holding 4 32-bit floating-point numbers
3. `result`: 16-byte aligned memory address where the function will write 4 32-bit floating-point numbers

This function has no return value, instead the result is stored in the passed buffer (`result`):

```c
line_a = {10.0, 20.0, 30.0, 40.0};
line_b = { 5.0, 15.0, 25.0, 35.0};
sum_yields(line_a, line_b, result);
// => result == {15.0, 35.0, 55.0, 75.0};
```

## 2. Compute scaled deviation

Between operations, a sampling station measures machined parts and compares them against target dimensions.
The measured values stream in from a precision gauge into a buffer that is always 16-byte aligned.
The target values come from the work order packet, which has no alignment guarantee.
The deviation is multiplied by a per-axis sensitivity factor before it is passed to the downstream tolerance checker.
For this stage, the downstream checker reads the deviation directly from a SIMD register rather than from memory.

Define a function `scaled_deviation` that, given `measured` and `target` and a `sensitivity`, writes the scaled deviation to `result`.
The arguments, in order, are:

1. `measured`: 16-byte aligned memory address holding 2 64-bit floating-point numbers
2. `target`: memory address holding 2 64-bit floating-point numbers (alignment not guaranteed)
3. `sensitivity`: memory address holding 2 64-bit floating-point numbers (alignment not guaranteed)
4. `result`: memory address for a buffer where the function will write 2 64-bit floating-point numbers (alignment not guaranteed)

The scaled deviation is `(measured - target) * sensitivity`, lane-wise.

This function has no return value, instead the result is stored in the passed buffer (`result`) as a pair of 64-bit floating-point numbers.

```c
measured    = {10.5, 20.5};
target      = {10.0, 20.0};
sensitivity = { 2.0,  4.0};
scaled_deviation(measured, target, sensitivity, result);
// => result == {1.0, 2.0};
```

## 3. Calibrate a batch

Before parts enter the final inspection bay, the dimensional readings from a 4-part batch are rescaled into double precision and corrected for known temperature drift.

The 4 raw readings arrive as single-precision numbers.
For each row of 2 readings, the calibration computes `reference / (raw - offset)`, and then multiplies this result by a constant conversion factor of `0.5`.

Note that the reference and the offset are the same for both rows of the batch.
The conversion factor is the same on every calibration, so rather than receiving as an argument, you should declare it as a packed 16-byte constant in memory.

Define a function `calibrate_batch` that, given a `raw` batch, a `reference`, an `offset`, and a `result` buffer, writes the calibrated values to `result`.
The arguments, in order, are:

1. `raw`: memory address holding 4 32-bit floating-point numbers (alignment not guaranteed)
2. `reference`: 16-byte aligned memory address holding 2 64-bit floating-point numbers
3. `offset`: 16-byte aligned memory address holding 2 64-bit floating-point numbers
4. `result`: 16-byte aligned memory address where the function will write 4 64-bit floating-point numbers (32 bytes total)

The function should, for each of the two rows of the batch:

1. Convert the 2 single-precision raw values of the row to double precision.
2. Subtract `offset` from the converted pair.
3. Divide `reference` by the result.
4. Lane-wise multiply each 64-bit floating-point number by the fixed conversion factor of `0.5`.
5. Store the 2 64-bit floating-point numbers to the corresponding 16 bytes of `result`.

This function has no return value, instead the result is stored in the passed buffer (`result`):

```c
raw       = {10.0, 20.0, 25.0, 50.0};
reference = {100.0, 100.0};
offset    = {  5.0,  10.0};
calibrate_batch(raw, reference, offset, result);
// => result == {10.0, 5.0, 2.5, 1.25};
```

## 4. Normalize scores along a line

At the end of the line, every part has a quality score that needs to be normalized before it gets reported.
Each score is multiplied by its own per-part gain, then divided by a per-axis production scale.
The gains buffer holds one gain per part.

The production scale is the same for the whole run and is passed in a memory address holding two 64-bit floating-point numbers.
The scores are updated **in place**: the same buffer that held the raw scores now holds the normalized scores.

Define a function `normalize_scores` that, given a `scores` array, a `gains` array, a `scale`, and a count `n`, normalizes the scores in place.
The arguments, in order, are:

1. `scores`: 16-byte aligned memory address holding `n` 64-bit floating-point numbers (modified in place)
2. `gains`: 16-byte aligned memory address holding `n` 64-bit floating-point numbers
3. `scale`: 16-byte aligned memory address holding 2 64-bit floating-point numbers
4. `n`: a 64-bit positive even integer (minimum `2`), the number of scores to normalize

The two scale lanes apply to the two elements of each pair.
The first lane scales the first element of every pair (lanes at even positions), the second lane scales the second (lanes at odd positions).
Each score is multiplied by its corresponding gain, then divided by the appropriate scale lane: `score * gain / scale_lane`.

This function has no return value, instead the result is stored in the input buffer (`scores`), at the same position of the corresponding `score` that was normalized:

```c
n      = 4
scores = {10.0, 20.0, 30.0, 40.0};
gains  = { 2.0,  1.5,  1.0,  0.5};
scale  = { 2.0,  4.0};
normalize_scores(scores, gains, scale, n);
// => scores == {10.0, 7.5, 15.0, 5.0};
```

## Source

### Created by

- @oxe-i