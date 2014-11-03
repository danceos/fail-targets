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
	@echo "****************************************************************\n\
* The next step is to trace a golden run. The golden run executes the\n\
* system-under-test (SUT) within the Bochs emulator. A trace file is \n\
* produced and saved as main/trace.pb\n\
*\n\
*    $ make trace-$(shell dirname $<)\n\
****************************************************************"



trace-%: %/system.elf %/system.iso
	bochs-experiment-runner.py -e $< -i $(shell dirname $<)/system.iso -1 \
		-V vgabios.bin -b BIOS-bochs-latest \
		-f fail-x86-tracing -- \
		-Wf,--start-symbol=os_main \
		-Wf,--save-symbol=os_main \
		-Wf,--end-symbol=stop_trace \
		-Wf,--state-file=$(shell dirname $<)/state \
		-Wf,--trace-file=$(shell dirname $<)/trace.pb -Wf,--elf-file=$< -q
	@echo "****************************************************************\n\
* The trace is now generated. It can be viewed with\n\
*\n\
*   $ dump-trace $(shell dirname $<)/trace.pb\n\
*\n\
* Next, we have to import the trace into the database\n\
*\n\
*    $ make import-$(shell dirname $<)\n\
****************************************************************"


import-%: %/trace.pb
	import-trace -t $<  -i mem  -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b mem
	import-trace -t $<  -i regs  -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b regs --flags
	import-trace -t $<  -i regs  -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b ip --no-gp --ip
	import-trace -t $<  -i ElfImporter --objdump objdump -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b ip 
	import-trace -t $<  -i ElfImporter --objdump objdump -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b mem
	import-trace -t $<  -i ElfImporter --objdump objdump -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b regs

	prune-trace -v $(shell dirname $<) -b %% --overwrite

	@echo "****************************************************************\n\
* The golden run sits now within the MySQL database. If you are interested,\n\
* use the 'mysql' command to inspect the curent state of the DB. The tables\n\
* trace, fsppilot, and fspgroup are of special interest.\n\
*\n\
* Next, we have to run the campaign sever and the injection client\n\
*\n\
*   $ make server-$(shell dirname $<) &\n\
*   $ make client-$(shell dirname $<) \n\
****************************************************************"

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
		-Wf,--catch-write-outerspace 2>/dev/null | grep -C 4 'INJECT'

	@echo "****************************************************************\n\
* Congratiulations! You've run your first FAIL* injection campaign.\n\
* The results can be viewd with\n\
*   $ make result-$(subst client-,,$@)\n\
*\n\
* For a more detailed information, have a look at the web-based resultbrowser.\n\
*\n\
*   $ make resultbrowser\n\
****************************************************************"

result-%:
	@echo "select variant, benchmark, resulttype, sum(t.time2 - t.time1 + 1)\
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
