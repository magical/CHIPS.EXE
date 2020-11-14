# *Don't* reorder the list of asm files. The linker assigns segment numbers based on the order of the input files.
CODE=seg2.asm logic.asm seg4.asm seg5.asm seg6.asm movement.asm sound.asm digits.asm
OBJ=$(CODE:.asm=.obj)
RESOURCES=chips.ico res/*

chips.exe: chips.asm base.exe data.bin link.stamp $(RESOURCES) Makefile
	nasm -o $@ $<

BASE=basedata.bin baseseg2.bin baselogic.bin baseseg4.bin baseseg5.bin baseseg6.bin basemovement.bin baseseg8.bin basedigits.bin

check: $(BASE) chips.exe Makefile
	-cmp basedata.bin data.bin
	-cmp baseseg2.bin seg2.linked.bin
	-cmp baselogic.bin logic.linked.bin
	-cmp baseseg4.bin seg4.linked.bin
	-cmp baseseg5.bin seg5.linked.bin
	-cmp baseseg6.bin seg6.linked.bin
	-cmp basemovement.bin movement.linked.bin
	-cmp baseseg8.bin sound.linked.bin
	-cmp basedigits.bin digits.linked.bin
	cmp base.exe chips.exe

clean:
	rm *.bin *.obj
	rm chips.exe
	rm data.map
	rm link.stamp

%.bin: %.asm fixmov.awk Makefile
	awk -f fixmov.awk $< >$<.tmp
	nasm -O0 -o $@ $<.tmp
	rm $<.tmp

%.obj: %.asm fixmov.awk Makefile
	awk -f fixmov.awk $< >$<.tmp
	nasm -O0 -f obj -o $@ $<.tmp
	rm $<.tmp

link.stamp: bin/link chips.link $(OBJ) Makefile
	bin/link -script chips.link $(OBJ)
	@# touch a file to tell make we did the thing
	@touch $@

headers:
	$(SHELL) extern.sh >extern.inc
	grep -E -e '(KERNEL|USER|GDI|WEP4UTIL)\.\w+' --only-matching --no-filename $(CODE) | LC_ALL=C sort -u | sed -e 's/^/EXTERN /' >windows.inc

# additional dependencies
logic.obj: constants.asm structs.asm variables.asm func.mac
movement.obj: constants.asm structs.asm variables.asm func.mac
seg2.obj: constants.asm structs.asm variables.asm func.mac
seg4.obj: constants.asm structs.asm variables.asm
seg5.obj: constants.asm variables.asm func.mac
seg6.obj: constants.asm structs.asm variables.asm
sound.obj: constants.asm variables.asm func.mac
digits.obj: variables.asm func.mac

$(OBJ): extern.inc windows.inc

variables.asm: data.bin genvars.sh Makefile
	sh genvars.sh >variables.asm

movement.svg: tools/graph movement.asm
	tools/graph <movement.asm | dot -Tsvg >movement.svg

bin/dialog: tools/dialog/dialog.go
	go build -o bin/dialog ./tools/dialog
bin/dd: tools/dd/dd.go
	go build -o bin/dd ./tools/dd
bin/label: tools/label/label.go
	go build -o bin/label ./tools/label
bin/link: tools/link/*.go
	go build -o bin/link ./tools/link
bin/res: tools/res/res.go
	go build -o bin/res ./tools/res

baseseg1.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xa00 -count 0x952
baseseg2.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x1600 -count 0x2dca
basedata.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x4800 -count 0x1738
baselogic.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x6200 -count 0x2a70
baseseg4.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x8e00 -count 0x1208
baseseg5.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xa200 -count 0x1bc
baseseg6.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xa600 -count 0x75b
basemovement.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xae00 -count 0x1cd4
baseseg8.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xcc00 -count 0x620
basedigits.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xd400 -count 0x150

%.dis: %.bin
	ndisasm $< >$@
