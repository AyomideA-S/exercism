# Lost and Found

Welcome to Lost and Found on Exercism's x86-64 Assembly Track.
If you need help running the tests or submitting your code, check out `HELP.md`.
If you get stuck on the exercise, check out `HINTS.md`, but try and solve it without using those first :)

## Introduction

The **call stack**, or just **stack**, is a special data structure that starts at the highest point in memory and grows downward.

## Push and Pop

The stack supports at least two operations, with instructions of the same name:

| Instruction | Operation performed                                 |
| ----------- | --------------------------------------------------- |
| `push`      | adds an element to the stack                        |
| `pop`       | removes and returns the most recently added element |

This means that the stack is a **last in, first out (LIFO)** data structure.

In order to keep track of the current point of the stack, where the most recent element is located, the register `rsp` is used.

So, a `push` instruction takes one operand and stores the contents of this operand in the stack.
As the stack grows downward, the value in `rsp` is reduced by the size of the stored value.

Similarly, a `pop` instruction takes one operand and stores the most recent value in the stack (the one pointed by `rsp`) into it.
The value in `rsp` is then increased by the size of the retrieved value.

## Local Variables

It is also possible to manipulate the value of `rsp` directly.
This is often used to create local variables for a function.

```x86asm
sub rsp, 24 ; this reserves 24 bytes of space in the stack
add rsp, 24 ; this restores the previous value of rsp, "reducing" the stack by 24 bytes
```

Note that, at the moment space is reserved in stack, the value stored in that space is _undefined_.

~~~~exercism/note
Neither `pop` nor direct manipulation of `rsp` actually remove the contents stored in memory.
The "removal" of the stack is abstracted from the new address in `rsp`.

In some contexts, this may cause security concerns by exposing internal values to external sources.
One way to deal with that is by zeroing-out the contents of any stack space used by the function.
~~~~

## Call and Ret

The main purpose of the stack is to keep track of the return address for called functions.

As it was mentioned in a previous concept, there is a special register called `rip` that points to the next instruction to be executed.
This register is used to control the flow of a program, being modified by instructions such as `jmp` and `call`.

Whenever a `call` instruction is used, the current value in `rip` is implicitly pushed to the stack.
Subsequently, the operand for the instruction is moved into `rip`, so that execution continues in the called function.

A `ret` instruction does the opposite operation.
It pops from the stack into `rip`, so execution returns to the calling function.

At point of entry, `rsp` points to the address to be returned.
This is the address `ret` must pop from the stack.

So, any change in the value of `rsp` inside a function, either directly or with `push`, must be reversed before the function returns.

## Callee-Saved and Caller-Saved Registers

Apart from `rsp`, there are other registers that must be preserved across function calls: `rbp`, `rbx`, `r12`, `r13`, `r14` and `r15`.
In general, the calling function expects to be able to use those registers without them being changed by a called function.

This means the _called_ function must save the values in those registers before using them and restore them to their original values before returning.
This is why they are called **callee-saved registers**.

Other general-purpose registers are directly available for use by the called function.

This means that the _caller_ function must save the values in those registers before calling any function, in case they are modified by the called function.
This is why they are called **caller-saved registers**.

_The most common way for saving the contents of a register is by storing it into the stack._

## Prologue and Epilogue

In some cases, the stack might be heavily used, with many modifications before the function returns.
So, keeping track of all those changes to reverse them may be complex.

In those cases, a common strategy is saving the address of `rsp` in another register that remains otherwise unchanged inside the function.
And then, the value of `rsp` might be restored with a simple `mov` instruction at the end, before the function returns.

Although any register may be used for this purpose, it is conventional to use `rbp` as a base pointer.
Since `rbp` is itself a callee-saved register, this is often preceded by a `push rbp`.
This sequence is usually called **prologue**.

At the end, the restoration of `rsp` is made with a `mov rsp, rbp` and then `rbp` is also restored with a `pop` from the stack.
This sequence is usually called **epilogue**.

```x86asm
section .text
fn:
    ; prologue
    push rbp
    mov rbp, rsp
    ...
    ; epilogue
    mov rsp, rbp
    pop rbp
    ret
```

## Passing and Returning Arguments with the Stack

In the System V ABI calling convention, arguments are usually passed to functions in registers.
However, when there are too many arguments, or they need more than the size of a register, the stack may be used.

