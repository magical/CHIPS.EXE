// This program prints relocation data from 16-bit windows NE executables.
package main

// http://wiki.osdev.org/NE

import (
	"encoding/binary"
	"flag"
	"fmt"
	"io"
	"os"
	"sort"

	"github.com/kr/pretty"
)

var le = binary.LittleEndian

func main() {
	flag.Parse()
	f, err := os.Open(flag.Arg(0))
	if err != nil {
		fmt.Println(err)
		return
	}
	f.Seek(0x3C, 0)
	off := int64(read16(f))
	f.Seek(off, 0)
	var ne NE
	err = binary.Read(f, le, &ne)
	if err != nil {
		fmt.Println(err)
		return
	}
	pretty.Println(&ne)

	modNames := make([]string, ne.ModRefs)
	f.Seek(off+int64(ne.ModRefTable), 0)
	for i := range modNames {
		off := off + int64(ne.ImportNameTable) + int64(read16(f))
		modNames[i] = readStringAt(f, off)
	}

	segments := make([]Segment, ne.SegCount)
	f.Seek(off+int64(ne.SegTableOffset), 0)
	err = binary.Read(f, le, segments)
	if err != nil {
		fmt.Println(err)
		return
	}

	importNameOff := off + int64(ne.ImportNameTable)

	for i := range segments {
		seg := &segments[i]
		fmt.Printf("Segment %d\n", 1+i)
		segOffset := int64(seg.Offset) << ne.SectorShift
		fmt.Printf("  Start: %4x\n", segOffset)
		fmt.Printf("  Size:  %4x\n", seg.Size)
		//fmt.Printf("         %4x\n", seg.AllocSize)
		if seg.Flags&SegData == 0 {
			fmt.Println("  Type: Code")
		} else {
			fmt.Println("  Type: Data")
		}
		flg := ""
		if seg.Flags&SegMovable != 0 {
			if flg != "" {
				flg += " "
			}
			flg += "Movable"
		}
		if seg.Flags&SegPreload != 0 {
			if flg != "" {
				flg += " "
			}
			flg += "Preload"
		}
		if seg.Flags&SegHasReloc != 0 {
			if flg != "" {
				flg += " "
			}
			flg += "HasReloc"
		}
		if seg.Flags&SegDiscardable != 0 {
			if flg != "" {
				flg += " "
			}
			flg += "Discardable"

		}
		fmt.Printf("  Flags: %s\n", flg)
		fmt.Println()

		if seg.Flags&SegHasReloc == 0 {
			continue
		}

		/* Read relocation data */
		f.Seek(segOffset+int64(seg.Size), 0)
		nreloc := read16(f)
		reloc := make([]byte, 8*nreloc)
		_, err = io.ReadFull(f, reloc[:])
		if err != nil {
			fmt.Println(err)
			continue
		}
		var reloclist []Reloc
		for j := 0; j < int(nreloc); j++ {
			r := reloc[j*8 : j*8+8]
			typ := "unknown"
			switch r[0] {
			case 0:
				typ = "LOBYTE"
			case 2:
				typ = "SEGMENT"
			case 3:
				typ = "FARADDR"
			case 5:
				typ = "OFFSET"
			}
			val := ""
			switch r[1] {
			case 0:
				seg := r[4]
				num := int(r[6]) + int(r[7])<<8
				if seg == 0xff {
					// Address in movable segment,
					// specified by entry point ordinal
					val = fmt.Sprintf("INTERNAL .%d", num)
				} else {
					// Address in fixed segment,
					// specified by segment number
					// and offset
					val = fmt.Sprintf("INTERNAL %d:%d", seg, num)
				}
			case 1, 2:
				mod := int(r[4]) + int(r[5])<<8
				num := int(r[6]) + int(r[7])<<8
				var modName interface{} = mod
				var entry interface{} = num
				if mod-1 < len(modNames) {
					modName = modNames[mod-1]
				}
				if r[1] == 2 {
					entry = readStringAt(f, importNameOff+int64(num))
				}
				val = fmt.Sprintf("IMPORT %v.%v", modName, entry)
			case 3:
				val = "OSFIXUP"
			default:
				val = "???"
			}
			str := fmt.Sprint(typ, " ", val)

			// Follow source chain
			x := uint16(r[2]) + uint16(r[3])<<8
			for ; x != 0xffff; x = read16(f) {
				reloclist = append(reloclist, Reloc{
					Addr:   segOffset + int64(x),
					String: str,
				})

				f.Seek(segOffset+int64(x), 0)
			}
		}

		// Sort relocations
		sort.Sort(byAddress(reloclist))

		// Print relocations
		for _, r := range reloclist {
			fmt.Printf("  Reloc @ %4X %s\n", r.Addr, r.String)
		}
		fmt.Println()
	}
}

