# Secrets

Welcome to Secrets on Exercism's x86-64 Assembly Track.
If you need help running the tests or submitting your code, check out `HELP.md`.
If you get stuck on the exercise, check out `HINTS.md`, but try and solve it without using those first :)

## Introduction

Each bit of an integer can be used to store a binary value.
Because many situations involve binary information---such as true or false, inclusion or exclusion, on or off---the binary representation of an N-bit integer provides a compact way to encode the binary state of N items.
This makes the ability to manipulate bits and bytes essential in assmbly.
The x86-64 instruction set offers a wide variety of bitwise manipulation instructions.

## Single bit manipulation

These instructions work on single bits in a operand.

They all take two operands, the second indicates the index of the bit being operated in the first operand.
All of them copy the selected bit into the **carry flag (CF)**.

| Name | Description                                                                   |
|------|-------------------------------------------------------------------------------|
|bt    |copies the bit into `CF` without modifying any operand                         |
|bts   |copies the bit into `CF` and sets it in the destination operand                |
|btr   |copies the bit into `CF` and clears it in the destination operand              |
|btc   |copies the bit into `CF` and complements (flips) it in the destination operand |

## Bitwise operations

Bitwise operations are performed in all bits of an operand.

They all have an instruction with the same name as the performed bitwise operation:

| Name   | Description                                  |
|--------|----------------------------------------------|
|and     |1 if both bits are 1                          |
|or      |1 if at least one of the bits is 1            |
|xor     |1 if the bits differ                          |
|not     |1 if bit was 0; 0 if bit was 1                |

Most of them take two operands, perform a bitwise operation on both and store the result in the destination operand.
The exception is `not`, which takes just one destination operand.

~~~~exercism/note
When we interpret one and zero as inclusion and exclusion, respectively, an integer is called a *bitmask* (or simply a *mask*).
A bitmask "masks out" items because a zero in the`i`th bit excludes the `i`th item, while a one includes it.
We also commonly use a bitmask to include certain bits of an integer while excluding others.

For example, let `A` be an integer whose binary representation is


| index | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|-------|---|---|---|---|---|---|---|---|
| bits  | 1 | 0 | 0 | 1 | 0 | 1 | 0 | 1 |

Also, let `M` be an integer whose binary representation is

| index | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|-------|---|---|---|---|---|---|---|---|
| bits  | 0 | 0 | 0 | 0 | 1 | 1 | 0 | 1 |

Both are 8-bit integers. In this case, we can say that `A` is masked by `M` at the first and the fourth through seventh bit positions.

The bitwise instructions discussed earlier are useful in manipulating integers with masks.
For example:
- To *clear* the bits of `A`that are not selected by `M`, take the bitwise AND: `A AND M`.
- To *set* the bits of `A` selected by `M`, take the bitwise OR: `A OR M`.
~~~~

## TEST Instruction

The `test` instruction makes a bitwise AND between both operands and sets flags according to the result.

If A is the first operand and B, the second:

| flag | set when             |
|:----:|:---------------------|
| CF   | always cleared       |
| ZF   | A AND B == 0         |
| SF   | A AND B < 0 (signed) |
| OF   | always cleared       |

This instruction takes two operands and update the flags, but **do not modify its operands**.

## Shift operations

These instructions move the bits in the destination operand by a number of positions specified by the second operand.
The second operand must be a constant number (an `immediate`) or the register `cl` (the lowest 8 bits of `rcx`).

| Name    | Description             |
|---------|-------------------------|
|shl/sal  |Shifts bits to the left  |
|shr/sar  |Shifts bits to the right |

### Shl / Sal

Both `shl` and `sal` perform the exact same operation, one is an alias of the other.

Whenever a shift left is made, bits closer to the end of the sequence than the length of the shift are first moved to the carry flag (CF) and then discarded.
On the other hand, a number of new cleared bits equal to the length of the shift is added to the beginning.

Since each bit in an integer represents a power of 2, a shift to the left by n positions has the effect of multiplying the integer by 2ⁿ.

### Shr/Sar

There are two instructions to move bits to the right: `shr` and `sar`.

