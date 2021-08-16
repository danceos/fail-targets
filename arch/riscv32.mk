FAIL_DOWNLOAD_URL = ${FAIL_DOWNLOAD_BASE}?job=build-riscv-generic-tools%3A+%5Briscv32%5D

include arch/riscv-common.mk

CFLAGS += -march=rv32im -target riscv32-unknown-freebsd
