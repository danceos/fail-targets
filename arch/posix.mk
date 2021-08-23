FAIL_DOWNLOAD_URL = NOTAVAILABLE

CFLAGS  += 
LDFLAGS += 

################################################################
# Build Targets
${BUILD_DIR}/%/system.o: %.c
	mkdir -p $(shell dirname $@)
	${CC} ${CFLAGS} -c $< -o $@ 

${BUILD_DIR}/%/system.elf: ${BUILD_DIR}/%/system.o
	${CC} ${LDFLAGS} $< -o $@

${BUILD_DIR}/%/trace.pb: ${BUILD_DIR}/%/system.elf
	$<

define arch-make-targets

build-$1: ${BUILD_DIR}/$1/system.elf

trace-$1: ${BUILD_DIR}/$1/trace.pb


endef