Whenever any of the two instructions is used, bits closer to the start of the sequence than the length of the shift are first moved to the carry flag (CF) and then discarded.
On the other hand, a number of new bits equal to the length of the shift is added to the end.

The difference between them is that `shr` moves `0` bits to the left end, while `sar` moves `1` if the most significant was set and `0` otherwise.
This means that `sar` preserves the sign in the shift of a signed integer.

Since each bit in an integer represents a power of 2, a shift to the right by n positions using `shr` has the effect of making an *unsigned* division by 2ⁿ.

Similarly, a shift to the right by n positions using `sar` has the effect of making a *signed* division by 2ⁿ.

## Rotation Operations

These instructions move the bits in the destination operand by a number of positions specified by the second operand.
The second operand must be a constant number (an `immediate`) or the register `cl` (the lowest 8 bits of `rcx`).

The difference between a rotation and a shift is that a rotation does not discard or add any bits.
Bits that would be discarded by a shift are instead moved to the opposite end.
So, all bits remain, they all change places.

| Name    | Description               |
|---------|---------------------------|
|rol      |Rotates bits to the left   |
|ror      |Rotates bits to the right  |

There are variants for both of those instructions that use the `carry flag (CF)` as an extra bit in the rotation:

| Name    | Description                                   |
|---------|-----------------------------------------------|
|rcl      |Rotates bits to the left, including the `CF`   |
|rcr      |Rotates bits to the right, including the `CF`  |

This means that a bit at one end of the sequence is first moved to the flag before going to the other end of the sequence.
At the same time, the previous value in the flag is moved to the bit that would receive the one moved to the flag.

So, the `CF` works as an extra bit to the left in the case of `rcr` and as an extra bit to the right in the case of `rcl`.

## Other bit manipulation instructions

There are other useful bit manipulation instructions:

| Name     | Description                                                                            |
|----------|----------------------------------------------------------------------------------------|
| popcnt   | Counts the number of bits set                                                          |
| lzcnt    | Counts the number of leading zeros (a bit cleared before the first set bit)            |
| bsr      | Gets the index of the most significant set bit. If no bit is set, result is undefined  |
| bsf      | Gets the index of the least significant set bit. If no bit is set, result is undefined |

These instructions all work with two 16-bit, 32-bit or 64-bit operands.
They can not be used with 8-bit operands.

## Instructions

Your friend has just sent you a message with an important secret.
Not wanting to make it easy for others to read it, the message was encrypted by performing a series of bit manipulations.
You will need to write the methods to help decrypt the message.

~~~~exercism/note
These are the single bit instructions mentioned in this concept:

| Name | Description                                                                   |
|------|-------------------------------------------------------------------------------|
|bt    |copies the bit into `CF` without modifying any operand                         |
|bts   |copies the bit into `CF` and sets it in the destination operand                |
|btr   |copies the bit into `CF` and clears it in the destination operand              |
|btc   |copies the bit into `CF` and complements (flips) it in the destination operand |

These are the bitwise instructions mentioned in this concept:

| Name   | Description                                  |
|--------|----------------------------------------------|
|and     |1 if both bits are 1                          |
|or      |1 if at least one of the bits is 1            |
|xor     |1 if the bits differ                          |
|not     |1 if bit was 0; 0 if bit was 1                |

These are the shift instructions mentioned in this concept:

| Name    | Description             |
|---------|-------------------------|
|shl/sal  |Shifts bits to the left  |
|shr/sar  |Shifts bits to the right |

These are the rotation instructions mentioned in this concept:

| Name    | Description                                   |
|---------|-----------------------------------------------|
|rol      |Rotates bits to the left                       |
|ror      |Rotates bits to the right                      |
|rcl      |Rotates bits to the left, including the `CF`   |
|rcr      |Rotates bits to the right, including the `CF`  |

These are the miscellaneous instructions mentioned in this concept:

