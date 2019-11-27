package main

import (
	"encoding/hex"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
)

type Record struct {
	Type     uint8
	Size     uint16
	Contents []byte
	Checksum uint8
}

func ReadRecord(f *os.File) (*Record, error) {
	var header [3]byte
	_, err := io.ReadFull(f, header[:])
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
	if _, err := io.ReadFull(f, contents); err != nil {
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

func dump(f *os.File) error {
	for {
		rec, err := ReadRecord(f)
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}
		fmt.Printf("RECORD type %#0x, size %d\n", rec.Type, rec.Size)
		fmt.Println(hex.Dump(rec.Contents))
	}
}

func main() {
	log.SetFlags(0)
	flag.Parse()
	f, err := os.Open(flag.Arg(0))
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()
	if err := dump(f); err != nil {
		log.Fatal(err)
	}

}
