out.exe: chips.asm data.o logic.o Makefile
	nasm -o out.exe chips.asm

check: out.exe chips.exe Makefile
	cmp out.exe chips.exe

%.o: %.asm
	sed -f fixmov.sed $< >$<.tmp
	nasm -O0 -o $@ $<.tmp
	rm $<.tmp

data.o: data.asm Makefile
logic.o: logic.asm Makefile

bin/label: tools/label/label.go Makefile
	go build -o bin/label ./tools/label
