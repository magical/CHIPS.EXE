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

	// TODO: init elsewhere
	ld.segments = make([]Segment, len(inputs))
	for i := range ld.segments {
		ld.segments[i].Index = i + 1
		ld.segments[i].reloctab = make(map[interface{}]*RelocInfo)
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
		if err := ld.patch(filename, &ld.segments[i]); err != nil {
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
	Index         int
	symbols       []Symbol // exported symbols
	extnames      []string // imported names (1-indexed)
	// reloc chain buckets
	reloclist []*RelocInfo
	reloctab  map[interface{}]*RelocInfo
}

// NE Relocation record format
// Relocation records are 8 bytes long and follow the general format:
//    db fixup type
//    db target type / flags
//    dw offset
//    dd <target info>
//
// There are several types of fixups & targets,
// of which we care about exactly 3 combinations:
//
//    SEGMENT / INTERNALREF
//      02 00 xxxx FF 00 ssss
//    FARADDR / IMPORTORDINAL
//      03 01 xxxx mmmm nnnn
//    OFFSET / IMPORTORDINAL
//      05 01 xxxx mmmm nnnn
//
//  where
//    xxxx is the first location to fix up (the head of the relocation chain)
//    ssss is the segment number
//    mmmm is the module number where a symbol resides
//    nnnn is the ordinal number of the imported symbol
//
// Any relocations with the same fixup type and target should share a relocation chain.
//
// For more details see EXEFMT.TXT (https://archive.org/details/exefmt)
type RelocInfo struct {
	target  RelocTarget
	patches []int
}
type RelocTarget interface {
	isRelocTarget()
}

// TODO: use more concrete values
func (s *Symbol) isRelocTarget()  {}
func (s *Segment) isRelocTarget() {}

func (ri *RelocInfo) kind() relocKind {
	switch s := ri.target.(type) {
	default:
		panic("invalid RelocInfo: unknown target")
	case *Symbol:
		// TODO
		//if s.IsConst() {
		//	return rkOffsetImportordinal
		//}
		_ = s
		return rkFaraddrImportordinal
	case *Segment:
		return rkSegmentInternal
	}
}

type relocKind int

const (
	rkSegmentInternal relocKind = iota
	rkFaraddrImportordinal
	rkOffsetImportordinal
)

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
				log.Print("fixup: ", fmtFixup(f, seg, baseOffset))
				if f.RefType == RefExternal {
					// External (symbol) reference
					if !(1 <= f.RefIndex && f.RefIndex <= len(seg.extnames)) {
						log.Printf("%s: warning: fixup references external symbol %d, which is out of range", filename, f.RefIndex)
						continue
					}
					name := seg.extnames[f.RefIndex-1]
					symb := ld.symtab[name]
					_ = symb
				} else if f.RefType == RefSegment {
					// Internal (segment) reference
					// There should only be one segment in the object file,
					// so RefIndex should always be one
					if f.RefIndex != 1 {
						log.Printf("%s: warning: fixup references segment index %d, which is out of range", filename, f.RefIndex)
						continue
					}
				}
				_ = offset
			}
		}
	}
	return nil
}

func fmtFixup(f ObjFixup, seg *Segment, base int) string {
	offset := base + f.DataOffset
	typ := "unk"
	if f.FixupType == FixupSegment {
		typ = "seg"
	} else if f.FixupType == FixupOffset {
		typ = "off"
	}
	if f.RefType == RefExternal {
		return fmt.Sprintf("%s %x => %s", typ, offset, seg.extnames[f.RefIndex-1])
	} else if f.RefType == RefSegment {
		return fmt.Sprintf("%s %x @ seg %d", typ, offset, f.RefIndex)
	} else {
		return fmt.Sprintf("%s %x type=%d index=%d\n", typ, offset, f.RefType, f.RefIndex)
	}
}

func (ld *Linker) patch(filename string, seg *Segment) error {
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
			data := ld.fixup(filename, seg, &ledata, fixes)
			_, err = out.Write(data)
			if err != nil {
				return err
			}
		}
	}
	// TODO: write reloc records
	return out.Close()
}