In those cases, values are added to the stack in reversed order, so that the first argument is closer to `rsp`.
Since at point of entry, `rsp` points to the return address, which is a 8-byte value in x86-64, the first argument on the stack, if any, can be accessed in `rsp + 8`.

## Stack Alignment

The System V ABI states that the stack needs to be 16 byte aligned immediately _before_ the call instruction is executed.
As `call` pushes `rip` into the stack, at point of entry the stack for the called function is **not** 16-byte aligned.

This means that a function that calls another (and, in special, external functions) needs to align the stack before using `call`.

This can be done by subtracting a suitable value from `rsp`.
This value must be 8 more than a multiple of 16: 8, 24, 40, etc.
Since a `push` instruction subtracts from `rsp`, a dummy `push` may be used to the same effect.

## Instructions

Your friend Leticia works at the Lost-and-Found office in a metro station.

Every article found is added to a new entry in a list of items for the day.
At the end of the month, any item not retrieved is moved to a deposit in a box labeled with the date it was found.
This is all done on paper, so things sometimes get unwieldy!

Leticia asked for your help in automating some of these tasks.

~~~~exercism/note
These are the instructions mentioned in this concept:

| Instruction   | Description                                               |
|---------------|-----------------------------------------------------------|
| push a        | pushes a into the stack, reducing `rsp` by the size of a  |
| pop a         | pops a from the stack, increasing `rsp` by the size of a  |
~~~~

## 1. Create an entry for each item

The first thing you need to do is to organize all items, so they can be looked up in a easier way.
Each item is identified in storage by its ID, a description, the date it was found and a variable number of categories.

Define a function `create_item_entry` that has no return value and inserts a new entry for an item in a memory location.
This function may take any number of parameters, of which the first six always are:

1. The address for a location in memory where the entry should be stored.
2. The ID for the item, as a 64-bit unsigned integer.
3. The address for a string with the item's description.
4. The day the item was found, as a 64-bit unsigned integer.
5. The month the item was found, as a 64-bit unsigned integer.
6. The number of categories for the item, as a 64-bit unsigned integer.

Each subsequent parameter is the address for a string with one of the categories.

Values should be stored in the provided memory location in the same order of the arguments: ID, description, day, month, number of categories, and each category in order.

## 2. Reserve space for a monthly list of items

It is cumbersome to search for items in so many different lists.
So, you decide to organize everything in a single list for each month.
This list is implemented as an array.

Define the `create_monthly_list` function that allocates space in memory for an array and returns the address of that memory location.
It takes as parameters:

1. The capacity of the array in bytes, as a 64-bit unsigned integer.
2. An allocator function.

The allocator function takes as parameter a 64-bit unsigned integer corresponding to the size in memory to be allocated, in bytes, and returns the address for the allocated space.

Note that the allocated space has _undefined_ value, so all bytes in that space should be cleared, ie, their value should be set to `0`.

## 3. Insert an item in the monthly list

At each day, every found item should be inserted in the monthly list.

Define the `insert_found_item` function that has no return value and takes as parameters:

1. The address for a space in memory where the monthly list is located.
2. The current number of entries already stored in the list, as a 64-bit unsigned integer.
3. A new entry to be added to the list.

You may consider that the new entry always fits into the list and that each entry in the list takes up 120 bytes in space.

## 4. Print an item

Searching for a specific entry would be much easier if Leticia could see it printed on the screen.

Define the `print_item` function that takes as parameters:

1. The address for a buffer where an introductory ASCII NUL-terminated string may be stored.
2. The address for a space in memory where the monthly list is located.
3. The index of the entry in the array for the item that should be printed, as a 64-bit unsigned integer.
4. A printing function.

This function has no return value and should call the printing function with the following arguments:

1. The address to a memory location where the introductory string is stored; or `0` (as a 64-bit integer) if no string is passed.
2. The index of the entry in the array for the item that should be printed, as a 64-bit unsigned integer.
3. The ID for the item, as a 64-bit unsigned integer.
4. The address for a string with the item's description.
5. The day the item was found, as a 64-bit unsigned integer.
6. The month the item was found, as a 64-bit unsigned integer.
7. The number of categories for the item, as a 64-bit unsigned integer.
8. The address of the first category string.

The introductory string is optional.
If it is used in the printing function, this string must be NUL-terminated (ending in `0`) and have at most 50 characters, already considering the NUL terminator.
Otherwise, the value `0` should be passed to the printing function instead.

You may consider that each item in the list takes up 120 bytes in space.

## Source

### Created by

- @oxe-i