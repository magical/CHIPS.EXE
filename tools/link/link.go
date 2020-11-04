package main

// This tool is (will be) a "half" linker: it takes several
// .obj files as input, performs symbol resolution and relocation,
// and writes out a .bin file for each object which can then
// be copied into the final executable.
//
// It follows a traditional two-pass model:
// the first pass loads symbols from object files
// the second pass performs fixups and writes the patched object files.
//
// The second phase actually reads each object file twice:
// we have to read the fixup locations before patching so that
// we can order the relocation chains correctly according to the link script.

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

	ld.segments = make([]Segment, len(inputs))
	for i := range ld.segments {
		ld.segments[i].Index = i + 1
	}

	// Phase 1: load symbols
	for i, filename := range inputs {
		if err := ld.loadSymbols(filename, &ld.segments[i]); err != nil {
			log.Fatal(err)
		}
	}

	// Phase 1½?: resolve symbols

	// Phase 2: apply patches and write output
	for i, filename := range inputs {
		if err := ld.loadPatchlist(filename, &ld.segments[i]); err != nil {
			log.Fatal(err)
		}
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
	Index     int
	symbols   []Symbol // exported symbols
	extnames  []string // imported names (1-indexed)
}
type Symbol struct {
	name    string
	input   *Input
	module  *Module  // for external symbols
	segment *Segment // for internal symbols
	offset  int
}
type Input struct{ filename string }
type Module struct{ name string }

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

	extnames, err := ReadExternalNames(f)
	if err != nil {
		return err
	}
	seg.extnames = extnames

	// XXX combine ReadObjNames and ReadExternalNames
	f.Seek(0, io.SeekStart)
	names, err := ReadObjNames(f)
	if err != nil {
		return err
	}
	// XXX close file here?

	inp := &Input{filename: filename} // XXX memoize?

	// TODO
	if true {
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

// Algorithm for applying relocation info from the script file:
//
// 1 read the script file. assign reloc records to a per-segment list
//     the script may reference segments that don't exist during linking
//     map[int][]UserRelocInfo
// 2. when reading fixup records, associate each type of reloc record iwth a list
//    and append each patch address to the appropriate list
// 3. for each relocation, look up if the user specified an order.
//    if so, sort the patch list according to that order
// 4. build a patch chain map for the segment which maps each address to the next address in the chain
//     map[int][int
// 5. when patching the object file, reach from the chain map
// 6. when writing relocation records, first loop through records from the script file and, if
//    any references exist in the actual file, write it out. after that, go through the records
//    from the actual object file and, if we haven't written them already, write them out.
//
// internal references are always grouped into the same bucket, because they are always from this segment.
// they may or may not end up in the relocation data; they may be resolved immediately.
// external references may be per-symbol (in the case of an imported symbol) or they may be a local symbol
// from another segment, in which case they get lumped into a bucket with the other symbols from that segment.
//
// during the first pass, we know all the imported symbols and we know all the symbols from this segment,
// but of the remaining symbols we don't know which are in which segment, so we don't know which bucket to put them in.

//
func (ld *Linker) loadPatchlist(filename string, seg *Segment) error {
	file, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer file.Close()
	var baseOffset int
	for {
		rec, err := ReadRecord(file)
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		switch rec.Type {
		case TypeLedata:
			ledata := ParseLedata(rec)
			baseOffset = ledata.StartOffset
		case TypeFixup:
			fixes, err := ParseFixup(rec)
			if err != nil {
				return err
			}
			for _, f := range fixes {
				offset := baseOffset + f.DataOffset
				// TODO: add offset to reloc data
				// oh this isn't going to work. we need to resolve symbols
				// in order to put the reloc data into buckets
				// but this is part of phase 1 so we don't have full symbol info yet
				//
				// UNLESS i can find spans that work globally...
				//
				// actually, no, that doesn't work. even if i could assign a global order,
				// we would still have to put then into the correct bins before creating the patch chain
				// because a patch is only allowed to point to a patch with the same relocation info
				typ := "unk"
				if f.FixupType == FixupSegment {
					typ = "seg"
				} else if f.FixupType == FixupOffset {
					typ = "off"
				}
				if f.RefType == RefExternal {
					log.Printf("fixup: %s %x => %s", typ, offset, seg.extnames[f.RefIndex-1])
				} else if f.RefType == RefSegment {
					log.Printf("fixup: %s %x @ seg %d", typ, offset, f.RefIndex)
				}

				_ = offset
			}
		}
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
			// An offset fixup for a (internal) segment reference.
			// Nasm should have already set the correct offset,
			// so there's nothing for us to do here.
			// XXX maybe if there are multiple segments we have to adjust the offset?

			addr := f.DataOffset + ledata.StartOffset
			x, _ := read16(data[f.DataOffset:])
			log.Printf("fixup: off %x seg (= %04x)", addr, x)
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
