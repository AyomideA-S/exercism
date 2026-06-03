# Bird Watcher

Welcome to Bird Watcher on Exercism's x86-64 Assembly Track.
If you need help running the tests or submitting your code, check out `HELP.md`.
If you get stuck on the exercise, check out `HINTS.md`, but try and solve it without using those first :)

## Introduction

## Arrays

Any data in assembly is a sequence of bytes.
This means that any data can be viewed as an **array** of those underlying bytes.

### Accessing elements in an array

In order to access any value in memory, it is necessary to compute its **effective address**.
An effective address is an expression that may consist of:

- a _base address_, for instance, the one indicated by the label of a variable.
- one _index register_, possibly scaled by `1`, `2`, `4` or `8`.
- a signed 32-bit _displacement_, which is a number to be added to (or subtracted from) the base address.

Note that this address is _0-indexed_, so that a base address, without any offset, points to the first byte of a variable.
This is why dereferencing memory using just a label without any offset, as we have been done in previous concepts, yields a value starting at its first byte:

```x86asm
section .data
    example dq 10 ; example is a 8-byte variable
                  ; so it can be viewed as an array of those 8 bytes
                  ; which can be accessed from index 0 to index 7

section .text
fn:
    mov al, byte [example] ; this accesses the first byte
    mov r8b, byte [example + 2] ; this accesses the third byte
    mov edx, dword [example + 1] ; this accesses 4 bytes starting at the second
```

~~~~exercism/note
x86-64 is [little endian][endianness].
This means that the least significant byte of a multibyte value is stored at the smallest memory address.

Consequently, when accessing the individual bytes of a multibyte value, it is necessary to add a positive offset to the base address to reach more significant bytes.

[endianness]: https://en.wikipedia.org/wiki/Endianness
~~~~

An initialized variable declared with a list of values is an array of those values, each element having the size specified.
However, offsets are always for **_bytes_**, even when each element in the array has a greater size:

```x86asm
section .data
    arr dq 4, 8, 15, 23, 42 ; this defines an array of 5 qwords (8-byte elements)
                            ; the first qword has value 4 and can be accessed at [arr] (offset 0)
                            ; any subsequent qword can be accessed at offsets increasing by the size in bytes of each element (8)

section .text
fn:
    mov rdx, 2
    lea rcx, [rel arr]
    mov rax, qword [rcx + 8*rdx + 8]  ; rdx is an index register scaled by 8
                                      ; 8 is a signed 32-bit displacement
                                      ; rax now holds 8-bytes stored in 'arr' starting at offset:
                                      ; 8*rdx(2) + 8 = 16 + 8 = 24
                                      ; this is the fourth element of the array, i.e., the element 23
```

Note that, since addresses are for bytes, it is possible to access directly an individual byte for any element in an array:

```x86asm
section .data
    arr dq 4, 8, 15, 16   ; this defines an array of 4 qwords (8-byte elements)

section .text
fn:
    mov r8, 3
    lea r9, [rel arr]
    mov r10b, byte [r9 + 2*r8 + 1] ; this accesses the byte in 'arr' at offset: 2*r8(3) + 1 = 7
                                   ; this byte is part of the first qword and has value 0 (the fist byte is the least significant one)
```

For the same reason, it is possible to access more than an element's size in a single instruction:

```x86asm
section .data
    arr db 1, 2, 3, 4 ; this defines an array of 4 bytes

section .text
fn:
    lea rcx, [rel arr]
    mov r11, dword [arr] ; this accesses all bytes in arr as a 32-bit value with bytes
                         ; the least significant byte is 1, the next is 2 and so on
                         ; the resulting number is 0x04030201 or 67305985 in decimal
```

### Computing the size of an initialized array

NASM (The Netwide Assembler - the assembler used by this track) has a special symbol (`$`) that indicates the current location in memory.
This symbol offers a convenient way to compute the total size in memory occupied by an array:

```x86asm
section .data
    example dd 4, 5, 6
    example_length dq $ - example  ; this is a qword variable with the size of the array, in bytes
```

When used just after `example`, `$` has the address in memory for the end of the array.
This means that `$ - example` is the difference between that address and the one pointed by the label `example`.
This is exactly the total size, in bytes, occupied by the array pointed by `example`.

So, by defining `example_length` with this value, we have created a 8-byte variable which stores the size, or length, of the array, in bytes.

### Section .bss

Uninitialized data is declared in the **section .bss**.
On most platforms, this data is automatically filled with zero by the OS at the start of the program.

