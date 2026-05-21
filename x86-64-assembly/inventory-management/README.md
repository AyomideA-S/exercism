# Inventory Management

Welcome to Inventory Management on Exercism's x86-64 Assembly Track.
If you need help running the tests or submitting your code, check out `HELP.md`.
If you get stuck on the exercise, check out `HINTS.md`, but try and solve it without using those first :)

## Introduction

## Binary Notation

An **integer** is an abstraction that represents whole numbers, such as `4`, `-2`, `0` or `64532`.

To represent an integer as a sequence of bytes, the **binary notation** is used.
In this system, each bit in the sequence represents a distinct power of two, with the value increasing as the index of the bit increases from right to left.

## Unsigned and Signed Integers

### Unsigned numbers

If the number can only be non-negative, it's called an **unsigned** number.

Unsigned numbers are represented directly as the sum of all set bits in their sequence.

The range of representable non-negative integers in a register goes from `0` (no bit set) to `2⁶⁴ - 1` (sum of all 64 bits set).

### Signed numbers

If an integer can assume positive or negative values, it's called a **signed** number.

To represent negative numbers, x86-64 uses the **two's complement** representation.

The `neg` instruction can be used to change the sign of a number.

~~~~exercism/caution
In assembly, there's no way to tell if a sequence of bytes represents a signed or an unsigned number.
It's the programmer's responsibility to give meaning to those bytes.

The use of comments can be a great aid in this task.
~~~~

## Immediates

In a previous concept, it was mentioned that a constant number, such as `4` or `15`, can be used as source operand to many instructions.
Those numbers are called **immediates**.

An immediate is truncated to fit into the destination operand.
However, in most instructions, an immediate must be at most a _32-bit signed integer_.
A number that does not fit into this size can not be used directly as operand.

The exception to this rule is `mov`, which accepts a _64-bit signed integer_ as source operand.

It is possible to use a signed negative integer as immediate in place of an unsigned integer with the same bit representation:

```x86asm
add rax, -1  ; this is 18446744073709551615 in unsigned representation
             ; an attempt to use 18446744073709551615 directly wouldn't work because immediates are usually 32-bit signed integers

mov rax, 18446744073709551615  ; this works because mov can take a 64-bit immediate as source operand
```

## Arithmetic

### Sum

The addition of two numbers can be calculated using the `add` instruction.

Sometimes, the sum of two numbers leaves an excessive bit that does not fit into the destination operand.
This bit is stored in a special flag called the **carry flag (CF)**.
The `CF` can also be set by other instructions, performing other operations.

The instruction `adc` can be used to sum two numbers and also the value in the carry flag.
It is a two-operand instruction, with the same syntax as `add`.

There's also an `inc` one-operand instruction, that sums 1 to the value in its operand.

The sum of two integers operates in the same way for both unsigned and signed numbers.

### Subtraction

The subtraction of two integers is performed using the `sub` instruction.

There's also a `dec` one-operand instruction, that subtracts 1 from the value in its operand.

The subtraction of two integers also operates in the same way for both unsigned and signed numbers.

### Multiplication

There are two different instructions to perform multiplication between two numbers in x86-64.
As a rule, unsigned multiplication uses the instruction `mul`, while signed multiplication uses `imul`.

The `mul` instruction takes the following one-operand form, where src is the source operand:

```x86asm
mul src
```

The `imul` instruction can take a one-operand, two-operand or three-operand form:

```x86asm
imul src
imul dest, src
imul dest, src1, src2
```

#### One-operand form

Two registers are implicitly used to perform a multiplication in one-operand form: `rax` and `rdx`.
If the multiplication involves two 64-bit numbers, then the lower 64 bits of the result will be in `rax` and the upper 64 bits will be in `rdx`.

This is usually called `rdx:rax`, to indicate that both registers are used in tandem.

The same happens if the multiplication involves different register sizes.
So, for instance, if two 32-bit numbers are being multiplied, `eax` and `edx` will be used.

The exception is the multiplication between two bytes.

In this case, instead of `dl:al`, `ax` will be used.
The lower portion of `ax` (`al`) will get the lower 8 bits of the product, while the upper portion (`ah`) will get the upper 8 bits.

