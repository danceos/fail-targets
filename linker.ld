/* Kernel entry function */
ENTRY(_start)

OUTPUT_FORMAT(elf32-i386)

SECTIONS {

    /DISCARD/ : {
        *(".text.inlined*")
        *(.comment)
        *(.eh_frame)
        *(.note.gnu.build-id)
    }

    /* Set kernel start address */
    . = 0x100000;

    /* Code and readonly data */
    .text : {
        /* fill gaps with int3 opcode to detect invalid jumps */
        FILL(0xcc)

        /* multiboot header */
        multiboot_header = .;
        KEEP (*(".rodata.multiboot"))

        /* /\* fixed address for IRQ handlers *\/ */
        /* . = 0x1000; */

        /* /\* start of interrupt handlers *\/ */
        /* _stext_irqs = .; */

        /* /\* IRQ Handlers *\/ */
        /* KEEP (*(".text.irqhandlers*")) /\* ASM *\/ */
        /* KEEP (*(".text.irq_handler*")) /\* C *\/ */
        /* *(".text.isrs*") /\* C *\/ */
        /* *(".text.isr_*") /\* C *\/ */
        /* KEEP (*(".text.OSEKOS_ISR*")) */
        /* KEEP (*(".text.idt")) /\* ASM *\/ */

        /* /\* sysenter handler *\/ */
        /* KEEP (*(".text.sysenter_syscall")) */

        /* _etext_irqs = .; */
        /* . += 16; /\* padding after data, workaround for import-trace *\/ */

        KEEP (*(".text.startup"))
        *(".text*")
        *(".rodata*")
    }

    /* Data and Stacks */
    . = 0x200000;
    .data : {
        KEEP (*(".startup_stack"))
        KEEP (*(".kernel_stack"))
        *(".data*")
        *(COMMON);
    }

    /* Memory-mapped I/O APIC */
    _sioapic = 0xFEC00000;
    ioapic = 0xFEC00000;
    _eioapic = 0xFEC00FFF;

    /* Memory-mapped Local APIC */
    _slapic = 0xFEE00000;
    lapic = 0xFEE00000;
    _elapic = 0xFEE00FFF;
}
