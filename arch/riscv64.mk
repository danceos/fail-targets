FAIL_DOWNLOAD_URL = ${FAIL_DOWNLOAD_BASE}?job=build-riscv-generic-tools%3A+%5Briscv64%5D

include arch/riscv-common.mk

CFLAGS += -march=rv64im -target riscv64-unknown-freebsd
