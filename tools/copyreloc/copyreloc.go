// This program copies relocation data for a given segment from
// from a 16-bit windows NE executable to a binary file
package main

import (
	"encoding/binary"
	"flag"
	"fmt"
	"io"
	"os"
	"sort"
)

var le = binary.LittleEndian

const verbose = false

func main() {
	segFlag := flag.Int("seg", 0, "segment to copy")
	fromFlag := flag.String("from", "", "executable to copy from")
	toFlag := flag.String("to", "", "bin file to copy to")
	flag.Parse()
	if *segFlag == 0 || *fromFlag == "" || *toFlag == "" {
		fmt.Fprintln(os.Stderr, "error: missing required args -seg, -from, and -to")
		os.Exit(1)
	}

	exe, err := os.Open(*fromFlag)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	defer exe.Close()

	dst, err := os.OpenFile(*toFlag, os.O_RDWR, 0)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	defer dst.Close()

	if err := copyReloc(exe, dst, *segFlag); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	if err := dst.Close(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func copyReloc(f, dst *os.File, segment int) error {
	_, err := f.Seek(0x3C, 0)
	if err != nil {
		return err
	}
	off16, err := read16(f)
	if err != nil {
		return err
	}
	off := int64(off16)
	_, err = f.Seek(off, 0)
	if err != nil {
		return err
	}
	var ne NE
	err = binary.Read(f, le, &ne)
	if err != nil {
		return err
	}

	segments := make([]Segment, ne.SegCount)
	_, err = f.Seek(off+int64(ne.SegTableOffset), 0)
	if err != nil {
		return err
	}
	err = binary.Read(f, le, segments)
	if err != nil {
		return err
	}

	if !(1 <= segment && segment <= len(segments)) {
		return fmt.Errorf("segment %d does not exist; max segment=%d", segment, len(segments)-1)
	}

	seg := &segments[segment-1]

	segOffset := int64(seg.Offset) << ne.SectorShift
	if verbose {
		fmt.Printf("Segment %d\n", segment)
		fmt.Printf("  Start: %4x\n", segOffset)
		fmt.Printf("  Size:  %4x\n", seg.Size)
		//fmt.Printf("         %4x\n", seg.AllocSize)
		if seg.Flags&1 == SegData {
			fmt.Println("  Type: Data")
		} else {
			fmt.Println("  Type: Code")
		}
		fmt.Println()
	}

	if seg.Flags&SegHasReloc == 0 {
		return fmt.Errorf("segment %d has no relocations", segment)
	}

	/* Read relocation data */
	_, err = f.Seek(segOffset+int64(seg.Size), 0)
	if err != nil {
		return err
	}
	nreloc, err := read16(f)
	if err != nil {
		return err
	}
	relocdata := make([]byte, 8*nreloc)
	_, err = io.ReadFull(f, relocdata[:])
	if err != nil {
		return fmt.Errorf("reading relocation data: %v", err)
	}
	var patchlist []Patch
	for j := 0; j < int(nreloc); j++ {
		r := relocdata[j*8 : j*8+8]
		switch r[1] {
		case 0: // INTERNAL
		case 1, 2: // IMPORT
		case 3: // OSFIXUP
		default:
			return fmt.Errorf("internal error: unknown relocation type %d", r[1])
		}

		// Follow source chain
		x := uint16(r[2]) + uint16(r[3])<<8
		for x != 0xffff {
			_, err := f.Seek(segOffset+int64(x), 0)
			if err != nil {
				return err
			}
			value, err := read16(f)
			if err != nil {
				return err
			}

			patchlist = append(patchlist, Patch{
				Addr:  int64(x),
				Value: value,
			})

			x = value
		}
	}

	sort.Sort(byAddress(patchlist))

	dstSize, err := dst.Seek(0, io.SeekEnd)
	if err != nil {
		return err
	}

	if dstSize == int64(seg.Size)+int64(2+len(relocdata)) {
		fmt.Fprintln(os.Stderr, "warning: it looks like the destination file has already been patched - proceeding anyway")
		_, err = dst.Seek(int64(seg.Size), io.SeekStart)
		if err != nil {
			return err
		}
	} else if dstSize != int64(seg.Size) {
		return fmt.Errorf("error: destination file must be the same size as the segment (%d bytes), not %d bytes", dstSize, seg.Size)
	}

	err = write16(dst, nreloc)
	if err != nil {
		return err
	}
	_, err = dst.Write(relocdata[:])
	if err != nil {
		return err
	}

	for _, patch := range patchlist {
		_, err := dst.Seek(int64(patch.Addr), 0)
		if err != nil {
			return err
		}
		err = write16(dst, patch.Value)
		if err != nil {
			return err
		}
	}

	return nil
}

func read16(f *os.File) (uint16, error) {
	var b [2]byte
	_, err := io.ReadFull(f, b[:])
	if err != nil {
		return 0, err
	}
	return uint16(b[0]) + uint16(b[1])<<8, nil
}

func write16(f *os.File, v uint16) error {
	var b [2]byte
	b[0] = byte(v)
	b[1] = byte(v >> 8)
	_, err := f.Write(b[:])
	return err
}

type Patch struct {
	Addr  int64
	Value uint16
}

type byAddress []Patch

func (p byAddress) Len() int           { return len(p) }
func (p byAddress) Less(i, j int) bool { return p[i].Addr < p[j].Addr }
func (p byAddress) Swap(i, j int)      { p[i], p[j] = p[j], p[i] }

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
	SegCode = 0
	SegData = 1

	SegMovable     = 1 << 4
	SegPreload     = 1 << 6
	SegHasReloc    = 1 << 8
	SegDiscardable = 1 << 12
)
