; abi stuff (i keep forgetting)
; x0-x7   : args/return
; x9-x15  : temporaries
; x19-x28 : callee-saved
; d0-d7   : float args/return
;
; note: need leading underscore for c symbols on mac (_asm_add)

.section __TEXT,__text
.align 2


; integer ops (for the history index arithmetic)

; int64_t asm_clamp(int64_t val, int64_t min, int64_t max)
; used internally — clamps val to [min, max]
; args: x0=val, x1=min, x2=max
.global _asm_clamp
_asm_clamp:
    cmp     x0, x1
    csel    x0, x1, x0, lt     ; if val < min, x0 = min
    cmp     x0, x2
    csel    x0, x2, x0, gt     ; if val > max, x0 = max
    ret


; float math (d0, d1 -> d0)

; double asm_fadd(double a, double b)
.global _asm_fadd
_asm_fadd:
    fadd    d0, d0, d1
    ret

; double asm_fsub(double a, double b)
.global _asm_fsub
_asm_fsub:
    fsub    d0, d0, d1
    ret

; double asm_fmul(double a, double b)
.global _asm_fmul
_asm_fmul:
    fmul    d0, d0, d1
    ret

; double asm_fdiv(double a, double b)
; returns nan if b is 0, ieee 754 handles it
.global _asm_fdiv
_asm_fdiv:
    fdiv    d0, d0, d1
    ret

; double asm_fsqrt(double a)
; single arg in d0, result in d0
; fsqrt is one instruction, nice
.global _asm_fsqrt
_asm_fsqrt:
    fsqrt   d0, d0
    ret

; double asm_fneg(double a)
; flip sign
.global _asm_fneg
_asm_fneg:
    fneg    d0, d0
    ret

; double asm_fpct(double a)
; divide by 100 (percentage button)
; could just call asm_fdiv but wanted to try fmov with immediate
.global _asm_fpct
_asm_fpct:
    fmov    d1, #10.0
    fmul    d1, d1, d1          ; d1 = 100
    fdiv    d0, d0, d1
    ret


; 1.0 / a using neon reciprocal approximation
; x1 = x0 * (2.0 - a * x0)
; close enough for a calculator display (~23 bits)

.global _asm_neon_reciprocal
_asm_neon_reciprocal:
    ; frecpe works on single (s) not double (d), so we convert
    fcvt    s0, d0              ; d0 → s0 (double to single)
    frecpe  s1, s0              ; s1 = approx 1/s0
    frecps  s2, s0, s1          ; s2 = 2.0 - s0*s1  (NR multiplier)
    fmul    s1, s1, s2          ; s1 = refined estimate
    fcvt    d0, s1              ; back to double
    ret


; history buffer (circular)
; entry = 48 bytes:
;   0: operand_a (double)
;   8: operand_b (double)
;   16: result (double)
;   24: op_char (int32)
;   28: padding
;
; max 20 entries. overwrite oldest when full.

.section __DATA,__bss
.align 3

; 20 entries × 48 bytes = 960 bytes
_hist_buf:  .space 960

; write index (0..19)
_hist_idx:  .space 8

; how many entries are actually written (0..20)
_hist_count: .space 8


.section __TEXT,__text
.align 2

; constants
.set HIST_MAX,       20
.set HIST_ENTRY_SZ,  48


