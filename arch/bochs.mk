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
	cp grub.cfg $(shell dirname $<)/grub/boot/grub
	cp $< $(shell dirname $<)/grub/boot/system.elf
	grub-mkrescue -o $@ $(shell dirname $<)/grub

define arch-make-targets
build-$1: ${BUILD_DIR}/$1/system.iso
endef



