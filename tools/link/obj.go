package main

// Reference for the OBJ file format:
//
// Tool Interface Standard (TIS)
// Portable Formats Specification Version 1.1
// Chapter III. Relocatable Object Format Module (OMF)
// https://refspecs.linuxfoundation.org/elf/TIS1.1.pdf

import (
	"encoding/hex"
	"fmt"
	"io"
)

type Record struct {
	Type     uint8
	Size     uint16
	Contents []byte
	Checksum uint8
}

func ReadRecord(r io.Reader) (*Record, error) {
	var header [3]byte
	_, err := io.ReadFull(r, header[:])
	if err != nil {
		return nil, err
	}

	typ := header[0]
	size := int(header[1]) | int(header[2])<<8

	if size < 1 {
		return nil, fmt.Errorf("record too small: %d", size)
	}
	if size > 1024 {
		return nil, fmt.Errorf("record too large: %d", size)
	}
	contents := make([]byte, size)
	if _, err := io.ReadFull(r, contents); err != nil {
		return nil, err
	}
	rec := &Record{
		Type:     typ,
		Size:     uint16(size),
		Contents: contents[:size-1],
		Checksum: contents[size-1],
	}
	return rec, nil
}

const (
	TypePubdef = 0x90
	TypeExtdef = 0x8c
	TypeLedata = 0xa0
	TypeFixup  = 0x9c
)

func dump(r io.Reader) error {
	for {
		rec, err := ReadRecord(r)
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}
		fmt.Printf("RECORD type %#0x, size %d\n", rec.Type, rec.Size)
		fmt.Print(hex.Dump(rec.Contents))
		switch rec.Type {
		case TypePubdef:
			pubdef(rec)
		case TypeFixup:
			fixup(rec)
		case TypeExtdef:
			extdef(rec)
		}
		fmt.Println()
	}
}

func fixup(r *Record) {
	data := r.Contents
	for len(data) > 0 {
		if data[0]&0x80 == 0 {
			// THREAD sub record
			fmt.Println("THREAD")
			skip := 2
			if data[1]&0x80 != 0 {
				skip = 3
			}
			data = data[skip:]
		} else {
			// FIXUP subrecord
			locationType := data[0] >> 2 & 15
			locationStr := "(unknown)"
			switch locationType {
			case 0:
				locationStr = "8-bit low"
			case 1:
				locationStr = "16-bit offset"
			case 2:
				locationStr = "16-bit segment base"
			case 3:
				locationStr = "32-bit pointer"
			case 4:
				locationStr = "8-bit high"
			case 9:
				locationStr = "32-bit offset"
			case 11:
				locationStr = "48-bit pointer"
			}
			dataOffset := uint(data[1]) | (uint(data[0]&3) << 8)

			frameType := int(data[2] >> 4)
			targetType := int(data[2] & 7)
			datum := int(data[3])
			extra := 0
			if datum&0x80 != 0 {
				datum = datum&0x7f<<8 | int(data[4])
				extra++
			}

			fmt.Printf("FIXUP %s @ %#x, F%d T%d, datum %d\n", locationStr, dataOffset, frameType, targetType, datum)
			data = data[4+extra:] // TODO
		}
	}
}

func pubdef(r *Record) {
	data := r.Contents
	bsi := data[1]
	data = data[2:] // base group index and base seg index
	if bsi == 0 {
		data = data[2:] // base frame
	}
	for len(data) > 0 {
		n := data[0]
		name := string(data[1 : n+1])
		offset := int(data[n+1]) + int(data[n+2])<<8

		data = data[1+n+3:]
		fmt.Printf("	%04x\t%s\n", offset, name)
	}
}

func extdef(r *Record) {
	data := r.Contents
	for i := 1; len(data) > 0; i++ {
		n := int(data[0])
		name := string(data[1 : n+1])
		typeIdx := int(data[n+1])
		skip := 1
		if typeIdx&0x80 != 0 {
			skip++
		}

		data = data[1+n+skip:]
		fmt.Printf("	%d\t%s\t%d\n", i, name, typeIdx)
	}
}

func ReadObjNames(r io.Reader) ([]ObjSymbol, error) {
	// TODO: maybe don't read the whole file
	var syms []ObjSymbol
	for {
		rec, err := ReadRecord(r)
		if err == io.EOF {
			return syms, nil
		}
		if err != nil {
			return syms, err
		}
		switch rec.Type {
		case TypePubdef:
			syms = append(syms, parsePubdef(rec)...)
		}
	}
}

