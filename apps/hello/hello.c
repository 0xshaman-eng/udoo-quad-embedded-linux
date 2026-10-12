/*
 * hello.c - first cross-compiled application for the UDOO Quad
 *
 * Prints a greeting plus system information from uname(2),
 * proving the binary was built for ARM and runs on the board's kernel.
 */
#include <stdio.h>
#include <sys/utsname.h>

int main(void)
{
    struct utsname info;

    printf("Hello from UDOO Quad!\n");

    if (uname(&info) == 0) {
        printf("  Host name : %s\n", info.nodename);
        printf("  Kernel    : %s %s\n", info.sysname, info.release);
        printf("  Machine   : %s\n", info.machine);
    }

    return 0;
}
