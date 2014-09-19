package main

import (
	"flag"
	"fmt"
	"io"
	"os"
)

var skip = flag.Int64("skip", 0, "skip bytes")
var count = flag.Int64("count", 0, "byte count")

func main() {
	flag.Parse()
	_, err := os.Stdin.Seek(*skip, 1)
	if err != nil {
		fmt.Println(err)
		return
	}
	io.CopyN(os.Stdout, os.Stdin, *count)
}
