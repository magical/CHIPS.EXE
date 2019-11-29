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

			fmt.Printf("FIXUP %s @ %#x, F%d T%d, datum %d\n", locationStr, dataOffset, frameType, targetType, datum)
			data = data[4:] // TODO
		}
	}
}

func pubdef(r *Record) {
	data := r.Contents
	data = data[2:] // base group index and base seg index
	for len(data) > 0 {
		n := data[0]
		name := string(data[1 : n+1])
		offset := int(data[n+1]) + int(data[n+2])<<8

		data = data[1+n+3:]
		fmt.Printf("	%04x\t%s\n", offset, name)
	}
}
