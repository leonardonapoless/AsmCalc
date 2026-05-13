#pragma once
#include <stdint.h>

// integer utils
int64_t asm_clamp(int64_t val, int64_t min, int64_t max);

// floating-point arithmetic (NEON scalar
double asm_fadd(double a, double b);
double asm_fsub(double a, double b);
double asm_fmul(double a, double b);
double asm_fdiv(double a, double b);
double asm_fsqrt(double a);
double asm_fneg(double a);
double asm_fpct(double a);

// reciprocal (neon)
double asm_neon_reciprocal(double a);

// history
// op uses ascii: +, -, *, /, r (recip), n (neg), % (pct), (sqrt)

void asm_hist_push(double a, double b, double result, int32_t op);
int64_t asm_hist_count(void);
void asm_hist_get(int64_t index, double *out_a, double *out_b,
                  double *out_result, int32_t *out_op);
void asm_hist_clear(void);