| Name     | Description                                                                            |
|----------|----------------------------------------------------------------------------------------|
| popcnt   | Counts the number of bits set                                                          |
| lzcnt    | Counts the number of leading zeros (a bit cleared before the first set bit)            |
| bsr      | Gets the index of the most significant set bit. If no bit is set, result is undefined  |
| bsf      | Gets the index of the least significant set bit. If no bit is set, result is undefined |
~~~~

## 1. Extract the mask

The message is encoded in a 16-bit integer.
However, of those, the 8 highest bits are not actually part of the message, but a mask that needs to be used in the decryption.

Implement the `extract_higher_bits` function that takes a 16-bit integer and returns the 8 highest bits of it.

```c
extract_higher_bits(0b1010010011000101)
// => 0b10100100
```

## 2. Extract the message

Having the ability of extracting the mask is not enough, you should also isolate the message.

Implement the `extract_lower_bits` function that takes a 16-bit integer and returns the 8 lowest bits of it.

```c
extract_lower_bits(0b1010010011000101);
// => 0b11000101
```

## 3. Extract redundant bits

Some bits are set in both the message and the mask.
This is a very important piece of information that will be used later.

Implement the `extract_redundant_bits` that takes a 16-bit integer, encoding both the message and a mask, and returns a 8-bit integer with only the redundant bits set.
A bit in the returned number should be set to 1 where it is also 1 in both the message and the mask.
All other bits should be _cleared_.

```c
extract_redundant_bits(0b1010010011000101);
// => 0b10000100
```

## 4. Set all message bits

Next, there are some bits that need to be set to `1` in the message, according to the mask.

Implement the `set_message_bits` function that takes a 16-bit integer, encoding both the message and a mask, and returns the result of setting the bits in the message to 1.
A bit from the message should be set to 1 where the bit in the mask is 1.
All other bits should be kept _unchanged_, so that they remain set if they were already set, and cleared if they were already cleared.

```c
set_message_bits(0b1010010011000101);
// => 0b11100101
```

## 5. Rotate private key

There is a piece of the puzzle not explicit in the message: the 16-bit number `0b1011001100111100`.
This number is your shared private key and you should use it to help decrypt the message.

In order to do that, you first need to rotate the bits of your private key to the left by a certain number of positions.
The number of positions is equal to the number of redundant bits set in both the message and the mask.

Implement the `rotate_private_key` function that takes a 16-bit integer, encoding both the message and a mask, and returns the result of rotating your private key.
This result is a 16-bit integer.

```c
rotate_private_key(0b1010010011000101);
// => 0b1100110011110010
```

~~~~exercism/note
NASM (The Netwide Assembler, the assembler used by this track) has support to constants in binary format with `0b` prefixed.
It also supports using an underscore (`_`) as separator in a constant, for readability:

```x86asm
PRIVATE_KEY equ 0b1011_0011_0011_1100
```
~~~~

## 6. Format private key

In order to be used in decryption, your private key must be formatted to isolate the relevant bits.

To fully format a private key, you must:

- Rotate it.
- Isolate the lowest 8-bit portion of the rotated private key, which is the base value.
- Isolate the highest 8-bit portion of the rotated private key, which is a mask to be applied to the base value.
- Flip bits in the base value that are also set in the mask.
- Flip all bits in the result.

A flipped bit is 1 if it was 0 and 0 if it was 1.

Implement the `format_private_key` function that takes a 16-bit integer, encoding both the message and a mask, and returns a fully formatted 8-bit private key.

```c
format_private_key(0b1010010011000101);
// => 0b11000001
```

## 7. Finish decryption

Once you have the message with all relevant bits set and the formatted private key, it is time to join them together to get the resulting message.

The resulting message is a 16-bit integer, of which:

- The highest 8 bits is filled with the formatted private key.
- The lowest 8 bits is filled with the message, after setting all relevant bits.

Implement the `decrypt_message` function that takes a 16-bit integer encoding both the message and a mask, and returns a 16-bit integer with the message fully decrypted.

This function should make use of the formatted private key that you generate with `format_private_key` and also of the message with all relevant bits set with `set_message_bits`.

```c
decrypt_message(0b1010010011000101);
// => 0b1100000111100101
```

## Source

### Created by

- @oxe-i