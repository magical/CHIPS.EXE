chips.exe: chips.asm base.exe data.bin logic.bin Makefile
	nasm -o $@ $<

check: chips.exe Makefile
	cmp base.exe chips.exe

%.bin: %.asm fixmov.awk Makefile
	awk -f fixmov.awk $< >$<.tmp
	nasm -O0 -o $@ $<.tmp
	rm $<.tmp

data.bin: data.asm base.exe Makefile
logic.bin: logic.asm base.exe constants.asm Makefile

bin/label: tools/label/label.go Makefile
	go build -o bin/label ./tools/label
