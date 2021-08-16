CC      := clang-11
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
	-Wf,--elf-file      -Wf,$<             \
	-Wf,--start-symbol  -Wf,start_trace 	\
	-Wf,--end-symbol    -Wf,stop_trace  	\
	-Wf,--check-bounds                      \
	-Wf,--state-file=$(dir $<)/state      \
	-Wf,--trace-file=$(dir $<)/trace.pb   \
	-V $<

client-%:
	${BOCHS_RUNNER} --mode sail                     \
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
	${BOCHS_RUNNER} --mode sail  -1  -j 1           \
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



define arch-make-targets
build-$1: ${BUILD_DIR}/$1/system.elf

trace-$1: ${BUILD_DIR}/$1/trace.pb


endef


