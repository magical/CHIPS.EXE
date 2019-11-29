package main

// This tool is (will be) a "half" linker: it takes several
// .obj files as input, performs symbol resolution and relocation,
// and writes out a .bin file for each object which can then
// be copied into the final executable.

import (
	"flag"
	"log"
	"os"
)

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
