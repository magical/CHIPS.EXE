package main

import (
	"bufio"
	"encoding/binary"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"strings"
)

func main() {
	log.SetFlags(0)
	addr := flag.Int64("addr", 0, "address to read dialog from")
	flag.Parse()
	if *addr == 0 {
		log.Fatal("error: no -addr given")
	}
	if err := readDialog(os.Stdin, *addr); err != nil {
		log.Fatal(err)
	}
}

func readDialog(f *os.File, addr int64) error {
	_, err := f.Seek(addr, io.SeekStart)
	if err != nil {
		return err
	}
	r := bufio.NewReader(f)
	var dlg Dialog
	err = binary.Read(r, binary.LittleEndian, &dlg)
	if err != nil {
		return err
	}
	//fmt.Printf("dlg_style %#08x\n", dlg.Style)
	//fmt.Printf("dlg_count %d\n", dlg.Count)
	//fmt.Printf("dlg_x     %d\n", dlg.X)
	//fmt.Printf("dlg_y     %d\n", dlg.Y)
	//fmt.Printf("dlg_width %d\n", dlg.Width)
	//fmt.Printf("dlg_height %d\n", dlg.Height)

	fmt.Printf("    dd %#08x ; window style\n", dlg.Style)
	fmt.Printf("    db %d    ; number of items\n", dlg.Count)
	fmt.Printf("    dw %d, %d, %d, %d ; position and size\n", dlg.X, dlg.Y, dlg.Width, dlg.Height)

	//fmt.Println("menu", menu)
	//fmt.Println("window", windowClass)

	fmt.Printf("    db %#x   ; menu\n", dlg.Menu)
	fmt.Printf("    db %#x   ; window class\n", dlg.Class)

	caption, err := readCString(r)
	_ = err
	//fmt.Printf("caption %q, 0\n", caption)
	fmt.Printf("    db %q, 0 ; caption\n", caption)
	lo, err := r.ReadByte()
	hi, err := r.ReadByte()
	pointSize := int(lo) | int(hi)<<8
	//fmt.Printf("point size %d\n", pointSize)
	fmt.Printf("    dw %d ; font size\n", pointSize)
	font, err := readCString(r)
	//fmt.Printf("font %s\n", font)
	fmt.Printf("    db %q, 0 ; font\n", font)

	fmt.Printf("    ; Items\n")
	for i := 0; i < int(dlg.Count); i++ {
		var b = make([]byte, 0, 16)
		_, err = io.ReadFull(r, b[:15])
		if err != nil {
			return err
		}
		str, err := readCString(r)
		if err != nil {
			return err
		}
		str2, err := readCString(r)
		if err != nil {
			return err
		}
		//fmt.Printf("db % x, %v, %v\n", b[:15], nasmstr(str), nasmstr(str2))
		fmt.Printf("    db %s, %v, %v\n", strings.ReplaceAll(fmt.Sprintf("% #x", b[:15]), " ", ", "), nasmstr(str), nasmstr(str2))
	}
	return nil
}

type Dialog struct {
	Style  uint32
	Count  uint8
	X      uint16
	Y      uint16
	Width  uint16
	Height uint16
	Menu   uint8
	Class  uint8
}

// Read a zero-terminated string from f
func readCString(r *bufio.Reader) (string, error) {
	var s []byte
	for {
		b, err := r.ReadByte()
		if err != nil {
			if err == io.EOF {
				err = io.ErrUnexpectedEOF
			}
			return "", err
		}
		if b == 0 {
			break
		}
		s = append(s, b)
	}
	return string(s), nil
}

type Item struct {
	// names are all tentative
	X      uint16
	Y      uint16
	Width  uint16
	Height uint16
	ID     int16
	V1     uint8
	V2     uint16
	V3     uint16
}

type nasmstr string

func (s nasmstr) String() string {
	if s == "" {
		return "0"
	}
	return fmt.Sprintf("%q", string(s)) + ", 0"
}
