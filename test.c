// MIT License
// Copyright (c) 2026 Yabloko Labs Ltd
//
// test.c - Test file for C analysis

#include <stdio.h>

void greet(char* name) {
    printf("Hi %s\n", name);
}

int main() {
    greet("world");
    greet("c");
    return 0;
}