func ReadExternalNames(r io.Reader) ([]string, error) {
	// TODO: maybe don't read the whole file
	var names []string
	for {
		rec, err := ReadRecord(r)
		if err == io.EOF {
			return names, nil
		}
		if err != nil {
			return names, err
		}
		switch rec.Type {
		case TypeExtdef:
			names = append(names, parseExtdef(rec)...)
		}
	}
}

type ObjSymbol struct {
	Offset int
	Name   string
	Const  bool
}

func parsePubdef(r *Record) []ObjSymbol {
	data := r.Contents
	bsi := data[1]
	data = data[2:] // base group index and base seg index
	if bsi == 0 {
		data = data[2:] // base frame
	}
	// we ignore the segment index because the files we're
	// concerned with only contain one segment per file
	// FIXME: support code&data segments in a single file
	var syms []ObjSymbol
	for len(data) > 0 {
		n := data[0]
		name := string(data[1 : n+1])
		offset := int(data[n+1]) + int(data[n+2])<<8
		syms = append(syms, ObjSymbol{Offset: offset, Name: name, Const: bsi == 0})
		data = data[1+n+2+1:]
	}
	return syms
}

func parseExtdef(r *Record) []string {
	data := r.Contents
	var names []string
	for len(data) > 0 {
		n := int(data[0])
		name := string(data[1 : n+1])
		var typeIdx int
		typeIdx, data = readIndex(data[1+n:])
		_ = typeIdx // debugging data; unused by us
		names = append(names, name)
	}
	return names
}

type ObjLedata struct {
	SegmentIndex int
	StartOffset  int
	Data         []byte
}

func ParseLedata(r *Record) ObjLedata {
	if r.Type != TypeLedata {
		panic(fmt.Sprintf("ParseLedata: wrong record type %x", r.Type))
	}
	data := r.Contents
	segmentIndex, data := readIndex(data)
	startOffset, data := read16(data)
	return ObjLedata{
		SegmentIndex: segmentIndex,
		StartOffset:  startOffset,
		Data:         data,
	}
}

func readIndex(b []byte) (int, []byte) {
	n := int(b[0])
	if n&0x80 != 0 {
		n = n&0x7f<<8 | int(b[1])
		return n, b[2:]
	} else {
		return n, b[1:]
	}
}

func read16(b []byte) (int, []byte) {
	n := int(b[0]) | int(b[1])<<8
	return n, b[2:]
}

type ObjFixup struct {
	FixupType int
	//LocationType int

	DataOffset int

	RefType  int
	RefIndex int
	//FrameType    int
	//TargetType   int
	//Datum        int
}

func ParseFixup(r *Record) ([]ObjFixup, error) {
	if r.Type != TypeFixup {
		panic(fmt.Sprintf("ParseFixup: wrong record type %x", r.Type))
	}
	data := r.Contents
	var list []ObjFixup
	for len(data) > 0 {
		// FIXUP subrecord
		var ft int = FixupUnknown
		switch data[0] & 0xFC {
		case 0xC4:
			ft = FixupOffset
		case 0xC8:
			ft = FixupSegment
		//case 0xCC:
		//	locationStr = "32-bit pointer"
		//case 0xE4:
		//	locationStr = "32-bit offset"
		default:
			return nil, fmt.Errorf("ParseFixup: unknown location type")
		}
		var rt int
		switch data[2] {
		case 0x54:
			rt = RefSegment
		case 0x56:
			rt = RefExternal
		default:
			return nil, fmt.Errorf("ParseFixup: unknown frame/target type")
		}
		var f ObjFixup
		f.DataOffset = int(data[1]) | (int(data[0]&3) << 8)
		f.FixupType = ft
		f.RefType = rt
		f.RefIndex = int(data[3]) // either a segment index or a symbol index
		extra := 0
		if f.RefIndex&0x80 != 0 {
			f.RefIndex = f.RefIndex&0x7f<<8 | int(data[4])
			extra = 1
		}
		list = append(list, f)
		data = data[4+extra:]
	}
	return list, nil
}

const (
	FixupUnknown = -1
	FixupSegment = 1
	FixupOffset  = 2
	//FixupPointer32 = 3
	//FixupOffset32  = 9
)

const (
	RefSegment  = 0
	RefExternal = 1
)
