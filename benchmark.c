#include "lib.c"

#ifndef BENCHMARK_ROUNDS
#define BENCHMARK_ROUNDS 1
#endif

uint32_t crc32_update(char *p, uint16_t len)
{
	uint16_t i;
	uint32_t crc = 0;
	while (len--) {
		crc ^= *p++;
		for (i = 0; i < 8; i++)
			crc = (crc >> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
	}
    return crc;
}

uint32_t array[8];


MAIN() {
    MARKER(start_trace);
    uint32_t crc = 0;
    uint32_t a = 0, b = 1;
    
    for (uint16_t i = 0; i < BENCHMARK_ROUNDS; i++) {
        // Calculate the nth. Fibonacci Number
        for (uint8_t x = 0; x < sizeof(array)/sizeof(*array); x++) {
            array[x] = a;
            a = a + b;
            b = array[x];
        }

        crc ^= crc32_update((char *)array, sizeof(array));
    }
    MARKER(stop_trace);

    POSIX_PRINTF("SUM: %x\n", crc);
}

