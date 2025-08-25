#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void delivery_shell() {
    char *const argv[] = {"/bin/sh", NULL};
    char *const envp[] = {NULL};
    execve("/bin/sh", argv, envp);
}

int main(){
    setvbuf(stdin, 0, 2, 0);
    setvbuf(stdout, 0, 2, 0);

    char buf[64];
    printf("return to overwrite!!!\n");

    read(0, buf, 100);

    return 0;
}
