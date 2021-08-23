#pragma once

#define INLINE   __attribute__((always_inline)) inline
#define NOINLINE __attribute__((noinline))

#define __QUOTE(x) #x
#define QUOTE(x) __QUOTE(x)

#ifndef MARKER
#define MARKER(str) __asm__ volatile(QUOTE(str) ":"                      \
                                 : /* no inputs */                   \
                                 : /* no outputs */                  \
                                 : "memory", ARCH_ASM_CLOBBER_ALL    \
        )
#endif

#ifndef MAIN
#define MAIN() void os_main(void)
#endif

#ifndef POSIX_PRINTF
#define POSIX_PRINTF(...)
#endif


typedef __UINT8_TYPE__ uint8_t;
typedef __UINT16_TYPE__ uint16_t;
typedef __UINT32_TYPE__ uint32_t;

typedef __INT8_TYPE__ int8_t;
typedef __INT16_TYPE__ int16_t;
typedef __INT32_TYPE__ int32_t;
