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


define arch-make-targets
build-$1: ${BUILD_DIR}/$1/system.elf

trace-$1: ${BUILD_DIR}/$1/system.elf
	${FAIL_TRACE} \
	-Wf,--elf-file      -Wf,$$<             \
	-Wf,--start-symbol  -Wf,start_trace 	\
	-Wf,--end-symbol    -Wf,stop_trace  	\
	-Wf,--check-bounds                      \
	-Wf,--state-file=$$(dir $$<)/state      \
	-Wf,--trace-file=$$(dir $$<)/trace.pb   \
	$$<

endef


