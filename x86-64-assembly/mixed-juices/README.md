# Mixed Juices

Welcome to Mixed Juices on Exercism's x86-64 Assembly Track.
If you need help running the tests or submitting your code, check out `HELP.md`.
If you get stuck on the exercise, check out `HINTS.md`, but try and solve it without using those first :)

## Introduction

## Loops

A **loop** is a sequence of instructions that is potentially executed more than once, until an ending condition is met.

In x86-64 a loop is usually created with a jump to a previous label:

```x86asm
example_loop:
    ...
    jmp example_loop
```

Note that an unconditional jump to a previous label will always transfer execution to this label.
This means the loop will keep repeating forever, unless there is another loop to outside the repeated sequence.

For instance, this loop does not end:

```x86asm
infinite_loop:
    inc rax
    jmp infinite_loop ; always jumps to 'infinite_loop', repeating 'inc rax' forever
```

And this loop may end, depending on the condition being met:

```x86asm
maybe_finite_loop:
    cmp rax, 1
    je out_of_loop ; jumps to 'out_of_loop' if rax == 1, breaking the loop

    inc rax
    jmp maybe_finite_loop ; always jumps to 'infinite_loop'
out_of_loop:
    ...
```

There are some instructions which can be used to create loop-like behavior.
One of them is **loop**.

Its single operand is a label which has the address to the start of the loop.

The `loop` instruction uses the value in `rcx` as a counter, decrementing it by 1 each time.
Once the value in `rcx` reaches zero, the loop ends and execution continues sequentially:

```x86asm
section .text
fn:
    mov rax, 0
    mov rcx, 10
.example:
    inc rax
    loop .example ; this repeats the sequence starting in .example 10 times (the value in rcx)
                  ; at each time, rcx is decremented by 1
```

There are two variants for the `loop` instruction that check for the zero flag (`ZF`) at each iteration.
Apart from stopping the loop once `rcx` reaches zero, they also stop when the condition is _not_ met.

| instruction       | condition |
| ----------------- | --------- |
| `loope`/`loopz`   | `ZF` == 1 |
| `loopne`/`loopnz` | `ZF` == 0 |

The `ZF` **is not tested** by those instructions.
There must be a `cmp`, `test`, or another instruction that changes `ZF` before them:

```x86asm
section .text
fn:
    mov rax, 0
    mov rcx, 10
.example:
    inc rax
    cmp rax, 3
    loopne .example ; this repeats the sequence starting in .example while rcx > 0 and rax != 3
```

## Instructions

Your friend Li Mei runs a juice bar where she sells delicious mixed fruit juices.
You are a frequent customer in her shop and realized you could make your friend's life easier.
You decide to use your coding skills to help Li Mei with her job.

## 1. Determine how long it takes to make a juice

Li Mei likes to tell her customers in advance how long they have to wait for a juice from the menu that they ordered.
She has a hard time remembering the exact numbers because the time it takes to mix the juices varies:

| ID  | Drink               | Time |
| --- | ------------------- | ---- |
| 1   | Pure Strawberry Joy | 1    |
| 2   | Energizer           | 3    |
| 3   | Green Garden        | 3    |
| 4   | Tropical Island     | 4    |
| 5   | All or Nothing      | 5    |
| 6   | Feel Good           | 4    |
| 7   | Today’s Special     | 7    |
| 8   | Client's Choice     | 10   |

Write a function `time_to_make_juice` that takes an ID for a juice, as a 32-bit number, and returns the time it takes to make the juice, also as a 32-bit number.

```c
time_to_make_juice(2);
// => 3
```

## 2. Determine how long it takes to make all ordered juices

Li Mei needs to periodically replenish her supplies, so she needs to know in advance how much time she will take to prepare all the currently available orders.

To help your friend, write a function `time_to_prepare` that takes an array of IDs for each ordered juice and the number of juices in the array.
This function should return the total time it will take to prepare all the drinks in the array.

You can consider that each ID, the number of IDs in the array and the return value are all 32-bit numbers.
The result will always fit in a 32-bit number.

```c
time_to_prepare({2, 3, 8}, 3);
// => 16
```

## 3. Replenish the lime wedge supply

A lot of Li Mei's creations include lime wedges, either as an ingredient or as part of the decoration.
So when she starts her shift in the morning she needs to make sure the bin of lime wedges is full for the day ahead.

Implement the function `limes_to_cut` which takes the number of lime wedges Li Mei needs to cut, an array representing the supply of whole limes she has at hand, and the number of limes in the array.

Each lime is represented in the array by a character with its size.
Different sizes of lime can give Li Mei a different number of wedges:

| Size | Wedges |
| ---- | ------ |
| 'S'  | 6      |
| 'M'  | 8      |
| 'L'  | 10     |

~~~~exercism/note
A character is a 8-bit number that can be used as any 8-bit number can:

| Character | Value |
|-----------|-------|
| 'S'       | 83    |
| 'M'       | 77    |
| 'L'       | 76    |

It can also be used directly in instructions, being equivalent to its value:

```x86asm
mov dl, 'S'
cmp cl, 'M'
```
~~~~

Li Mei always cuts the limes in the order in which they appear in the array, starting with the first item.
She keeps going until she reached the number of wedges that she needs or until she runs out of limes.

Li Mei would like to know in advance how many limes she needs to cut.

You can consider that the number of wedges needed, the number of limes in the array and the return value are all 32-bit numbers.
The result will always fit in a 32-bit number.

```c
limes_to_cut(25, {'S', 'S', 'L', 'M', 'S'}, 5);
// => 4
```

## 4. Finish up the shift

Li Mei always works until 3pm.
Then her employee Dmitry takes over.
There are often drinks that have been ordered but are not prepared yet when Li Mei's shift ends.
Dmitry will then prepare the remaining juices.

To make the hand-over easier, implement a function `remaining_orders` which takes:

- The number of minutes left in Li Mei's shift.
- An array of IDs for each juice that has been ordered but not prepared yet.

The function should return the number of orders that Li Mei prepared before the end of her workday.

The time left in the shift will always be greater than 0.
The array of juices to prepare will never be empty and the shift will always end before reaching the end of the array.
Furthermore, the orders are prepared in the order in which they appear in the array.
If Li Mei starts to mix a certain juice, she will always finish it even if she has to work a bit longer.

You can consider that the number of minutes left, each ID in the array and the return value are all 32-bit numbers.
The result will always fit in a 32-bit number.

```c
remaining_orders(5, {5, 5, 3});
// => 1
```

## Source

### Created by

- @oxe-i