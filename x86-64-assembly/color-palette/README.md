# Color Palette

Welcome to Color Palette on Exercism's x86-64 Assembly Track.
If you need help running the tests or submitting your code, check out `HELP.md`.
If you get stuck on the exercise, check out `HINTS.md`, but try and solve it without using those first :)

## Introduction

Memory is usually mapped for a program by the Operating System (OS) in a general layout:

| address | memory region          |
| :-----: | :--------------------- |
|  high   | stack                  |
|         | ...                    |
|         | heap                   |
|         | read-and-write segment |
|         | code/read-only segment |
|   low   | reserved               |

Memory in segments is organized in sections, with different permissions.

The functions we have defined until now were all in **section .text**.
This section holds read-only executable data.
Other sections are used to declare data variables, that may be read-only or read-and-write, but are not executable.

## Section .data

The initialized data is declared in the **section .data**.

In NASM (The Netwide Assembler - the assembler used by this track), an initialized variable has a name, a directive that indicates the data size, and a list of values separated by comma.
Each of these is separated with a space from the other and the label might optionally be followed by a `:`.

The main directives and their related data sizes are:

| directive | size    |
| :-------: | :------ |
|    db     | 1 byte  |
|    dw     | 2 bytes |
|    dd     | 4 bytes |
|    dq     | 8 bytes |

For instance, this declares a byte variable named `space` with the value `10`:

```x86asm
section .data
    space db 10
```

Variables declared in `section .data` are mutable, i.e., they are read-and-write.
They also have _static_ storage duration, which means they exist for the entire program runtime.

## Section .rodata

The **section .rodata** is similar to `section .data`.
Both sections contain initialized data, which is declared in the same way and have the same storage duration.

The main difference between them is that data in `section .rodata` is immutable, i.e., read-only.

~~~~exercism/note
Constants defined with `equ` are different than those defined in `section .rodata`.

A constant defined with `equ` does not occupy space in memory and is directly substituted for its value by the assembler.
It is in fact a placeholder for its value.

On the other hand, constants defined in `section .rodata` are actually stored in memory, having an address.
~~~~

## Accessing data

### Labels and Indirection

Declared data must have a name associated with it.
This name is called a **label**.

A label is a symbol that encodes the specific address of data in memory.
**Addresses in x86-64 are 64-bit values**.

In NASM, trying to access data directly with its label does not yield the memory allocated, but its address:

```x86asm
section .data
    example dq 27 ; this declares a 8-byte variable initialized with 27

section .text
fn:
    mov rax, example ; this stores the address of the declared variable in rax, not its contents
    ...
```

In order to access the contents of a memory address, it is necessary to _dereference_ it.
This is called **indirection**.

In NASM, this is done with `[]`:

```x86asm
section .data
    example dq -27 ; this declares a 8-byte variable initialized with -27

section .text
fn:
    mov rax, [example] ; this dereferences example and access the value stored in memory (-27)
    ...
```

However, there are some situations when there might be an ambiguity regarding the size of the memory dereferenced.
In those cases, a prefix specifying this size must be used.

These are the most important prefixes and their sizes in a typical x86-64 program:

| prefix | size    |
| :----- | :------ |
| byte   | 1 byte  |
| word   | 2 bytes |
| dword  | 4 bytes |
| qword  | 8 bytes |

The last example can be rewritten with the size prefix:

```x86asm
section .data
    example dq 27 ; this declares a 8-byte variable initialized with 27

section .text
fn:
    mov rax, qword [example] ; this dereferences example and access the value stored in memory (27)
    ...
```

It is good practice to always use a prefix when dereferencing memory.

### Writing to memory

Writing to memory is done in the same way, by dereferencing an address:

```x86asm
section .data
    example1 db 10            ; example1 is a 1-byte memory location initialized with value 10
    example2 dq -456          ; example2 is a 8-byte memory location initialized with value -456
    example3 dd 54            ; example3 is a 4-byte memory location initialized with value 54

section .text
fn:
    mov byte [example1], 20   ; example1 now has value 20
    mov qword [example2], rdx ; example2 now has value equal to the contents in rdx
    mov dword [example3], eax ; example3 now has value equal to the contents in eax
```

Note that you can use memory operands in most instructions without first loading the contents in a register.
However, it is not usually possible to use them in both source and destination operand, only one of the two:

```x86asm
section .data
    example4 dw 4
    example5 dq -8
    example6 dd 15

section .text
fn:
    add word [example4], 5     ; example4 is now a 2-byte memory location with the value 4 + 5 = 9
    imul rax, qword [example5] ; rax = rax * (-8)
    ; this is not possible -> sub dword [example6], dword [example6]
```

