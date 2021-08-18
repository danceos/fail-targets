FAIL_DOWNLOAD_URL = ${FAIL_DOWNLOAD_BASE}?job=build-avr-generic-tools

CFLAGS  += -mmcu=atmega8
LDFLAGS += -mmcu=atmega8

CC := avr-gcc

################################################################
# Build Targets
${BUILD_DIR}/%/system.o: %.c
	mkdir -p $(shell dirname $@)
	${CC} ${CFLAGS} -c $< -o $@ 

${BUILD_DIR}/%/system.elf: ${BUILD_DIR}/%/system.o
	${CC} ${LDFLAGS} $< -o $@

${BUILD_DIR}/%/system.bin: ${BUILD_DIR}/%/system.elf
	avr-objcopy -Obinary $< $@ 


${BUILD_DIR}/%/trace.pb: ${BUILD_DIR}/%/system.bin 
	${BOCHS_RUNNER} --mode avr  -1                 \
	-f ${FAIL_TRACE}                               \
	-e $(shell dirname $<)/system.elf              \
	-i $(shell dirname $<)/system.bin              \
	-- \
	-Wf,--full-trace \
	-Wf,--state-file=$(shell dirname $<)/state     \
	-Wf,--trace-file=$(shell dirname $<)/trace.pb  \
	-Wf,--start-symbol=start_trace                 \
	-Wf,--end-symbol=stop_trace                    \
	-Wf,--check-bounds

client-%:
	${BOCHS_RUNNER} --mode avr                     \
	-f ${FAIL_INJECT}                               \
	-e ${BUILD_DIR}/$(subst client-,,$@)/system.elf \
	-i ${BUILD_DIR}/$(subst client-,,$@)/system.bin \
	-j $(shell getconf _NPROCESSORS_ONLN) \
	-- \
	-Wf,--state-dir=${BUILD_DIR}/$(subst client-,,$@)/state \
	-Wf,--trap                    \
	-Wf,--timeout=1000            \
	-Wf,--ok-marker=ok_marker     \
	-Wf,--fail-marker=fail_marker
	2>/dev/null | grep -B 2 -A 8 'INJECT'

inject-%:
	${BOCHS_RUNNER} --mode avr -1                   \
	-f ${FAIL_INJECT}                               \
	-e ${BUILD_DIR}/$(subst inject-,,$@)/system.elf \
	-i ${BUILD_DIR}/$(subst inject-,,$@)/system.bin \
	-j 1 -- \
	-Wf,--state-dir=${BUILD_DIR}/$(subst inject-,,$@)/state \
	-Wf,--trap                    \
	-Wf,--timeout=1000            \
	-Wf,--ok-marker=ok_marker     \
	-Wf,--fail-marker=fail_marker

# Unfortunately, the LLVM Disassembler for AVR is crap, Therefore, no regular register injection

import-arch-%: ${BUILD_DIR}/%/trace.pb ${HOME}/.my.cnf
	${FAIL_IMPORT} -v ${ARCH}/$(patsubst import-arch-%,%,$@) -b mem  -t $< -e $(shell dirname $<)/system.elf -i mem --memory-type ram
	${FAIL_IMPORT} -v ${ARCH}/$(patsubst import-arch-%,%,$@) -b regs-trace  -t $< -e $(shell dirname $<)/system.elf -i mem --memory-type register
	${FAIL_PRUNE}  -v ${ARCH}/$(patsubst import-arch-%,%,$@) -b %% --overwrite


define arch-make-targets

build-$1: ${BUILD_DIR}/$1/system.bin

trace-$1: ${BUILD_DIR}/$1/trace.pb


endef