~~~~exercism/caution
The `rdx` register is implicitly used in a one-operand multiplication.
This means any necessary value in `rdx` must be saved before that operation.
~~~~

#### Two-operand form

The two-operand form of `imul` allows for explicitly declaring a different destination operand.

In that case, the product between source and destination operands is placed in the destination operand.
This product is truncated to fit into the destination operand.

#### Three-operand form

The three-operand form of `imul` multiplies the two source operands and places the result in the destination operand.

This means that the destination operand is not multiplied with any of the source operands, it just receives the result.
This product is also truncated to fit into the destination operand.

#### Handling overflow

In case of a possible overflow, it is sometimes useful to move operands to a larger register size.

A `movzx` instruction can be used to convert a value in an 8-bit or 16-bit source operand to a larger destination operand, clearing all remaining bits.
This is called **zero extension**:

```x86asm
mov ax, 1000 ; lower 16 bits of eax are 1000, upper bits are undefined
mov cx, 200 ; lower 16 bits of ecx are 200, upper bits are undefined

; 200 * 1000 does not fit in 16 bits, so a 32-bit multiplication is necessary
; however, multiplying eax by ecx may produce an incorrect result due to undefined bits

movzx eax, ax ; lower 16 bits of eax remain 1000, upper bits are cleared
movzx ecx, cx ; lower 16 bits of ecx remain 200, upper bits are cleared
mul ecx ; now eax correctly holds 200 * 1000
```

A 32-bit source operand is always zero-extended to all 64 bits of the destination operand with a simple `mov`.

### Division

As is the case with multiplication, there are also two instructions to perform division between two numbers.
Unsigned division uses the instruction `div`, while signed division uses `idiv`.

Both instructions work with only one operand:

```x86asm
div src
idiv src
```

In both cases, the value in `rdx:rax` is divided by the value in the source operand.
The quotient is written to the `rax` register and the remainder is written to the `rdx` register.

Note that as `rdx:rax` is the dividend, both registers must have the appropriate bits set.

So, whenever working with 64-bit integers, the `rdx` register must be set up before the division.

For unsigned division, all bits in `rdx` must be cleared.
This is called **zero extension**.

For signed division, all bits in `rdx` must be cleared for a non-negative number in `rax`, and set for a negative number.
This is called **sign extension**.

Failing to do this can cause a wrong result for the division or, if the quotient is too large to fit in `rax`, an error.

There are three instructions that automate the sign extension: `cwd`, `cdq` and `cqo`.
They perform sign extension from `ax` to `dx`, from `eax` to `edx` and from `rax` to `rdx`, respectively.

There's no equivalent instruction for sign extending `al` to `dl` because division between two bytes operates differently.
Instead of using `dl:al`, `ax` is used.

So, the lower 8 bits of `ax` (`al`) will get the quotient of the operation and the higher 8 bits (`ah`) will get the remainder.

There is also the instruction `movsx` that works similarly to `movzx`, extending from any 8-bit or 16-bit source operand to a larger destination operand.
While `movzx` performs zero-extension, `movsx` performs sign-extension.

A variant of `movsx` called `movsxd` can sign-extend from a 32-bit source operand to a 64-bit destination operand.

~~~~exercism/caution
The `rdx` register is implicitly used in an integer division.
This means any necessary value in `rdx` must be saved before that operation.
~~~~

## Instructions

A local store is moving its inventory to a larger warehouse.
You were hired to pack and move everything.

You have four tasks, all related to managing the transport.

~~~~exercism/note
These are the instructions mentioned in this concept:

| Instruction   | Description                                                     |
|---------------|-----------------------------------------------------------------|
| add a, b      | a = a + b                                                       |
| adc a, b      | a = a + b + CF (previous carry)                                 |
| inc a         | a = a + 1                                                       |
| sub a, b      | a = a - b                                                       |
| dec a         | a = a - 1                                                       |
| imul a        | rdx:rax = a * rax (signed)                                      |
| imul a, b     | a = a * b (signed)                                              |
| imul a, b, c  | a = b * c (signed)                                              |
| mul a         | rdx:rax = a * rax (unsigned)                                    |
| div a         | rax = quotient, rdx = remainder of rdx:rax / a (unsigned)       |
| idiv a        | rax = quotient, rdx = remainder of rdx:rax / a (signed)         |
| movzx a, b    | a = b, adding 0 to the extra bits                               |
| movsx a, b    | a = b, adding 1 to the extra bits if b < 0 or 0 otherwise       |
~~~~

~~~~exercism/note
Remember that you can access the same register with different sizes by changing the name of the operand.
For example: `rax` (64-bit), `eax` (32-bit), `ax` (16-bit), `al` (8-bit).

You can refer to the [previous concept][basics] for the full table.

[basics]: https://exercism.org/tracks/x86-64-assembly/concepts/basics
~~~~

## 1. Get weight of each box

Items are being packed in boxes that must be labeled with their weight.
There is no scale around, but luckily you know how much each item weighs on average.

To better organize things, a box holds only items of two different products.

Define a function `get_box_weight` that returns the total weight of a box, in `g`.
This function takes as parameters, in this order:

- The number of items for the first product in the box
- The weight of each item of the first product, in `g`
- The number of items for the second product in the box
- The weight of each item of the second product, in `g`

Consider that an empty box weighs **500 g**.
A constant `WEIGHT_OF_EMPTY_BOX` is defined at the top of the solution file.

Example:

```c
get_box_weight(30, 40, 50, 20);
// => 2700
```

All arguments are 16-bit non-negative integers, and the return value is a 32-bit non-negative integer.

## 2. Calculate how many boxes fit into the truck

Boxes are being stacked and moved to the new warehouse in a truck.
However, there is only so much vertical space in the truck.

Define a function `max_number_of_boxes` that returns how many boxes of a certain height can be stacked vertically (one on top of another) within the truck.

This function takes as parameter the height of the box, in `cm`.
Consider that the truck interior height is **300 cm**.
A constant `TRUCK_HEIGHT` is defined at the top of the solution file.

Example:

```c
max_number_of_boxes(30);
// => 10
```

The argument and the return value are 8-bit non-negative integers.
The box height is always at least `2`, so the result fits in 8 bits.

## 3. Check if all products are accounted for

There is a checklist in the new warehouse with the number of items still unaccounted for each product.
For each new box moved there, you need to calculate the new value in the checklist for each product in the box.

Define a function `items_to_be_moved` that returns how many items remain to be moved to the new warehouse for a given product.
This function takes as parameters, in this order:

- The number of items still unaccounted for a product
- The number of items for the product in a box

Example:

```c
items_to_be_moved(76532, 120);
// => 76412
```

The arguments are 32-bit non-negative integers.
The return value is a 32-bit integer.
In case of an error in the process, it is possible that the result is a negative number.

## 4. Get payment

Your payment is based on how many boxes were moved and how many truck trips were necessary.
For each box, you will be paid **5 dollars** and for each trip, you will be paid **220 dollars**.
Constants `PAY_PER_BOX` and `PAY_PER_TRUCK_TRIP` are defined at the top of the solution file.

Note that you may have received part of this payment up front to cover initial costs, and this up-front payment should be subtracted from the final pay.
In addition, some products are not covered by insurance and your payment will also be reduced by the value of any of those items broken or missing.
It is possible that you end up owing money if you are not careful!

This means the net amount you are owed, or owe, is:

```c
net = boxes * PAY_PER_BOX + trips * PAY_PER_TRUCK_TRIP - up_front - broken_items * item_value
```

This payment, or debt, will be divided equally between you and a number of workers you hired.
Any remaining money, or debt, is yours.
For example, if the net amount of money is `100` being shared amongst `6` people (you and `5` workers), you get `20` (`100/(5 + 1) = 16` plus the remaining `4`).

Define a function `calculate_payment` that returns how much you should be paid, or pay, at the end.
This function takes as parameters, in this order:

- How much you have received up front, as a 64-bit non-negative integer
- The total number of boxes moved, as a 32-bit non-negative integer
- The number of truck trips made, as a 32-bit non-negative integer
- The number of broken or missing items, as a 32-bit non-negative integer
- The value of each lost item, as a 64-bit non-negative integer
- The number of workers to split the payment or debt with you, as an 8-bit positive integer

Example:

```c
calculate_payment(2000, 1000, 5, 21, 2, 1);
// => 2029
```

The return value is a 64-bit integer.

## Source

### Created by

- @oxe-i