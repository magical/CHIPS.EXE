package main

// This tool is (will be) a "half" linker: it takes several
// .obj files as input, performs symbol resolution and relocation,
// and writes out a .bin file for each object which can then
// be copied into the final executable.
//
// It follows a modified traditional two-pass model:
// the first pass loads symbols and reads fixup locations
// the second pass performs the fixups and writes the patched object files.
//
// We have to read the fixup locations before patching so that
// we can order the relocation chains according to the link script.

import (
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"sort"
	"strings"
)

func main() {
	log.SetFlags(0)
	dumpMode := flag.Bool("dump", false, "dump contents instead of linking")
	flag.Parse()
	if *dumpMode {
		cmdDump()
	} else {
		cmdLink()
	}
}

func cmdDump() {
	f, err := os.Open(flag.Arg(0))
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()
	if err := dump(f); err != nil {
		log.Fatal(err)
	}
}

func cmdLink() {
	var ld Linker
	inputs := flag.Args()
	// Phase 1: load symbols and patch locations
	for _, filename := range inputs {
		if err := ld.loadSymbols(filename, nil); err != nil {
			log.Fatal(err)
		}
	}

	// Phase 2: apply patches and write output
	for _, filename := range inputs {
		if err := ld.patch(filename); err != nil {
			log.Println(err)
			continue
		}
	}
}

type Linker struct {
	segments []Segment
	symtab   map[string]*Symbol
}

type Segment struct {
	Index   int
	symbols []Symbol
}
type Input struct {
	filename string
}
type Symbol struct {
	name    string
	input   *Input
	segment *Segment
	offset  int
}

func (s *Symbol) File() string {
	return s.input.filename
}

func (ld *Linker) loadSymbols(filename string, seg *Segment) error {
	if ld.symtab == nil {
		ld.symtab = make(map[string]*Symbol)
	}

	f, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer f.Close()
	names, err := ReadObjNames(f)
	if err != nil {
		return err
	}
	// XXX close file here?

	inp := &Input{filename: filename} // XXX memoize?

	// TODO
	if false {
		for _, s := range names {
			fmt.Println(s.Offset, s.Name)
		}
	}

	for _, s := range names {
		if other, found := ld.symtab[s.Name]; found {
			log.Printf("warning: symbol %s redeclared in %s", s.Name, filename)
			log.Printf("  (previously declared in %s)", other.File())
			continue
		}
		symb := &Symbol{
			name:    s.Name,
			input:   inp,
			segment: seg,
			offset:  s.Offset,
		}
		ld.symtab[s.Name] = symb
	}

	return nil
}

func (ld *Linker) patch(filename string) error {
	f, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer f.Close()
	outfile := strings.TrimSuffix(filename, ".obj") + ".bin.test"
	out, err := os.Create(outfile)
	if err != nil {
		return err
	}
	defer out.Close()
	var ledata ObjLedata
	for {
		rec, err := ReadRecord(f)
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		switch rec.Type {
		case TypeLedata:
			ledata = ParseLedata(rec)
		case TypeFixup:
			fixes, err := ParseFixup(rec)
			if err != nil {
				return err
			}
			data := ld.fixup(&ledata, fixes)
			_, err = out.Write(data)
			if err != nil {
				return err
			}
		}
	}
	return out.Close()
}

func (ld *Linker) fixup(ledata *ObjLedata, fixes []ObjFixup) []byte {
	fmt.Printf("%x\n", ledata.StartOffset)
	data := ledata.Data
	last := 0xffff
	for _, f := range fixes {
		if f.FixupType == FixupOffset && f.RefType == RefSegment {
			continue
		}
		put16(data[f.DataOffset:], last)
		last = f.DataOffset + ledata.StartOffset
	}
	return data
}

func put16(b []byte, v int) {
	if v&0xFFFF != v {
		panic(fmt.Sprint("put16: value exceeds 16 bits:", v))
	}
	b[0] = uint8(v)
	b[1] = uint8(uint(v) >> 8)
}

// puts the fixups in the right order according to the spans from the linkscript
func sortFixes(p []int, spans []RelocSpan) {
	// first, sort in ascending order
	sort.Ints(p)

	start := 0
	for _, span := range spans {
		for start < len(p) && p[start] < int(span.Low) {
			start++
		}
		end := start
		for end < len(p) && p[end] < int(span.High) {
			end++
		}

		if span.Desc {
			reverseInts(p[start:end])
		}
		start = end
	}
}

func reverseInts(p []int) {
	for i, j := 0, len(p)-1; i < j; i, j = i+1, j-1 {
		p[i], p[j] = p[j], p[i]
	}
}
