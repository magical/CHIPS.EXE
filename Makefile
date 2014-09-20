SEGMENTS=data.bin logic.bin seg5.bin digits.bin
chips.exe: chips.asm base.exe $(SEGMENTS) Makefile
	nasm -o $@ $<

check: chips.exe Makefile
	-cmp basedata.bin data.bin
	-cmp baselogic.bin logic.bin
	-cmp basedigits.bin digits.bin
	-cmp baseseg5.bin seg5.bin
	cmp base.exe chips.exe

%.bin: %.asm fixmov.awk Makefile
	awk -f fixmov.awk $< >$<.tmp
	nasm -O0 -o $@ $<.tmp
	rm $<.tmp

data.bin: data.asm base.exe Makefile
logic.bin: logic.asm base.exe constants.asm Makefile

bin/dd: tools/dd/dd.go
	go build -o bin/dd ./tools/dd
bin/label: tools/label/label.go
	go build -o bin/label ./tools/label
bin/res: tools/res/res.go
	go build -o bin/res ./tools/res

baselogic.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x6200 -count 0x2a70
basedata.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x4800 -count 0x1738
basedigits.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xd400 -count 0x150
baseseg5.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xa200 -count 0x1bc

%.dis: %.bin
	ndisasm $< >$@
