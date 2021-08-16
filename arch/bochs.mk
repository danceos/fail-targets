FAIL_DOWNLOAD_URL = ${FAIL_DOWNLOAD_BASE}?job=build-bochs-generic-tools

CFLAGS += -m32
LDFLAGS += -Wl,-T linker.ld $^ -m32 -static -nostdlib  -Wl,--build-id=none

################################################################
# Build Targets
${BUILD_DIR}/%/system.o: %.c
	mkdir -p $(shell dirname $@)
	${CC} $< -o $@ ${CFLAGS} -c -ffunction-sections

${BUILD_DIR}/startup.o: arch/bochs/startup.s
	${CC} $< ${CFLAGS} -c -o $@ -ffunction-sections

${BUILD_DIR}/%/system.elf: ${BUILD_DIR}/%/system.o ${BUILD_DIR}/startup.o
	${CC} ${LDFLAGS} -o $@

${BUILD_DIR}/%/system.iso: ${BUILD_DIR}/%/system.elf
	rm -rf $(shell dirname $<)/grub
	mkdir -p $(shell dirname $<)/grub/boot/grub
	cp arch/bochs/grub.cfg $(shell dirname $<)/grub/boot/grub
	cp $< $(shell dirname $<)/grub/boot/system.elf
	grub-mkrescue -o $@ $(shell dirname $<)/grub

BOCHS_RUNNER_ARGS = \
	-V arch/bochs/vgabios.bin                      \
	-b arch/bochs/BIOS-bochs-latest                \

${BUILD_DIR}/%/trace.pb: ${BUILD_DIR}/%/system.iso
	${BOCHS_RUNNER} ${BOCHS_RUNNER_ARGS} -1        \
	-f ${FAIL_TRACE}                               \
	-e $(shell dirname $<)/system.elf              \
	-i $(shell dirname $<)/system.iso              \
	-- \
	-Wf,--state-file=$(shell dirname $<)/state     \
	-Wf,--trace-file=$(shell dirname $<)/trace.pb  \
	-Wf,--start-symbol=start_trace                 \
	-Wf,--end-symbol=stop_trace                    \
	-Wf,--check-bounds


client-%:
	${BOCHS_RUNNER} ${BOCHS_RUNNER_ARGS}            \
	-f ${FAIL_INJECT}                               \
	-e ${BUILD_DIR}/$(subst client-,,$@)/system.elf \
	-i ${BUILD_DIR}/$(subst client-,,$@)/system.iso \
	-j $(shell getconf _NPROCESSORS_ONLN) \
	-- \
	-Wf,--state-dir=${BUILD_DIR}/$(subst client-,,$@)/state \
	-Wf,--trap                    \
	-Wf,--timeout=10              \
	-Wf,--ok-marker=ok_marker     \
	-Wf,--fail-marker=fail_marker \
	-Wf,--catch-write-textsegment \
	-Wf,--catch-outerspace        \
	2>/dev/null | grep -B 2 -A 8 'INJECT'

inject-%:
	${BOCHS_RUNNER} ${BOCHS_RUNNER_ARGS} -1         \
	-f ${FAIL_INJECT}                               \
	-e ${BUILD_DIR}/$(subst inject-,,$@)/system.elf \
	-i ${BUILD_DIR}/$(subst inject-,,$@)/system.iso \
	-j 1 -- \
	-Wf,--state-dir=${BUILD_DIR}/$(subst inject-,,$@)/state \
	-Wf,--trap                    \
	-Wf,--timeout=10              \
	-Wf,--ok-marker=ok_marker     \
	-Wf,--fail-marker=fail_marker \
	-Wf,--catch-write-textsegment \
	-Wf,--catch-outerspace

define arch-make-targets

build-$1: ${BUILD_DIR}/$1/system.iso

trace-$1: ${BUILD_DIR}/$1/trace.pb

endef