func (ld *Linker) fixup(filename string, seg *Segment, ledata *ObjLedata, fixes []ObjFixup) []byte {
	fmt.Printf("%x\n", ledata.StartOffset)
	data := ledata.Data
	chain := make(map[*RelocInfo]int) // last patched address for a given reloc bucket
	// FIXME: chain needs to be reused across fixup calls
	for _, f := range fixes {
		if f.DataOffset+2 > len(data) {
			log.Printf("%s: error: fixup data offset %#x out of bounds for chunk of length %#x", filename, f.DataOffset, len(data))
			continue
		}
		var ri *RelocInfo
		switch f.RefType {
		case RefExternal:
			// External (symbol) reference
			if !(1 <= f.RefIndex && f.RefIndex <= len(seg.extnames)) {
				log.Printf("%s: warning: fixup references external symbol %d, which is out of range", filename, f.RefIndex)
				continue
			}
			name := seg.extnames[f.RefIndex-1]
			symb, ok := ld.symtab[name]
			if !ok {
				ld.warnMissing(filename, name)
				// TODO: make a dummy relocinfo?
				continue
			}
			if f.FixupType == FixupOffset {
				// we know what the offset is so we can just write it to the file
				// no need to create relocation record.
				// even if this is an imported symbol, the offset doesn't matter in that case
				// so we can just write 0.
				log.Printf("fixup @ %x: offset for %s = %x", f.DataOffset, symb.name, symb.offset)
				put16(data[f.DataOffset:], symb.offset)
			} else if f.FixupType == FixupSegment {
				// this one's tricker. the segment base won't be known until the program is loaded,
				// so we have to add a relocation record
				ri = seg.getOrMakeRelocInfo(symb)
				last, ok := chain[ri]
				if !ok {
					last = 0xffff
				}
				put16(data[f.DataOffset:], last)
				chain[ri] = ledata.StartOffset + f.DataOffset
				log.Printf("fixup @ %x: segment for %s = %x", f.DataOffset, symb.name, last)
			} else {
				log.Printf("%s: warning: unknown fixup type %#x", filename, f.FixupType)
			}
		case RefSegment:
			// Internal (segment) reference
			// There should only be one segment in the object file,
			// so RefIndex should always be one
			if f.RefIndex != 1 {
				log.Printf("%s: warning: fixup references segment index %d, which is out of range", filename, f.RefIndex)
				continue
			}
			if f.FixupType == FixupOffset {
				// An offset fixup for a (internal) segment reference.
				// Nasm should have already set the correct offset,
				// so there's nothing for us to do here.
				// XXX maybe if there are multiple segments we have to adjust the offset?
				continue
			}
			// this is the reference type that is used for references to symbols in the same segment
			// fun fact: we don't even get to know the symbol name in this case
			ri = seg.getSelfRelocInfo()
			last, ok := chain[ri]
			if !ok {
				last = 0xffff
			}
			put16(data[f.DataOffset:], last)
			chain[ri] = ledata.StartOffset + f.DataOffset
			log.Printf("fixup @ %x: self segment reference = %x", f.DataOffset, last)
		default:
			log.Printf("%s: warning: unknown fixup reftype: %#02x", filename, f.RefType)
			continue
		}
		//put16(data[f.DataOffset:], ri.last)
		//ri.last = f.DataOffset + ledata.StartOffset
	}
	return data
}

func (seg *Segment) getOrMakeRelocInfo(symb *Symbol) *RelocInfo {
	if symb.module != nil {
		// imported symbol
		if ri, ok := seg.reloctab[symb]; ok {
			return ri
		}
		ri := &RelocInfo{target: symb}
		seg.reloctab[symb] = ri
		seg.reloclist = append(seg.reloclist, ri)
		return ri
	} else {
		// internal symbol, so just a segment reference
		if ri, ok := seg.reloctab[symb.segment]; ok {
			return ri
		}
		ri := &RelocInfo{target: symb.segment}
		seg.reloctab[symb.segment] = ri
		seg.reloclist = append(seg.reloclist, ri)
		return ri
	}
}
func (seg *Segment) getSelfRelocInfo() *RelocInfo {
	if ri, ok := seg.reloctab[seg]; ok {
		return ri
	}
	ri := &RelocInfo{target: seg}
	seg.reloctab[seg] = ri
	seg.reloclist = append(seg.reloclist, ri)
	return ri
}

func (ld *Linker) warnMissing(filename string, name string) {
	// TODO: only print once
	log.Printf("%s: warning: unresolved symbol %q", filename, name)
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
