#pragma once

#define ARCH_ASM_CLOBBER_ALL "r0", "r1", "r2"

extern void os_main(void) __attribute__((noinline));

void main() {
    os_main();
    __asm__ volatile ("sleep");
}

