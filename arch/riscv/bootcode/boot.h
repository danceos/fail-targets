#pragma once

#if defined(__riscv) && !defined(__CHERI__)
#define RISCV 1
#define ARCH_ASM_CLOBBER_ALL NO_CAP_REGS

#elif defined(__riscv) && defined(__CHERI__)
#define RISCVCHERI 1
#define ARCH_ASM_CLOBBER_ALL NO_CAPS_REGS, CAP_REGS

#else
#warning compiling for unknown architecture, using stdlib malloc.
#endif

#define NO_CAP_REGS "ra","sp","gp","tp","t0","t1","t2","t3","t4","t5","t6","s0","s1","s2","s3","s4","s5","s6","s7","s8","s9","s10","s11","a0","a1","a2","a3","a4","a5","a6","a7"

#define CAP_REGS "cra","csp","cgp","ctp","ct0","ct1","ct2","ct3","ct4","ct5","ct6","cs0","cs1","cs2","cs3","cs4","cs5","cs6","cs7","cs8","cs9","cs10","cs11","ca0","ca1","ca2","ca3","ca4","ca5","ca6","ca7"

#ifndef __ASSEMBLER__

#if __riscv_xlen == 32
typedef unsigned int size_t;
#elif __riscv_xlen == 64
typedef unsigned long size_t;
#elif DEBUG
#else
#warning Unknown __riscv_xlen value
typedef unsigned long size_t;
#endif
#endif
