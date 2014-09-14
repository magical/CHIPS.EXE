out.exe: chips.asm Makefile
	nasm -o out.exe chips.asm

check: out.exe chips.exe
	cmp out.exe chips.exe
