CC=gcc
CFLAGS=-Wall -no-pie

all:	cc asm
		$(CC) $(CFLAGS) main.o shuffleImage.o -o main

cc:		../main.c
		$(CC) $(CFLAGS) -c ../main.c -o main.o

asm:	shuffleImage.asm
		nasm -f elf64 shuffleImage.asm

clean:
	rm -f *.o
	rm main