### The LEA instruction

Although a `mov` can be used to store the address of a variable in a register, there is an instruction with this specific purpose: **lea**.

This instruction uses a memory-form operand, but it does _not_ read memory.
Instead, it computes the effective address expression and writes the result in the destination operand:

```x86asm
lea rax, [example] ; this stores the address of 'example' in rax
```

It is more idiomatic to use `lea` to compute and store memory addresses in registers.

### Relative Addressing

When accessing memory locations, the default behavior in NASM is to generate **absolute addresses**.
This means that the assembler usually produces a fixed memory address.

However, this can sometimes introduce security concerns, by making addresses predictable to an attacker.

One possible mitigation for this involves randomizing locations of memory regions, so that an attacker can't reliably predict addresses.
In order to do that, executables must be built as **PIE (Position Independent Executable)**.

However, in a PIE, the final address of a variable is not known at link time.
So, code instead computes addresses as an offset from the value in a special register called `rip`, which points to the next instruction to be executed.

This is usually called **RIP-relative addressing**.

In NASM you can request RIP-relative access with the `rel` operator:

```x86asm
mov rax, qword [rel variable]
```

Relative addressing can also be made the default for a source file with `default rel` at the top.

All exercises in this track are compiled and linked as PIE, so `rel` should be used to generate relative addresses.

### Visibility

Labels (functions and data) defined in any section (e.g., .text, .data, .rodata) are visible within the same source file.
If declared `global`, they are visible to other source files as well.

Conversely, labels defined in other source files are visible to the current source file if declared `extern`.
In this case, there is no indication of data size in assembly, this must be known in advance.

```x86asm
default rel

section .data

global number1 ; 'number1' is a variable visible to other source files
number1 db 200

extern number2 ; 'number2' is a variable visible to the current source file, but defined in another

section .text

extern sum ; sum is a function visible to the current source file, but defined in another

fn:
    mov dil, byte [number1]
    mov sil, byte [number2]
    call sum
    ...
```

## Instructions

Your friend José is a teacher in a local school.
He had an idea for some fun experiments to show how colors can be combined to produce different ones.

He asked for your help with those experiments.

~~~~exercism/note
A color is represented in this exercise by a 32-bit (4-byte) number, encoding its `RGB` value.

A `RGB` value consists of 3 channels, _Red_, _Green_ and _Blue_, each one occupying 8 bits (1 byte).
The fourth byte is usually reserved for the _Alpha_ channel, but in this exercise its value will be empty (`0`).
~~~~

## 1. Get the RGB value for a color

The values for each color are already stored in a table, defined in another source file.
A color is identified by an unique address in this table.

Define a function `get_color_value` that returns the 32-bit value for a color.
This function takes as parameter a valid address for this color in the color table.

```c
get_color_value(black)
// => 0
```

**Hint** - 32 bits are equivalent to 4 bytes.

## 2. Add base color

In order to mix different colors, José will first fix a base one and change only the secondary color being combined with it.

Define a function `add_base_color` that saves the 32-bit value for a color in the variable `base_color`, so it can be used later.
This function has no return value and takes as parameter the address of the color in the color table.

The variable `base_color` is defined by you and must be accessible from other source files.

There will be no more than 1 base color at the same time.
If a new base color is added, the old one is discarded.

By default, at the start of the program, `base_color` should be initialized with the 32-bit value for _white_, which is `0xFFFFFF00`.

**Hint** - NASM accepts numbers defined in hexadecimal using `0x` at the start, such as in `0xFFFFFF00`.

## 3. Define constants for primary colors

José expects to make many combinations using primary colors, so he wants to have them separated for fast access.
Since he is using `RGB` to represent colors, the primary colors are:

- `RED`, with the value `0xFF000000`.
- `GREEN`, with the value `0x00FF0000`.
- `BLUE`, with the value `0x0000FF00`.

Define one constant for each of those colors.
Those constants must be accessible from other source files.

## 4. Combine colors

The colors should be combined according to a `combining_function` defined in another source file.
This function takes as parameters the 32-bit values for `base_color` and for a secondary color to be mixed with it.
It returns the 32-bit value for the combined color.

Define a function `make_color_combination` that combines two colors and saves the result in memory.
This function has no return value and takes as parameters, in this order:

- The address where the 32-bit value for the combined color should be stored.
- The address of a secondary color in the color table, to be combined with the primary color.

~~~~exercism/caution
Notice that `combining_function` may modify the values in registers you are using.
Make sure to save any variable you need in memory before calling the function.
~~~~

## Source

### Created by

- @oxe-i