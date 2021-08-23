#include <stdio.h>

#define MARKER(str) printf(QUOTE(str) "\n")

#define POSIX_PRINTF(...) printf(__VA_ARGS__)

#define MAIN() int main(int argc, char** argv)
