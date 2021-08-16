#include "lib.c"

int array[] = {1, 1, 2, 3, 5, 8, 13, 21};
int sum;
void os_main() {
    MARKER(start_trace);
	sum = 20;

	for (int i = 0; i < 1 << 20; i++) {
		sum += (array[i % (sizeof(array)/sizeof(*array))] * 23) + 1;
	}

    MARKER(stop_trace);

    MARKER(ok_marker);
}

