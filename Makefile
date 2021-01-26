FAIL_DIR     ?= ~/fail
FAIL_BIN     ?= ${FAIL_DIR}/build/bin
BOCHS_RUNNER ?= python ${FAIL_DIR}/tools/bochs-experiment-runner/bochs-experiment-runner.py
FAIL_SERVER  ?= ${FAIL_BIN}/generic-experiment-server
FAIL_TRACE   ?= ${FAIL_BIN}/fail-generic-tracing
FAIL_INJECT  ?= ${FAIL_BIN}/fail-generic-experiment
FAIL_IMPORT  ?= ${FAIL_BIN}/import-trace --enable-sanitychecks
FAIL_PRUNE   ?= ${FAIL_BIN}/prune-trace


all: main/system.iso


%/system.elf: %/system.o startup.o
	${CC} -Wl,-T linker.ld $^ -m32 -static -nostdlib  -Wl,--build-id=none -o $@

%/system.o: %.c 
	mkdir -p $(shell dirname $@)
	${CC} $< -o $@ -O2 -std=c11 -m32 -c -ffunction-sections

startup.o: startup.s
	${CC} startup.s -m32  -c -o startup.o -ffunction-sections

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
	${BOCHS_RUNNER} -e $< -i $(shell dirname $<)/system.iso -1 \
		-V vgabios.bin -b BIOS-bochs-latest \
		-f ${FAIL_TRACE} -- \
		-Wf,--start-symbol=os_main \
		-Wf,--save-symbol=os_main \
		-Wf,--end-symbol=stop_trace \
		-Wf,--check-bounds \
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
	${FAIL_IMPORT} -t $<  -i mem  -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b mem
	${FAIL_IMPORT} -t $<  -i regs  -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b regs --flags
	${FAIL_IMPORT} -t $<  -i regs  -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b ip --no-gp --ip
	${FAIL_IMPORT} -t $<  -i FullTraceImporter -v $(shell dirname $<) -b ip
	${FAIL_IMPORT} -t $<  -i ElfImporter --objdump objdump -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b ip 
	${FAIL_IMPORT} -t $<  -i ElfImporter --objdump objdump -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b mem
	${FAIL_IMPORT} -t $<  -i ElfImporter --objdump objdump -e $(shell dirname $<)/system.elf -v $(shell dirname $<) -b regs
	${FAIL_PRUNE} -v $(shell dirname $<) -b %% --overwrite
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
	${FAIL_SERVER} -v $(subst server-,,$@) -b %


import-jump-%: %/trace.pb
	${FAIL_BIN}/import-trace -t $<  -i RandomJumpImporter \
		--jump-from $(shell dirname $<).map \
		--jump-to $(shell dirname $<).map \
		-e $(shell dirname $<)/system.elf \
		-v $(shell dirname $<)/jump -b jump
	${FAIL_PRUNE} -v $(shell dirname $<)/jump -b %% --overwrite

server-jump-%:
	${FAIL_SERVER} --inject-randomjumps -v $(subst server-jump-,,$@)/jump -b %


client-%:
	${BOCHS_RUNNER} -e $(subst client-,,$@)/system.elf \
		-j $(shell getconf _NPROCESSORS_ONLN) \
		-i $(subst client-,,$@)/system.iso  \
		-V vgabios.bin -b BIOS-bochs-latest \
		-f ${FAIL_INJECT} -- \
		-Wf,--state-dir=$(subst client-,,$@)/state \
		-Wf,--trap -Wf,--timeout=10 \
		-Wf,--ok-marker=stop_trace \
		-Wf,--fail-marker=fail_marker \
		-Wf,--catch-write-textsegment \
		-Wf,--catch-outerspace \
		2>/dev/null | grep -B 2 -A 8 'INJECT'

inject-%:
	${BOCHS_RUNNER} -e $(subst inject-,,$@)/system.elf \
		-j 1 \
		-i $(subst inject-,,$@)/system.iso  \
		-V vgabios.bin -b BIOS-bochs-latest \
		-f ${FAIL_INJECT} -- \
		-Wf,--state-dir=$(subst inject-,,$@)/state \
		-Wf,--trap -Wf,--timeout=10 \
		-Wf,--ok-marker=stop_trace \
		-Wf,--fail-marker=fail_marker \
		-Wf,--catch-write-textsegment \
		-Wf,--catch-outerspace -Wf,--catch-outerspace

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
			ORDER BY variant, benchmark,sum(t.time2-t.time1+1);" | mysql -t

resultbrowser:
	resultbrowser -s 0.0.0.0

# Do never remove implicitly generated stuff
.SECONDARY:
