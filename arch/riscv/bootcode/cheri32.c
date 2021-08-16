#include <cheri_init_globals.h>
#include "boot.h"

asm (
".text" "\n"
".option push" "\n"
".option nocapmode" "\n"
".global _start" "\n"
"_start:" "\n"
"       lla     sp, __sp" "\n"
"       lla      t0, __stack_size" "\n"
"       cfromptr        csp, ddc, sp" "\n"
"       csetbounds      csp, csp, t0" "\n"
"       cincoffset      csp, csp, t0" "\n"
"       lla     t0, _start_purecap" "\n"
"       cfromptr        ct0, ddc, t0" "\n"
"       li      t1, 1" "\n"
"       csetflags       ct0, ct0, t1" "\n"
"       cjr     ct0" "\n"
".option pop" "\n"
);

extern void os_main();

void _start_purecap(void) {
        cheri_init_globals_3(__builtin_cheri_global_data_get(),
                __builtin_cheri_program_counter_get(),
                __builtin_cheri_global_data_get());
        os_main();
}
