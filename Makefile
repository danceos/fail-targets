all: main/system.iso

%/system.elf: %/system.o startup.o
	gcc -Wl,-T linker.ld $^ -m32 -static -nostdlib  -Wl,--build-id=none -o $@

%/system.o: %.c 
	mkdir -p $(shell dirname $@)
	gcc $< -o $@ -O2 -std=c11 -m32 -c -ffunction-sections

startup.o: startup.s
	gcc startup.s -m32  -c -o startup.o -ffunction-sections

%/system.iso: %/system.elf
	rm -rf $(shell dirname $<)/grub
	mkdir -p $(shell dirname $<)/grub/boot/grub
	cp grub.cfg $(shell dirname $<)/grub/boot/grub
	cp $< $(shell dirname $<)/grub/boot/system.elf
	grub-mkrescue -o $@ $(shell dirname $<)/grub


trace-%: %/system.elf %/system.iso
	bochs-experiment-runner.py -e $< -i $(shell dirname $<)/system.iso -1 \
		-V vgabios.bin -b BIOS-bochs-latest \
		-f fail-x86-tracing -- \
		-Wf,--start-symbol=os_main \
		-Wf,--save-symbol=os_main \
		-Wf,--end-symbol=stop_trace \
		-Wf,--state-file=$(shell dirname $<)/state \
		-Wf,--trace-file=$(shell dirname $<)/trace.pb -Wf,--elf-file=$< -q

import-%: %/trace.pb
	import-trace -t $<  -i mem  -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b mem
	import-trace -t $<  -i regs  -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b regs --flags
	import-trace -t $<  -i regs  -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b ip --no-gp --ip
	prune-trace -v $(shell dirname $<) -b %%


# Do never remove implicitly generated stuff
.SECONDARY:
