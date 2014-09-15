out.exe: chips.asm data.o logic.o Makefile
	nasm -o out.exe chips.asm

check: out.exe chips.exe Makefile
	cmp out.exe chips.exe

%.o: %.asm
	nasm -o $@ $<

data.o: data.asm Makefile
logic.o: logic.asm Makefile
