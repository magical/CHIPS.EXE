package main

// This tool is a "half" linker: it takes several .obj files
// as input, performs symbol resolution and relocation, and writes
// out a .bin file for each object which can then be copied into
// the final executable.
//
// It follows a traditional two-pass model:
// the first pass loads symbols from object files
// the second pass performs fixups and writes the patched object files.
//
// The second pass is somewhat complicated by the fact that we need to
// accurately recreate the order of the relocation chains chosen by the
// original linker.

// TODO:
// - [ ] support multiple segments in input files
// - [ ] concatenate data segments

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"sort"
	"strings"
)

var debug bool

func main() {
	log.SetFlags(0)
	flag.BoolVar(&debug, "debug", false, "print debug info during linking")
	dumpMode := flag.Bool("dump", false, "dump object contents instead of linking")
	scriptFlag := flag.String("script", "chips.link", "linkscript filename")
	segFlag := flag.Int("seg", 0, "for testing: the segment number to use when linking a single object")
	mapFlag := flag.String("map", "", "filename to write map file to")
	flag.Parse()
	if *dumpMode {
		cmdDump()
	} else {
		cmdLink(*scriptFlag, *mapFlag, *segFlag)
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

func cmdLink(script, mapfile string, singleObjectSegmentNumber int) {
	inputs := flag.Args()

	ld := NewLinker()

	if err := ld.loadScript(script); err != nil {
		// TODO; add filename lower in the call stack?
		log.Fatal(script+":", err)
	}

	// TODO: init elsewhere
	ld.segments = make([]SegmentInfo, len(inputs))
	base := 1 // XXX don't hardcode this
	for i := range ld.segments {
		ld.segments[i].num = ld.addSegment(base + i)
		ld.segments[i].reloctab = make(map[RelocTarget]*RelocInfo)
	}

	if len(inputs) == 1 && singleObjectSegmentNumber > 0 {
		ld.segments[0].num = ld.addSegment(singleObjectSegmentNumber) // for testing
	}

	// Phase 1: load symbols
	for i, filename := range inputs {
		if err := ld.loadSymbols(filename, &ld.segments[i]); err != nil {
			log.Fatal(err)
		}
	}

	errors := 0
	// Phase 2: apply patches and write output
	for i, filename := range inputs {
		if err := ld.patch(filename, &ld.segments[i]); err != nil {
			log.Print(filename, ": ", err)
			errors++
			continue
		}
	}

	// hack: compute segment start addresses for chips.exe
	// segment 1 starts at 0xa00
	off := 0xa00
	for i := range ld.segments {
		if i == 1 {
			// extra padding after segment 1
			off += 0x200
		}
		if i == 2 {
			// for the data segment
			off += 0x6200 - 0x4800
		}
		ld.segments[i].start = off
		size := ld.segments[i].size + ld.segments[i].relocsize
		off = align(off+size, 1<<9)
	}

	// write exported symbols to .map file
	if mapfile != "" {
		if err := ld.writeMapFile(mapfile); err != nil {
			log.Print(err)
		}
	}

	if errors > 0 {
		log.Fatal("there were errors")
	}
}

func (ld *Linker) loadScript(filename string) error {
	f, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer f.Close()
	return ld.ParseScript(f)
}

type Linker struct {
	modules  []*Module
	segments []SegmentInfo
	symtab   map[string]*Symbol
	segmemo  map[int]*Segment        // key = segment num
	userinfo map[int][]UserRelocInfo // key = segment num
}

func NewLinker() *Linker {
	return &Linker{
		symtab:   make(map[string]*Symbol),
		segmemo:  make(map[int]*Segment),
		userinfo: make(map[int][]UserRelocInfo),
	}
}

type Module struct {
	num     int
	name    string
	hasSyms bool
}
type Segment struct {
	Index int
}
type SegmentInfo struct {
	num      *Segment
	symbols  []*Symbol // exported symbols
	extnames []string  // imported names (1-indexed) used when loading
	// reloc chain buckets
	// needed during linking a segment
	reloclist []*RelocInfo
	reloctab  map[RelocTarget]*RelocInfo

	start     int // segment start address in exe
	size      int // number of bytes in segment data
	relocsize int // number of bytes in reloc data
}

func (ld *Linker) addModule(n int, name string) (*Module, error) {
	for _, m := range ld.modules {
		// TODO: check num too?
		if m.name == name {
			// TODO: error?
			return m, nil
		}
	}
	m := &Module{num: n, name: name}
	ld.modules = append(ld.modules, m)
	return m, nil
}

func (ld *Linker) hasModule(name string) bool {
	for _, m := range ld.modules {
		if m.name == name {
			return true
		}
	}
	return false
}

// Constructs a Segment with the given index, or returns an existing one with the same number.
func (ld *Linker) addSegment(num int) *Segment {
	if seg, ok := ld.segmemo[num]; ok {
		return seg
	}
	seg := &Segment{num}
	ld.segmemo[num] = seg
	return seg
}

func (ld *Linker) addImportedSymbol(mod *Module, name string, ordinal int) error {
	symb := &Symbol{
		name:   name,
		module: mod,
		offset: ordinal, // hmm
	}
	ld.symtab[name] = symb
	return nil
}

type Input struct{ filename string }
type Symbol struct {
	name     string
	input    *Input
	module   *Module  // for external symbols
	segment  *Segment // for internal symbols
	offset   int
	constant bool // symbol is a constant, not a function
}

func (s *Symbol) File() string {
	if s.input == nil {
		return "<preset>"
	}
	return s.input.filename
}

func (ld *Linker) addImportedConstant(mod *Module, name string, ordinal int) error {
	symb := &Symbol{
		name:     name,
		module:   mod,
		offset:   ordinal, // hmm
		constant: true,
	}
	ld.symtab[name] = symb
	return nil
}

func (ld *Linker) addLocalSymbol(name string, seg, offset int) error {
	symb := &Symbol{
		name:    name,
		segment: ld.addSegment(seg),
		offset:  offset,
	}
	ld.symtab[name] = symb
	return nil // TODO: error if already exists
}

func (ld *Linker) loadSymbols(filename string, seg *SegmentInfo) error {
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

	if debug {
		for _, s := range names {
			fmt.Printf("%x %s\n", s.Offset, s.Name)
		}
	}

	for _, s := range names {
		if other, found := ld.symtab[s.Name]; found {
			log.Printf("warning: symbol %s redeclared in %s", s.Name, filename)
			log.Printf("  (previously declared in %s)", other.File())
			continue
		}
		symb := &Symbol{
			name:     s.Name,
			input:    inp,
			segment:  seg.num,
			offset:   s.Offset,
			constant: s.Const,
		}
		ld.symtab[s.Name] = symb
		seg.symbols = append(seg.symbols, symb)
	}

	return nil
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
//      02 00 xxxx ss 00 0000
//    FARADDR / IMPORTORDINAL
//      03 01 xxxx mmmm nnnn
//    OFFSET / IMPORTORDINAL
//      05 01 xxxx mmmm nnnn
//
//  where
//    xxxx is the first location to fix up (the head of the relocation chain)
//    ss   is the segment number
//    mmmm is the module number where a symbol resides
//    nnnn is the ordinal number of the imported symbol
//
// Any relocations with the same fixup type and target should share a relocation chain.
//
// For more details see EXEFMT.TXT (https://archive.org/details/exefmt)

type RelocTarget interface {
	isRelocTarget()
}

type RelocInfo struct {
	target  RelocTarget
	patches []int // fixup addresses
	last    int   // last patched address for this reloc bucket
}

type UserRelocInfo struct {
	target RelocTarget
	spans  []RelocSpan
}

func (s *Symbol) isRelocTarget()  {}
func (s *Segment) isRelocTarget() {}

func (ri *RelocInfo) kind() relocKind {
	switch s := ri.target.(type) {
	default:
		panic("invalid RelocInfo: unknown target")
	case *Symbol:
		if s.constant {
			return rkOffsetImportordinal
		}
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

func (ld *Linker) addRelocExternal(segment int, symb *Symbol, spans []RelocSpan) {
	ri := UserRelocInfo{
		target: symb,
		spans:  spans,
	}
	ld.userinfo[segment] = append(ld.userinfo[segment], ri)
}

func (ld *Linker) addRelocInternal(segment, toSegment int, spans []RelocSpan) {
	seg := ld.addSegment(toSegment)
	ri := UserRelocInfo{
		target: seg,
		spans:  spans,
	}
	ld.userinfo[segment] = append(ld.userinfo[segment], ri)
}

// Algorithm for applying relocation info from the script file:
//
// 1. read the script file. assign reloc records to a per-segment list
//    the script may reference segments that don't exist during linking
//      map[int][]UserRelocInfo
//
// fixups are processed in two phases. first is the processing phase,
// second is the fixup phase (yes, we have to fix the fixups).
// both of these phases takes place during the second pass of the linker,
// after symbols are loaded.
//
// phase 1:
// 2. before processing, pre-load the list of reloc records with the user-specified relocations,
//    ensuring that those records will be written out in the correct order afterwards.
//    as fixup records are processed, any new (not in the user-supplied data)
//    relocation records will be appended to the end of the list.
//
// 3. when reading fixup records, accumulate patch addresses into a reloc record
//    associated with the appropriate type of relocation for each fixup. (RelocInfo)
//
// 4. copy the object data into the output file
//
// phase two:
// 5. sort the patches. for each relocation, look up if the user specified an order and,
//    if so, sort the patch list according to that order.
//
// 6. build a patch chain map for the segment which maps each address to the next address in the chain
//     map[int]int
//
// 7. fixup. iterate through the list of patch locations. seek to that point in the output file
//    and write the address from the chain map
//
// 8. finally, write the relocation records to the end of the output file
//
// internal references are always grouped into the same bucket, because they are always from this segment.
// they may or may not end up in the relocation data; they may be resolved immediately.
// external references may be per-symbol (in the case of an imported symbol) or they may be a local symbol
// from another segment, in which case they get lumped into a bucket with the other symbols from that segment.
//
// during the first pass, we know all the imported symbols and we know all the symbols from this segment,
// but of the remaining symbols we don't know which are in which segment, so we don't know which bucket to put them in.

func fmtFixup(f ObjFixup, seg *SegmentInfo, base int) string {
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

func (ld *Linker) patch(filename string, seg *SegmentInfo) error {
	f, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer f.Close()
	outfile := strings.TrimSuffix(filename, ".obj") + ".bin"
	out, err := os.Create(outfile)
	if err != nil {
		return err
	}
	defer out.Close()
	// preload user reloc info, if any, so that it appears in the right order at the end
	for _, u := range ld.userinfo[seg.num.Index] {
		_ = seg.getOrMakeRelocInfo(u.target)
	}
	// phase one: process data and write provisional fixups
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
			seg.size += len(data)
		}
	}
	// phase two: sort the fixup addresses according to the user relocation info and
	// alter the output file to use the new patch chains
	userinfo := ld.userinfo[seg.num.Index]
	if len(userinfo) > 0 {
		var patches []struct{ addr, value int }
		for _, u := range userinfo {
			if ri, ok := seg.reloctab[u.target]; ok {
				sortFixes(ri.patches, u.spans)
				//fmt.Printf("%v %x\n", ri.target, ri.patches)
				last := 0xffff
				for _, addr := range ri.patches {
					patches = append(patches, struct{ addr, value int }{addr, last})
					last = addr
				}
				ri.last = last
			}
		}
		// sort the patches first for good locality when writing
		sort.Slice(patches, func(i, j int) bool { return patches[i].addr < patches[j].addr })
		var buf [2]byte
		for _, p := range patches {
			if debug {
				log.Printf("patch @ %x = %x", p.addr, p.value)
			}
			put16(buf[:], p.value)
			if _, err := out.WriteAt(buf[:], int64(p.addr)); err != nil {
				return err
			}
		}
	}
	// finalize: write reloc records
	// XXX this seek is probably unnecessary
	if _, err := out.Seek(0, io.SeekEnd); err != nil {
		return err
	}
	seg.relocsize = 2 + len(seg.reloclist)*8
	out.Write([]byte{uint8(len(seg.reloclist)), 0})
	for _, ri := range seg.reloclist {
		if len(ri.patches) == 0 {
			log.Printf("warning: skipping empty reloc %v", ri.target)
			continue
		}
		var buf [8]byte
		switch ri.kind() {
		case rkOffsetImportordinal:
			//    OFFSET / IMPORTORDINAL
			//      05 01 xxxx mmmm nnnn
			buf[0] = 5
			buf[1] = 1
			put16(buf[2:], ri.last)
			put16(buf[4:], ri.target.(*Symbol).module.num)
			put16(buf[6:], ri.target.(*Symbol).offset) // ordinal
			out.Write(buf[:])
			if debug {
				fmt.Printf("%s: reloc: %v = % x\n", filename, ri.target, buf)
			}
		case rkFaraddrImportordinal:
			//    FARADDR / IMPORTORDINAL
			//      03 01 xxxx mmmm nnnn
			buf[0] = 3
			buf[1] = 1
			put16(buf[2:], ri.last)
			put16(buf[4:], ri.target.(*Symbol).module.num)
			put16(buf[6:], ri.target.(*Symbol).offset) // ordinal
			out.Write(buf[:])
			if debug {
				fmt.Printf("%s: reloc: %v = % x\n", filename, ri.target, buf)
			}
		case rkSegmentInternal:
			//    SEGMENT / INTERNALREF
			//      02 00 xxxx ss 00 0000
			buf[0] = 2
			buf[1] = 0
			put16(buf[2:], ri.last)
			put16(buf[4:], int(uint8(ri.target.(*Segment).Index)))
			put16(buf[6:], 0)
			out.Write(buf[:])
			if debug {
				fmt.Printf("%s: reloc: %v = % x\n", filename, ri.target, buf)
			}
		default:
			if debug {
				fmt.Println("reloc:", ri.target)
			}
			panic("unreachable")
		}
	}
	return out.Close()
}

func (ld *Linker) resolve(name string) (_ *Symbol, found bool) {
	symb, ok := ld.symtab[name]
	if !ok {
		// Hack: auto-resolve functions named FUN_<seg>_<offset>
		if strings.HasPrefix(name, "FUN_") {
			var seg, offset int
			if n, err := fmt.Sscanf(name, "FUN_%d_%x", &seg, &offset); n == 2 && err == nil {
				if debug {
					log.Println("adding", name)
				}
				ld.addLocalSymbol(name, seg, offset)
				symb, ok = ld.symtab[name]
				return symb, ok
			}
		}
	}
	return symb, ok
}

func (ld *Linker) fixup(filename string, seg *SegmentInfo, ledata *ObjLedata, fixes []ObjFixup) []byte {
	if debug {
		fmt.Printf("%x\n", ledata.StartOffset)
	}
	data := ledata.Data
	for _, f := range fixes {
		//log.Print("fixup: ", fmtFixup(f, seg, ledata.DataOffset))
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
			symb, ok := ld.resolve(name)
			if !ok {
				ld.warnMissing(filename, name)
				// TODO: make a dummy relocinfo?
				continue
			}
			if symb.module != nil && f.FixupType == FixupOffset {
				// imported symbol, this is part of a FARADDR relocation chain
				ri = seg.getOrMakeRelocInfoForSymbol(symb)
				last := ri.chain(ledata.StartOffset + f.DataOffset)
				put16(data[f.DataOffset:], last)
				if debug {
					log.Printf("fixup @ %x: faraddr offset for %s = %x", f.DataOffset, symb.name, last)
				}
			} else if f.FixupType == FixupOffset {
				// for local symbols we know what the offset is so we can just write
				// it to the file. no need to create relocation record.
				if debug {
					log.Printf("fixup @ %x: offset for %s = %x", f.DataOffset, symb.name, symb.offset)
				}
				put16(data[f.DataOffset:], symb.offset)
			} else if f.FixupType == FixupSegment {
				// this one's tricker. the segment base won't be known until the program is loaded,
				// so we have to add a relocation record
				if symb.module != nil {
					// imported symbol: assume this is part of a faraddr patch,
					// so the segment is just set to 0
					if debug {
						log.Printf("fixup @ %x: faraddr segment for %s", f.DataOffset, symb.name)
					}
					continue
				}
				ri = seg.getOrMakeRelocInfoForSymbol(symb)
				last := ri.chain(ledata.StartOffset + f.DataOffset)
				put16(data[f.DataOffset:], last)
				if debug {
					log.Printf("fixup @ %x: segment for %s = %x", f.DataOffset, symb.name, last)
				}
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
			last := ri.chain(ledata.StartOffset + f.DataOffset)
			put16(data[f.DataOffset:], last)
			if debug {
				log.Printf("fixup @ %x: self segment reference = %x", f.DataOffset, last)
			}
		default:
			log.Printf("%s: warning: unknown fixup reftype: %#02x", filename, f.RefType)
			continue
		}
		if ri != nil {
			ri.patches = append(ri.patches, ledata.StartOffset+f.DataOffset)
		}
		//put16(data[f.DataOffset:], ri.last)
		//ri.last = f.DataOffset + ledata.StartOffset
	}
	return data
}

func (ri *RelocInfo) chain(addr int) int {
	last := ri.last
	ri.last = addr
	return last
}

func (seg *SegmentInfo) getOrMakeRelocInfoForSymbol(symb *Symbol) *RelocInfo {
	if symb.module != nil {
		// imported symbol
		return seg.getOrMakeRelocInfo(symb)
	} else {
		// internal symbol, so just a segment reference
		return seg.getOrMakeRelocInfo(symb.segment)
	}
}

func (seg *SegmentInfo) getSelfRelocInfo() *RelocInfo {
	return seg.getOrMakeRelocInfo(seg.num)
}

func (seg *SegmentInfo) getOrMakeRelocInfo(target RelocTarget) *RelocInfo {
	if ri, ok := seg.reloctab[target]; ok {
		return ri
	}
	ri := newRelocInfo(target)
	seg.reloctab[target] = ri
	seg.reloclist = append(seg.reloclist, ri)
	return ri
}

func newRelocInfo(target RelocTarget) *RelocInfo {
	return &RelocInfo{target: target, last: 0xffff}
}

func (ld *Linker) warnMissing(filename string, name string) {
	// TODO: only print once
	log.Printf("%s: warning: unresolved symbol %q", filename, name)
}

// puts the fixups in the right order according to the spans from the linkscript
func sortFixes(p []int, spans []RelocSpan) {
	if debug {
		log.Println("SortFixes:")
		log.Println("spans = ", spans)
		log.Printf("%x\n", p)
	}
	// first, sort in ascending order
	sort.Ints(p)

	// then, find descending spans and reverse them
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
	if debug {
		log.Printf("%x\n", p)
	}

}

func reverseInts(p []int) {
	for i, j := 0, len(p)-1; i < j; i, j = i+1, j-1 {
		p[i], p[j] = p[j], p[i]
	}
}

func put16(b []byte, v int) {
	if v&0xFFFF != v {
		panic(fmt.Sprint("put16: value exceeds 16 bits:", v))
	}
	b[0] = uint8(v)
	b[1] = uint8(uint(v) >> 8)
}

// writemapfile writes a list of all exported symbols and their addresses
func (ld *Linker) writeMapFile(filename string) error {
	if !strings.HasSuffix(filename, ".map") {
		// refuse to overwrite non-map files
		if _, err := os.Stat(filename); err == nil {
			return fmt.Errorf("file %q already exists; refusing to overwrite", filename)
		}
	}
	f, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer f.Close()
	bw := bufio.NewWriter(f)

	// mimicks nasms map format for now
	// TODO: replace with something better
	fmt.Fprintln(bw, "-- Symbols --------------------------------------------------------------------")
	fmt.Fprintln(bw)
	// first print const symbols
	printedHeader := false
	for i := range ld.segments {
		for _, symb := range ld.segments[i].symbols {
			if symb.constant {
				if !printedHeader {
					fmt.Fprintln(bw, "---- No Section ---------------------------------------------------------------")
					fmt.Fprintln(bw)
					fmt.Fprintln(bw, "Value     Name")
					printedHeader = true
				}
				fmt.Fprintf(bw, "%08x  %s\n", symb.offset, symb.name)
			}
		}
		//fmt.Fprintf(bw, "%08x  %s\n", ld.segments[i].size, fmt.Sprint("_segment_", ld.segments[i].num.Index, "_size"))
	}
	if printedHeader {
		fmt.Fprintln(bw)
	}
	// then actual symbols
	for i := range ld.segments {
		if i > 0 {
			fmt.Fprintln(bw)
		}
		// TODO: use actual segment name
		fmt.Fprintln(bw, "---- Section CODE -------------------------------------------------------------")
		fmt.Fprintln(bw)
		fmt.Fprintln(bw, "Real              Virtual           Name")
		base := ld.segments[i].start
		for _, symb := range ld.segments[i].symbols {
			if !symb.constant {
				fmt.Fprintf(bw, "%16x  %16x  %s\n", base+symb.offset, symb.offset, symb.name)
			}
		}
		//fmt.Fprintf(bw, "Size    %x\n", ld.segments[i].size)
	}
	return bw.Flush()
}

// round v up to next multiple of size
func align(v, size int) int {
	if v%size != 0 {
		v += size - v%size
	}
	return v
}