In NASM, an uninitialized variable has a name, a directive that indicates data size and the number of elements to be reserved.
Each of these is separated with a space from the other.

The main directives and their related data sizes are:

| directive | size    |
| :-------: | :------ |
|   resb    | 1 byte  |
|   resw    | 2 bytes |
|   resd    | 4 bytes |
|   resq    | 8 bytes |

For instance, this reserves uninitialized space for `3` bytes in a variable named `example`:

```x86asm
section .bss
    example resb 3
```

And this reserves uninitialized space for `10` times `8` bytes (so, `80` bytes) in a variable named `arr`:

```x86asm
section .bss
    arr resq 10
```

Variables in `section .bss` are mutable, i.e., they are read-and-write.

Unitialized data can be accessed in the same way as initialized data, by using its effective address.
Similarly, they are also of static storage duration and accessible from any function in the same source file (and, if declared `global`, in other source files as well).

### Accessing array addresses with the Lea instruction

As it was explored in a previous concept, the `lea` instruction computes an effective memory address.
It can be used to compute the address of any element in an array, following the same semantics.

Note that in relative addressing it is often necessary to load the variable's address into a register before forming a more complex address:

```x86asm
lea rax, [rel arr]
lea rdx, [rax + 8*r10 - 20] ; accessing 'arr' directly instead of loading it into rax first may yield an error
```

~~~~exercism/note
One of the advantages of `lea` is that it uses address-calculation arithmetic to compute a value without actually accessing the memory in that address.
This makes it useful to do arithmetic computations even when none of the registers holds a memory address:

```x86asm
mov rcx, 3
mov rdx, 5
lea rax, [rcx + 8*rdx + 10] ; rax = rcx(3) + 8*rdx(5) + 10 = 3 + 40 + 10 = 53
```
~~~~

## Instructions

You're an avid bird watcher that keeps track of how many birds have visited your garden in the last seven days.

You have six tasks, all dealing with the numbers of birds that visited your garden.

~~~~exercism/note
The number of birds in each day is represented as a 8-bit (1-byte) number.
~~~~

## 1. Check what the counts were last week

For comparison purposes, you always keep a copy of the last week's counts nearby.

Implement the `last_week_counts` function that takes no parameter and returns a copy of last week's counts as a 8-byte number, where each byte represent a day's count, in order from the oldest (least-significant byte) to most recent.
Since the week has only 7 days, the last byte must be zeroed-out.

At the start of the program, the last week's counts, from the oldest (least-significant byte) to most recent, are: 0, 2, 5, 3, 7, 8 and 4.

## 2. Check what are the current counts for this week

Implement the `current_week_counts` function that takes no parameter and returns:

- A copy of current week's counts as a 8-byte number, where each byte represent a day's count, in order from the oldest (least-significant byte) to most recent.
- The number of days already with counts in the current week, as a 8-byte number.

All days after the most recent one should have its corresponding byte zeroed-out.

At the start of the program, there is no count for the current week.

~~~~exercism/note
In order to return two integers from a function, you should use both `rax` and `rdx` registers:

```x86asm
returning_two_values:
    mov rax, rdi
    mov rdx, rsi
    ret
```
~~~~

## 3. Save count for each day

Implement the `save_count` function which takes as parameter the most recent count, as a 1-byte number, and saves it in a new entry for the current week.
This function has no return value.

If there is already 7 entries in the current week before this function is called, the current week becomes the last week and the new entry is the first day of a new current week.

## 4. Check how many birds visited today

Implement the `today_count` function that has no parameter and returns the most recent entry for the current week, as a 1-byte number.

You can consider that this function will only be called after at least one day's count was added.

## 5. Update today's count

Sometimes after you finish counting birds for a day, but before you leave, you notice some new birds arriving.

Implement the `update_today_count` function that has no return value and adds a certain number of birds to the most recent entry for the current week.
This function takes as parameter the number of birds to be added, as a 1-byte number.

You can consider that this function will only be called after at least one day's count was added.

## 6. Insert new entries in bulk

Sometimes you are away to visit family.
On those occasions, you have a camera monitoring your garden, so you can update counts for the entire week.

Implement the `update_week_counts` function that has no return value and inserts counts for an entire week in one go.
It takes as parameter a 8-byte number, where each byte represent a day's count, in order from the oldest to most recent.
The last byte in the input parameter has no meaning and must be zeroed-out.

Once a new week is inserted, the current week becomes the last week and the inserted week becomes the current week.

You can consider that this function will only be called after all days in the current week were already filled.

## Source

### Created by

- @oxe-i