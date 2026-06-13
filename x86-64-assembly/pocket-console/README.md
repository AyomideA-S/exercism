# Pocket Console

Welcome to Pocket Console on Exercism's x86-64 Assembly Track.
If you need help running the tests or submitting your code, check out `HELP.md`.
If you get stuck on the exercise, check out `HINTS.md`, but try and solve it without using those first :)

## Introduction

## Branchless Code

The conditionals concept introduces `jcc`, the family of instructions for branching based on a condition.
A `jcc` transfers execution to another point in the program only if its condition is met.

However, modern CPUs are fast and capable of executing many instructions in parallel.
It would be too costly to stall all work while the CPU waits for a runtime check of a condition.

This is why, internally, the CPU does not wait.
It uses a **branch-predictor** to guess the outcome of a condition and starts _speculatively_ executing the predicted path.

If the prediction is correct, execution proceeds as if there was no branch.
However, if the prediction is wrong, the CPU must _discard the work done_ on the predicted path and restart on the correct one.

This is called a **branch misprediction** and it is expensive, incurring a delay.

When a branch is hard to predict, those mispredictions add up.
In those cases, it is sometimes preferable to avoid the branch entirely, so the same instructions execute regardless of the condition.
Code that selects between values without a `jcc` is called **branchless**.

There are several ways to structure code so that it branches less often, or so that the branches it does have are more predictable.
In particular, x86-64 provides two instruction families that are commonly used for writing branchless code.

### Conditional Moves

The family of instructions `cmovcc` copies the source operand into the destination only if a specific condition is met.
Otherwise, the destination is left unchanged.

The `cc` suffix follows the same naming as in `jcc`, with the same meaning:

| instruction | move if                              |
|-------------|--------------------------------------|
| `cmove`     | A == B after `cmp A, B`              |
| `cmovne`    | A != B after `cmp A, B`              |
| `cmovl`     | A < B (signed) after `cmp A, B`      |
| `cmovb`     | A < B (unsigned) after `cmp A, B`    |
| `cmovg`     | A > B (signed) after `cmp A, B`      |
| `cmova`     | A > B (unsigned) after `cmp A, B`    |

The rules are similar to `jcc`:

1. `l` and `g` are used for signed comparisons, and `b` and `a`, for unsigned.
2. Adding `e` to a suffix includes equality.
3. Adding `n` negates the condition.
4. There are also variants that refer to the flag being set.
   For example, `cmovz` and `cmovc`.

Consider the absolute value of a signed integer in `rdi`, returned in `rax`.
Written with `jcc`, the function selects one of two paths:

```x86asm
abs_branch:
    mov rax, rdi
    cmp rax, 0
    jge .done
    neg rax
.done:
    ret
```

Written with `cmovcc`, both candidate values are computed unconditionally and the conditional move picks one:

```x86asm
abs_branchless:
    mov rax, rdi
    neg rax            ; rax = -rdi
    cmp rdi, 0
    cmovge rax, rdi    ; the value in `rdi` is moved to `rax` if rdi >= 0
                       ; otherwise, it stays the same, i.e., -rdi
    ; now rax = abs(rdi)
    ret
```

The branchless version always executes the same instructions.
There is no `jcc` for the predictor to guess.

The destination of a `cmovcc` must be a register.
The source may be a register or a memory location, but not an immediate.

~~~~exercism/note
In the code above, the `neg` instruction sets several flags according to the result, including the sign flag (SF).
This means the `cmp rdi, 0` can be dropped entirely:

```x86asm
abs_branchless:
    mov rax, rdi
    neg rax            ; rax = -rdi. `neg` sets SF = 1 if the result is negative
    cmovs rax, rdi     ; if SF == 1 (i.e., rax < 0), replace rax with rdi
                       ; otherwise rax stays = -rdi, which is non-negative
    ; now rax = abs(rdi)
    ret
```

For positive `rdi`, `neg` produces a negative result and SF == 1, so `cmovs` restores `rdi`.
For zero or negative `rdi`, `neg` produces a non-negative result and SF == 0, so `rax` keeps the negated value (which is the correct absolute value).

Although `cmp` is the main way to compare values in assembly code, many instructions also set flags according to their result.
The full list of flags an instruction affects is usually listed in its [reference][reference].
For `neg` specifically, those are SF, ZF, CF, OF, and PF.

[reference]: https://www.felixcloutier.com/x86/
~~~~

### Conditional Set

The family of instructions `setcc` sets the destination operand to `1` if a specific condition is met, and to `0` otherwise.
The destination is always an _8-bit operand_.

The `cc` suffix follows the same naming as in `jcc` and `cmovcc`.
For example, `setz` sets the destination to `1` if `ZF == 1` and to `0` otherwise.

Since the destination is 8-bit, it is common to follow `setcc` with a `movzx` when a wider value is needed:

```x86asm
cmp rdi, rsi
setg al             ; al = 1 if rdi > rsi (signed), 0 otherwise
movzx eax, al       ; eax (and rax) = 1 or 0, with the upper bits cleared
```

This is a common idiom for turning a comparison result into an integer `0` or `1`.

## Instructions

You are writing firmware for the scoring system in a retro handheld console.
The machine's CPU is modest, and the scoreboard display refreshes at a fixed rate.
For the picture to stay smooth, the scoring routines must run in a predictable number of cycles regardless of what the player is doing.

You have four tasks.

~~~~exercism/note
The code for the tasks should be branchless.
Use `cmovcc`, `setcc`, and arithmetic instead of conditional jumps.
~~~~

## 1. Add a bonus without overflowing the display

The score region of the handheld's LCD has room for six decimal digits.
It cannot show any number above `999999`.
When a bonus would push the running total past that limit, the displayed total is held at the maximum rather than wrapping around.

Define a function `add_bonus` that, given a current total and a bonus to add, returns the new total clamped at `999999`.
The arguments, in order, are:

1. `total`: the current score total (always between `0` and `999999`)
2. `bonus`: the bonus to add (always non-negative)

The return value is `total + bonus` if that sum is less than or equal to `999999`, and `999999` otherwise:

```c
add_bonus(500, 100);
// => 600
add_bonus(999990, 50);
// => 999999
add_bonus(999999, 0);
// => 999999
```

Both arguments and the return value are 64-bit signed integers.

~~~~exercism/note
You may assume that `total + bonus` does not overflow a 64-bit signed integer.
~~~~

## 2. Compare two scores

The handheld keeps a small leaderboard of the player's best recent scores in its save file.
After each play, the new score is inserted into the leaderboard at the right position.
The sort routine asks which of two scores is ahead and expects the answer as a small integer.

Define a function `compare_scores` that, given two scores, returns:

- `+1` if the first score is _higher_
- `-1` if the first score is _lower_
- `0` if the two scores are _equal_

Example:

```c
compare_scores(500, 300);
// => 1
compare_scores(300, 500);
// => -1
compare_scores(500, 500);
// => 0
```

Both arguments and the return value are 64-bit signed integers.

## 3. Validate a raw score

The handheld can connect to another unit through its link cable to share scores after a multiplayer match.
The cable is electrically noisy and incoming bytes are occasionally corrupted, producing values far below the legal minimum or far above the legal maximum.
The validator clamps each incoming score into the legal range before the rest of the system sees it.

Define a function `validate_score` that, given a raw score and the legal bounds, returns the score clamped to `[min, max]`.
The arguments, in order, are:

1. `score`: the raw score received over the link cable
2. `min`: the smallest allowed score
3. `max`: the largest allowed score

The return value is `min` if `score < min`, `max` if `score > max`, and `score` otherwise.
You may assume that `min <= max`.

Example:

```c
validate_score(450, 0, 500);
// => 450
validate_score(-50, 0, 1530);
// => 0
validate_score(1234567, 0, 2999);
// => 2999
```

All arguments and the return value are 64-bit signed integers.

## 4. Track the two highest scores

At the end of each play session, the handheld scans the recent-plays log in its save file to find the two highest scores ever recorded.
The log is a plain array of 64-bit signed integers in memory.
The scan walks the array once and keeps two running maxes: the highest seen so far, and the second highest.

Note that both numbers should be at least `0`.
Any negative number is disregarded.

A first version of the function was written with cascading conditional jumps.
For each candidate, the code asks where it fits (above first, between first and second, or nowhere) and shifts the running maxes accordingly, discarding any negative result.

This works.
However, since the input values are random, each conditional jump leads to many branch mispredictions.
This is why you have decided to refactor the main loop to be branchless.

Below is the function with the branchy section commented out:

```x86asm
; rdi = output buffer for two elements, rsi = input array address, rdx = number of elements in array
top_two:
    xor r8d, r8d                   ; first  = 0
    xor r9d, r9d                   ; second = 0
    xor ecx, ecx                   ; index = 0
    test rdx, rdx
    jz .done

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                       BRANCHY CODE TO REFACTOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;.loop:
;    mov rax, qword [rsi + 8*rcx]   ; candidate
;    inc rcx
;    cmp rax, r8
;    jle .check_second              ; candidate <= first, try second
;    mov r9, r8                     ; second = first
;    mov r8, rax                    ; first  = candidate
;    cmp rcx, rdx
;    jb .loop                       ; go to next iteration
;    jmp .done                      ; otherwise, we are done
;.check_second:
;    cmp rax, r9
;    jle .loop                      ; candidate <= second, go to next iteration
;    mov r9, rax                    ; second = candidate
;    cmp rcx, rdx
;    jb .loop                       ; go to next iteration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.done:
    mov qword [rdi], r8            ; save first
    mov qword [rdi + 8], r9        ; save second
    ret
```

Replace the commented-out section with a branchless implementation.
The only jump permitted in the new code is the one that jumps back to the start of the loop to check a new element in the array.

The function has no return value and takes the same arguments as the branchy version:

1. `out`: output buffer where the function will write the top two non-negative scores in descending order, as 64-bit signed integers
2. `array`: input array of 64-bit signed integers
3. `length`: the number of elements in the array, as a 64-bit unsigned integer

~~~~exercism/note
If the array contains duplicate values, the duplicates may appear in both output slots if they are the top two scores.
~~~~

## Source

### Created by

- @oxe-i