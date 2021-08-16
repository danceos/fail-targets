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


	if (sum != 1270)
		MARKER(fail_maker);
    else
        MARKER(ok_marker);
}