func readStringAt(f *os.File, off int64) string {
	var b [1]byte
	f.ReadAt(b[:], off)
	len := b[0]
	s := make([]byte, len)
	f.ReadAt(s[:], off+1)
	return string(s)
}

func read16(f *os.File) uint16 {
	var b [2]byte
	_, err := io.ReadFull(f, b[:])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	return uint16(b[0]) + uint16(b[1])<<8
}

type Reloc struct {
	Addr   int64
	String string
}

type byAddress []Reloc

func (r byAddress) Len() int           { return len(r) }
func (r byAddress) Less(i, j int) bool { return r[i].Addr < r[j].Addr }
func (r byAddress) Swap(i, j int)      { r[i], r[j] = r[j], r[i] }

/*
type byAddress []byte

func (b byAddress) Len() int { return len(b) / 8 }
func (b byAddress) Swap(i, j int) {
	s, r := b[i*8:], b[j*8:]
	for k := 0; k < 8; k++ {
		s[k], r[k] = r[k], s[k]
	}
}
func (b byAddress) Less(i, j int) bool {
	addr0 := int(b[i*8+2]) + int(b[i*8+3])<<8
	addr1 := int(b[j*8+2]) + int(b[j*8+3])<<8
	return addr0 < addr1
}
*/

type NE struct {
	Sig               [2]byte  // "NE"
	MajLinkerVersion  uint8    // The major linker version
	MinLinkerVersion  uint8    // The minor linker version
	EntryTableOffset  uint16   // Offset of entry table, see below
	EntryTableLength  uint16   // Length of entry table in bytes
	FileLoadCRC       uint32   // UNKNOWN - PLEASE ADD INFO
	ProgFlags         uint8    // Program flags, bitmapped
	ApplFlags         uint8    // Application flags, bitmapped
	AutoDataSegIndex  uint16   // The automatic data segment index
	InitHeapSize      uint16   // The intial local heap size
	InitStackSize     uint16   // The inital stack size
	EntryPoint        uint32   // CS:IP entry point, CS is index into segment table
	InitStack         uint32   // SS:SP inital stack pointer, SS is index into segment table
	SegCount          uint16   // Number of segments in segment table
	ModRefs           uint16   // Number of module references (DLLs)
	NoResNamesTabSiz  uint16   // Size of non-resident names table, in bytes
	SegTableOffset    uint16   // Offset of segment table
	ResTableOffset    uint16   // Offset of resources table
	ResidNamTable     uint16   // Offset of resident names table
	ModRefTable       uint16   // Offset of module reference table
	ImportNameTable   uint16   // Offset of imported names table (array of counted strings, terminated with string of length 00h)
	OffStartNonResTab uint32   // Offset from start of file to non-resident names table
	MovEntryCount     uint16   // Count of moveable entry point listed in entry table
	SectorShift       uint16   // File alignment size shift count (0=9(default 512 byte pages))
	NResTabEntries    uint16   // Number of resource table entries
	TargOS            uint8    // Target OS
	OS2EXEFlags       uint8    // Other OS/2 flags
	RetThunkOffset    uint16   // Offset to return thunks or start of fast-load area
	SegRefThunksOff   uint16   // Offset to segment reference thunks or size of fast-load area
	MinCodeSwap       uint16   // Minimum code swap area size
	ExpctWinVer       [2]uint8 // Expected windows version (minor first)
}

type Segment struct {
	Offset uint16 // in segments
	Size   uint16 // in bytes, 0 == 64Ki
	Flags  uint16 /*
	   0 - set: data, unset: code
	   1 - set: preallocated
	   2 - set: loaded
	   3 - reserved
	   4 - set: movable, unset: fixed
	   5 - set: pure or shareable, unset: impure or nonshareable
	   6 - set: preload, unset: loadoncall
	   7 - set: executeonly if code segment, readonly if data segment
	   8 - set: has relocation data
	   12 - set: discardable
	*/
	AllocSize uint16
}

const (
	SegData        = 0
	SegCode        = 0
	SegMovable     = 1 << 4
	SegPreload     = 1 << 6
	SegHasReloc    = 1 << 8
	SegDiscardable = 1 << 12
)