; void asm_hist_push(double a, double b, double result, int32_t op)
; args: d0=a, d1=b, d2=result, w0=op
;
; saves callee-saved regs because we do a bunch of work here
.global _asm_hist_push
_asm_hist_push:
    stp     x29, x30, [sp, #-32]!
    stp     x19, x20, [sp, #16]
    mov     x29, sp

    ; load current index and count
    adrp    x9,  _hist_idx@PAGE
    add     x9,  x9,  _hist_idx@PAGEOFF
    ldr     x10, [x9]                   ; x10 = current write index

    adrp    x11, _hist_count@PAGE
    add     x11, x11, _hist_count@PAGEOFF
    ldr     x12, [x11]                  ; x12 = count

    ; compute byte offset into buffer: index * HIST_ENTRY_SZ
    mov     x19, x10
    mov     x20, #HIST_ENTRY_SZ
    mul     x13, x19, x20               ; x13 = byte offset

    ; get pointer to buffer
    adrp    x14, _hist_buf@PAGE
    add     x14, x14, _hist_buf@PAGEOFF
    add     x14, x14, x13              ; x14 = &hist_buf[index]

    ; write the entry
    str     d0, [x14, #0]              ; operand_a
    str     d1, [x14, #8]              ; operand_b
    str     d2, [x14, #16]             ; result
    str     w0, [x14, #24]             ; op char

    ; advance write index (wrap around at HIST_MAX)
    add     x10, x10, #1
    mov     x15, #HIST_MAX
    udiv    x16, x10, x15
    msub    x10, x16, x15, x10         ; x10 = x10 % HIST_MAX  (no umod instruction, classic)
    str     x10, [x9]

    ; update count (capped at HIST_MAX)
    add     x12, x12, #1
    cmp     x12, #HIST_MAX
    b.le    Lpush_store_count
    mov     x12, #HIST_MAX
Lpush_store_count:
    str     x12, [x11]

    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret


; int64_t asm_hist_count()
; returns number of valid entries in the history buffer
.global _asm_hist_count
_asm_hist_count:
    adrp    x0, _hist_count@PAGE
    add     x0, x0,  _hist_count@PAGEOFF
    ldr     x0, [x0]
    ret


; convert logical index (0 = oldest) to raw buffer index
; raw = (write_idx - count + logical_index) % MAX
.global _asm_hist_get
_asm_hist_get:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    ; save args
    mov     x9,  x0                     ; x9  = logical index
    mov     x10, x1                     ; x10 = *out_a
    mov     x11, x2                     ; x11 = *out_b
    mov     x12, x3                     ; x12 = *out_result
    mov     x13, x4                     ; x13 = *out_op

    ; load count and write index
    adrp    x14, _hist_count@PAGE
    ldr     x15, [x14, _hist_count@PAGEOFF]   ; x15 = count

    adrp    x16, _hist_idx@PAGE
    ldr     x17, [x16, _hist_idx@PAGEOFF]     ; x17 = next write index

    ; compute raw index:
    ;   raw = (write_idx - count + logical_index) % HIST_MAX
    ;   add HIST_MAX first to avoid underflow (unsigned arithmetic)
    mov     x0, #HIST_MAX
    add     x0, x0, x17                ; x0 = HIST_MAX + write_idx
    sub     x0, x0, x15                ; x0 -= count
    add     x0, x0, x9                 ; x0 += logical_index

    ; mod by HIST_MAX
    mov     x1, #HIST_MAX
    udiv    x2, x0, x1
    msub    x0, x2, x1, x0             ; x0 = x0 % HIST_MAX

    ; byte offset
    mov     x1, #HIST_ENTRY_SZ
    mul     x0, x0, x1

    ; pointer into buffer
    adrp    x1, _hist_buf@PAGE
    add     x1, x1, _hist_buf@PAGEOFF
    add     x1, x1, x0                 ; x1 = &entry

    ; read fields out
    ldr     d0, [x1, #0]
    str     d0, [x10]                  ; *out_a = entry.a

    ldr     d0, [x1, #8]
    str     d0, [x11]                  ; *out_b = entry.b

    ldr     d0, [x1, #16]
    str     d0, [x12]                  ; *out_result = entry.result

    ldr     w0, [x1, #24]
    str     w0, [x13]                  ; *out_op = entry.op

    ldp     x29, x30, [sp], #16
    ret


; void asm_hist_clear()
; just reset count and index
.global _asm_hist_clear
_asm_hist_clear:
    adrp    x0, _hist_idx@PAGE
    str     xzr, [x0, _hist_idx@PAGEOFF]

    adrp    x0, _hist_count@PAGE
    str     xzr, [x0, _hist_count@PAGEOFF]
    ret