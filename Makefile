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
	import-trace -t $<  -i ElfImporter --objdump objdump -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b ip 
	import-trace -t $<  -i ElfImporter --objdump objdump -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b mem
	import-trace -t $<  -i ElfImporter --objdump objdump -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b regs

	prune-trace -v $(shell dirname $<) -b %% --overwrite

server-%:
	generic-experiment-server -v $(subst server-,,$@) -b %

client-%: 
	bochs-experiment-runner.py -e $(subst client-,,$@)/system.elf \
		-j $(shell getconf _NPROCESSORS_ONLN) \
		-i $(subst client-,,$@)/system.iso  \
		-V vgabios.bin -b BIOS-bochs-latest \
		-f generic-experiment-client -- \
		-Wf,--state-dir=$(subst client-,,$@)/state \
		-Wf,--trap -Wf,--timeout=10 \
		-Wf,--ok-marker=stop_trace \
		-Wf,--fail-marker=fail_marker \
		-Wf,--catch-write-textsegment \
		-Wf,--catch-write-outerspace

result-%:
	@echo "select variant, 'all', resulttype, sum(t.time2 - t.time1 + 1)\
			FROM variant v \
			JOIN trace t ON v.id = t.variant_id \
			JOIN fspgroup g ON g.variant_id = t.variant_id AND g.instr2 = t.instr2 AND g.data_address = t.data_address\
			JOIN result_GenericExperimentMessage r ON r.pilot_id = g.pilot_id  \
			JOIN fsppilot p ON r.pilot_id = p.id \
			GROUP BY v.id, resulttype \
			ORDER BY variant, sum(t.time2-t.time1+1);" | mysql -t

resultbrowser:
	resultbrowser -s 0.0.0.0

# Do never remove implicitly generated stuff
.SECONDARY:
