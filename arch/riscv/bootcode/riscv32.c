#include "boot.h"

asm (
".text" "\n"
".global _start" "\n"
"_start:" "\n"
"       la     sp, __sp" "\n"
"       la     t0, __stack_size" "\n"
"       add    sp, sp, t0" "\n"
"       la     t0,  os_main" "\n"
"       jr     t0" "\n"
       );
