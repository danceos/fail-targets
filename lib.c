#pragma once

#define INLINE   __attribute__((always_inline)) inline
#define NOINLINE __attribute__((noinline))

#define __QUOTE(x) #x
#define QUOTE(x) __QUOTE(x)

#define MARKER(str) __asm__ volatile(QUOTE(str) ":"                      \
                                 : /* no inputs */                   \
                                 : /* no outputs */                  \
                                 : "memory", ARCH_ASM_CLOBBER_ALL    \
        )

#ifndef DEBUG
#define MAIN() void os_main(void)
#define PRINT_DEBUG(...)
#else
#include <stdio.h>
#define MARKER(str) printf(QUOTE(str) "\n")
#define DEBUG 1
#define PRINT_DEBUG(...) printf(__VA_ARGS__)
#define MAIN() void main(int argc, char** argv)
#endif
