all: main

main: main.o functions64.o
	ld -o main main.o ./functions64.o

main.o: main.asm functions64.inc
	nasm -g -f elf64 -F dwarf main.asm -l main.lst

clean:
	rm -f ./main.o || true
	rm -f ./main.lst || true
	rm -f ./main || true
