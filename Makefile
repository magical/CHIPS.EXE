SEGMENTS=data.bin logic.bin seg5.bin movement.bin digits.bin
RESOURCES=chips.ico res/*
chips.exe: chips.asm base.exe $(SEGMENTS) $(RESOURCES) Makefile
	nasm -o $@ $<

base=basedata.bin baselogic.bin basedigits.bin baseseg5.bin basemovement.bin

check: $(base) chips.exe Makefile
	-cmp basedata.bin data.bin
	-cmp baselogic.bin logic.bin
	-cmp basedigits.bin digits.bin
	-cmp baseseg5.bin seg5.bin
	-cmp basemovement.bin movement.bin
	cmp base.exe chips.exe

%.bin: %.asm fixmov.awk Makefile
	awk -f fixmov.awk $< >$<.tmp
	nasm -O0 -o $@ $<.tmp
	rm $<.tmp

data.bin: data.asm base.exe Makefile
logic.bin: logic.asm base.exe constants.asm structs.asm variables.asm func.mac Makefile
movement.bin: movement.asm constants.asm structs.asm variables.asm func.mac Makefile
seg5.bin: seg5.asm constants.asm variables.asm func.mac Makefile

variables.asm: data.asm genvars.sh Makefile
	sh genvars.sh >variables.asm

movement.svg: tools/graph movement.asm
	tools/graph <movement.asm | dot -Tsvg >movement.svg

bin/dd: tools/dd/dd.go
	go build -o bin/dd ./tools/dd
bin/label: tools/label/label.go
	go build -o bin/label ./tools/label
bin/res: tools/res/res.go
	go build -o bin/res ./tools/res

baseseg1.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xa00 -count 0xc00
baseseg2.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x1600 -count 0x2dca
basedata.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x4800 -count 0x1738
baselogic.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x6200 -count 0x2a70
baseseg4.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x8e00 -count 0x1400
baseseg5.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xa200 -count 0x1bc
baseseg6.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xa600 -count 0x800
basemovement.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xae00 -count 0x1cd4
baseseg8.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xcc00 -count 0x800
basedigits.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xd400 -count 0x150

%.dis: %.bin
	ndisasm $< >$@
