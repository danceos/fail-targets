CC      := clang-11
OBJDUMP := llvm-objdump-11
CFLAGS  += -nostdlib -fno-inline-functions -fno-unroll-loops -mcmodel=medium -gdwarf-5
LDFLAGS += -nostdlib -nostartfiles -static -fuse-ld=lld  -Wl,-nostdlib -Wl,--script=arch/riscv/linker.ld


${BUILD_DIR}/startup.o: arch/riscv/bootcode/${ARCH}.c
	@mkdir -p $(dir $@)
	${CC} ${CFLAGS} -o $@ -c $^

${BUILD_DIR}/%/system.o: %.c
	@mkdir -p $(dir $@)
	${CC} ${CFLAGS} -o $@ -c $^

${BUILD_DIR}/%/system.elf:  ${BUILD_DIR}/startup.o ${BUILD_DIR}/%/system.o
	${CC} ${CFLAGS} ${LDFLAGS} -o $@ $^


${BUILD_DIR}/%/trace.pb: ${BUILD_DIR}/%/system.elf
	${FAIL_TRACE} \
	-Wf,--full-trace  \
	-Wf,--elf-file      -Wf,$<             \
	-Wf,--start-symbol  -Wf,start_trace 	\
	-Wf,--end-symbol    -Wf,stop_trace  	\
	-Wf,--check-bounds                      \
	-Wf,--state-file=$(dir $<)/state      \
	-Wf,--trace-file=$(dir $<)/trace.pb   \
	-V $<

client-%:
	${BOCHS_RUNNER} --mode riscv                    \
	-f ${FAIL_INJECT}                               \
	-e ${BUILD_DIR}/$(subst client-,,$@)/system.elf \
	-j $(shell getconf _NPROCESSORS_ONLN) \
	-- \
	-Wf,--state-dir=${BUILD_DIR}/$(subst client-,,$@)/state \
	-Wf,--trap                    \
	-Wf,--timeout=100000          \
	-Wf,--ok-marker=ok_marker     \
	-Wf,--fail-marker=fail_marker \
	-Wf,--catch-write-textsegment \
	-Wf,--catch-outerspace        \
	-V 2>/dev/null | grep -B 2 -A 8 'INJECT'

inject-%:
	${BOCHS_RUNNER} --mode riscv  -1  -j 1           \
	-f ${FAIL_INJECT}                               \
	-e ${BUILD_DIR}/$(subst inject-,,$@)/system.elf \
	-- \
	-Wf,--state-dir=${BUILD_DIR}/$(subst inject-,,$@)/state \
	-Wf,--trap                    \
	-Wf,--timeout=100000          \
	-Wf,--ok-marker=ok_marker     \
	-Wf,--fail-marker=fail_marker \
	-Wf,--catch-write-textsegment \
	-Wf,--catch-outerspace -V


import-arch-%: ${BUILD_DIR}/%/trace.pb ${HOME}/.my.cnf
	${FAIL_IMPORT} -v ${ARCH}/$(patsubst import-arch-%,%,$@) -b regs-dfp  -t $< -e $(shell dirname $<)/system.elf -i objdump --objdump ${OBJDUMP}
	${FAIL_IMPORT} -v ${ARCH}/$(patsubst import-arch-%,%,$@) -b mem  -t $< -e $(shell dirname $<)/system.elf -i mem --memory-type ram
	${FAIL_IMPORT} -v ${ARCH}/$(patsubst import-arch-%,%,$@) -b regs-trace  -t $< -e $(shell dirname $<)/system.elf -i mem --memory-type register
	${FAIL_IMPORT} -v ${ARCH}/$(patsubst import-arch-%,%,$@) -b regs -t $< -e $(shell dirname $<)/system.elf -i regs 
	${FAIL_IMPORT} -v ${ARCH}/$(patsubst import-arch-%,%,$@) -b ip   -t $< -e $(shell dirname $<)/system.elf -i regs --no-gp --ip
	${FAIL_PRUNE}  -v ${ARCH}/$(patsubst import-arch-%,%,$@) -b %% --overwrite

define arch-make-targets
build-$1: ${BUILD_DIR}/$1/system.elf

trace-$1: ${BUILD_DIR}/$1/trace.pb


endef


