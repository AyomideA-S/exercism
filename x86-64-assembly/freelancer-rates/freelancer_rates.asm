default rel

section .data
    billable_hours dq 8.0   ; 8 billable hours in a workday
    billable_days dq 22.0   ; 22 billable days in a month
    percent_100 dq 100.0    ; Constant value for percentage calculations

section .text

global daily_rate
; daily_rate function
; Arguments:
;   xmm0: An hourly rate (64-bit floating-point number)
; Returns:
;   xmm0: The daily rate (64-bit floating-point number)
daily_rate:
    movsd xmm8, qword [billable_hours]  ; Load billable hours into xmm8
    mulsd xmm0, xmm8                    ; Calculate daily rate by multiplying hourly rate with billable hours
    ret

global apply_discount
; apply_discount function
; Arguments:
;   xmm0: A price (64-bit floating-point number)
;   xmm1: A discount in percent (64-bit floating-point number)
; Returns:
;   xmm0: The price with discount applied (64-bit floating-point number)
apply_discount:
    movsd xmm2, qword [percent_100] ; Load 100 into xmm2 for percentage calculation
    subsd xmm2, xmm1                ; Calculate (100 - discount) and store in xmm2
    divsd xmm2, qword [percent_100] ; Calculate (100 - discount) / 100 and store in xmm2
    mulsd xmm0, xmm2                ; Apply the discount to the price by multiplying the original price with the discount factor
    ret

global monthly_rate
; monthly_rate function
; Arguments:
;   xmm0: An hourly rate (64-bit floating-point number)
;   xmm1: A discount in percent (64-bit floating-point number)
; Returns:
;   rax: The discounted monthly rate (64-bit integer, rounded up)
monthly_rate:
    call daily_rate                     ; Calculate the daily rate and store it in xmm0
    movsd xmm2, qword [billable_days]   ; Load billable days into xmm2
    mulsd xmm0, xmm2                    ; Calculate monthly rate by multiplying daily rate with billable days
    call apply_discount                 ; Apply discount to the monthly rate
    roundsd xmm0, xmm0, 2               ; Round up the result to the nearest integer (2 means round up)
    cvtsd2si rax, xmm0                  ; Convert the rounded result to an integer and store it in rax
    ret

global days_in_budget
; days_in_budget function
; Arguments:
;   rdi: A budget as a 64-bit unsigned integer
;   xmm0: An hourly_rate as a 64-bit floating-point number
;   xmm1: A discount in percent as a 64-bit floating-point number
; Returns:
;   eax: The number of complete days of work the budget covers as a 32-bit unsigned integer, rounded down
days_in_budget:
    call daily_rate                     ; Calculate the daily rate and store it in xmm0
    call apply_discount                 ; Apply discount to the daily rate
    cvtsi2sd xmm1, rdi                  ; Convert the budget from an integer to a double and store in xmm1
    divsd xmm1, xmm0                    ; Divide the budget by the daily rate
    roundsd xmm0, xmm1, 1               ; Round down the result to the nearest integer (1 means round down)
    cvtsd2si eax, xmm0                  ; Convert the rounded result to an integer and store it in eax
    ret

%ifidn __OUTPUT_FORMAT__,elf64
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
