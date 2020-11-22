# *Don't* reorder the list of asm files. The linker assigns segment numbers based on the order of the input files.
CODE=crt.asm seg2.asm logic.asm seg4.asm seg5.asm seg6.asm movement.asm sound.asm digits.asm
OBJ=$(CODE:.asm=.obj)
RESOURCES=chips.ico res/*.bmp

chips.exe: chips.asm data.bin $(OBJ) $(RESOURCES) bin/link chips.link Makefile
	bin/link -script chips.link -map chips.map $(OBJ)
	$(generate-extern.inc)
	$(generate-segment_sizes.inc)
	nasm -o $@ $<

define generate-extern.inc =
	@echo "; Generated from chips.map; do not edit" >exports.inc
	@echo "; v""im: syntax=nasm" >>exports.inc
	awk <chips.map >>exports.inc -e '/WinMain|WNDPROC|MSGPROC/ { printf("%-16s equ 0x%s\n", $$3, $$2); }'
endef
define generate-segment_sizes.inc =
	@echo "; Generated from chips.map; do not edit" >segment_sizes.inc
	@echo "; v""im: syntax=nasm" >>segment_sizes.inc
	awk <chips.map >>segment_sizes.inc -e '/_segment_.*_size/ { print $$2, "equ", "0x"$$1; }'
endef

chips.exe: constants.asm exports.inc segment_sizes.inc

BASE=basecrt.bin basedata.bin baseseg2.bin baselogic.bin baseseg4.bin baseseg5.bin baseseg6.bin basemovement.bin baseseg8.bin basedigits.bin

check: $(BASE) chips.exe Makefile
	-cmp basecrt.bin crt.bin
	-cmp basedata.bin data.bin
	-cmp baseseg2.bin seg2.bin
	-cmp baselogic.bin logic.bin
	-cmp baseseg4.bin seg4.bin
	-cmp baseseg5.bin seg5.bin
	-cmp baseseg6.bin seg6.bin
	-cmp basemovement.bin movement.bin
	-cmp baseseg8.bin sound.bin
	-cmp basedigits.bin digits.bin
	cmp base.exe chips.exe

clean:
	rm *.bin *.obj
	rm chips.exe
	rm data.map

%.bin: %.asm fixmov.awk Makefile
	awk -f fixmov.awk $< >$<.tmp
	nasm -O0 -o $@ $<.tmp
	rm $<.tmp

%.obj: %.asm fixmov.awk Makefile
	awk -f fixmov.awk $< >$<.tmp
	nasm -O0 -f obj -o $@ $<.tmp
	rm $<.tmp

headers:
	$(SHELL) extern.sh >extern.inc
	grep -E -e '(KERNEL|USER|GDI)\.\w+' --only-matching --no-filename $(CODE) | LC_ALL=C sort -u | sed -e 's/^/EXTERN /' >windows.inc

# additional dependencies
logic.obj: constants.asm structs.asm variables.asm func.mac
movement.obj: constants.asm structs.asm variables.asm func.mac
crt.obj: variables.asm func.mac
seg2.obj: constants.asm structs.asm variables.asm func.mac
seg4.obj: constants.asm structs.asm variables.asm
seg5.obj: constants.asm variables.asm func.mac
seg6.obj: constants.asm structs.asm variables.asm
sound.obj: constants.asm variables.asm func.mac
digits.obj: variables.asm func.mac

$(OBJ): extern.inc windows.inc

variables.asm: data.bin genvars.sh Makefile
	$(SHELL) genvars.sh >variables.asm

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

basecrt.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xa00 -count 0x9f4
baseseg2.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x1600 -count 0x3084
basedata.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x4800 -count 0x1738
baselogic.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x6200 -count 0x2ac2
baseseg4.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0x8e00 -count 0x1312
baseseg5.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xa200 -count 0x216
baseseg6.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xa600 -count 0x7dd
basemovement.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xae00 -count 0x1d5e
baseseg8.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xcc00 -count 0x6aa
basedigits.bin: bin/dd base.exe
	bin/dd <base.exe >$@ -skip 0xd400 -count 0x18a

%.dis: %.bin
	ndisasm $< >$@
