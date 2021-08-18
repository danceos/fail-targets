#include "lib.c"

int array[] = {1, 1, 2, 3, 5, 8, 13, 21};
int sum;

MAIN() {
    MARKER(start_trace);
	sum = array[0] +  array[1];
    MARKER(stop_trace);


	if ((sum & 0x0f) != 2)
		MARKER(fail_marker);
    else
        MARKER(ok_marker);
}

