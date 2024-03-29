#include "lib.c"

int array[] = {1, 1, 2, 3, 5, 8, 13, 21};
int sum;

MAIN() {
    MARKER(start_trace);
	sum = 20;

	for (int i = 0; i < sizeof(array)/sizeof(*array); i++) {
		sum += (array[i] * 23) + 1;
	}
    MARKER(stop_trace);

    POSIX_PRINTF("SUM: %d\n", sum);


	if (sum != 1270)
        MARKER(fail_marker);
    else
        MARKER(ok_marker);

}

