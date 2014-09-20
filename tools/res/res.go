// This program prints the resource table from an NE executable.
package main

// http://wiki.osdev.org/NE

import (
	"encoding/binary"
	"flag"
	"fmt"
	"io"
	"os"
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

	var res []Resource
	var block ResBlock
	f.Seek(off+int64(ne.ResTableOffset), 0)
	resShift := read16(f)
	for {
		err = binary.Read(f, le, &block)
		if err != nil {
			fmt.Println(err)
			return
		}
		if block.TypeID == 0 {
			break
		}
		resEntries := make([]ResEntry, block.Num)
		err = binary.Read(f, le, resEntries)
		if err != nil {
			fmt.Println(err)
			return
		}
		for _, e := range resEntries {
			res = append(res, Resource{
				TypeID: block.TypeID,
				ResourceID: e.ResourceID,
				Sector: e.Sector,
				Length: e.Length,
				Flag:	e.Flag,
			})
		}
	}

	for i := range res {
		printResource(&res[i], resShift, f, off+int64(ne.ResTableOffset))
	}
}

var resourceTypes = []string{
	"0",
	"RT_CURSOR",
	"RT_BITMAP",
	"RT_ICON",
	"RT_MENU",
	"RT_DIALOG",
	"RT_STRING",
	"RT_FONTDIR",
	"RT_FONT",
	"RT_ACCELERATOR",
	"RT_RCDATA",
	"RT_MESSAGETABLE",
	"RT_GROUP_CURSOR",
	"RT_GROUP_ICON",
	"RT_VERSION",
	"RT_DLGINCLUDE",
	"RT_PLUGPLAY",
	"RT_VXD",
	"RT_ANICURSOR",
	"RT_ANIICON",
	"RT_HTML",
}

func printResource(r *Resource, resShift uint16, f *os.File, base int64) {
	var typeid interface{}
	var resid  interface{}
	if r.TypeID >= 0x8000 && int(r.TypeID)-0x8000 < len(resourceTypes) {
		typeid = resourceTypes[r.TypeID-0x8000]
	} else {
		typeid = fmt.Sprintf("%x", r.TypeID)
	}
	if r.ResourceID < 0x8000 {
		resid = readStringAt(f, base+int64(r.ResourceID))
	} else {
		resid = fmt.Sprintf("%x", r.ResourceID-0x8000)
	}
	fmt.Printf("TypeID:     %v\n", typeid)
	fmt.Printf("ResourceID: %v\n", resid)
	fmt.Printf("Offset:     %x\n", uint(r.Sector) << resShift)
	// EXEFMT says that the length field is measured in bytes.
	// It is a lie.
	fmt.Printf("Length:     %x\n", uint(r.Length) << resShift)
	fmt.Printf("Flag:       %x\n", r.Flag)
	fmt.Println()
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

type ResBlock struct {
	TypeID	uint16
	Num	uint16
	_	uint32
}

type ResEntry struct {
	Sector	uint16
	Length	uint16
	Flag	uint16
	ResourceID  uint16
	_	uint32
}

type Resource struct {
	TypeID	uint16
	Sector	uint16
	Length	uint16
	Flag	uint16
	ResourceID  uint16
}
