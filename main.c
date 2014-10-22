volatile int __dummy;
void __attribute__ ((noinline)) fail_marker();
void __attribute__ ((noinline)) fail_marker()
{
    __dummy = 100;
}

void __attribute__ ((noinline)) stop_trace();
void __attribute__ ((noinline)) stop_trace()
{
    __dummy = 100;
}


int array[] = {1, 1, 2, 3, 5, 8, 13, 21};
void os_main() {
	int sum = 0;

	for (int i = 0; i < sizeof(array)/sizeof(*array); i++) {
		sum = (array[i] * 23) + 1;
	}

	if (sum != 1250)
		fail_marker();
    stop_trace();
}

