// linker script parsing

package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"
)

func (ld *Linker) ParseScript(r io.Reader) error {
	//f, err := os.Open(module + ".sym")
	//if err != nil {
	//	return nil, err
	//}
	//defer f.Close()
	//br := bufio.NewReader(f)

	scanner := bufio.NewScanner(os.Stdin)
	//var m = make(map[int]string)
	lineno := 0
	for scanner.Scan() {
		lineno++
		line := strings.TrimSpace(scanner.Text())

		// skip empty lines
		if line == "" || strings.HasPrefix(line, ";") {
			continue
		}

		// split line and strip comments
		args := strings.Fields(line)
		for i := range args {
			if strings.HasPrefix(args[i], ";") {
				args = args[:i]
				break
			}
		}

		var err error
		switch strings.ToUpper(args[0]) {
		case "MODULE":
			err = ld.scriptModule(args)
		case "RELOC":
			err = ld.scriptReloc(args)
		default:
			err = fmt.Errorf("unknown command: %s", args[0])
		}
		if err != nil {
			return parseError(lineno, err.Error())
		}
	}
	if err := scanner.Err(); err != nil {
		return err
	}
	return nil
}

func parseError(lineno int, msg string) error {
	// TODO: parseError type?
	return fmt.Errorf("%d:%s", lineno, msg)
}

func (ld *Linker) scriptModule(args []string) error {
	var num int
	var modname string
	var symfile string
	switch len(args) {
	default:
		return errors.New("wrong number of arguments to MODULE")
	case 4:
		// MODULE [num] [modname] [symfile]
		symfile = args[3]
		fallthrough
	case 3:
		// MODULE [num] [modname]
		n, err := strconv.ParseUint(args[1], 10, 0)
		if err != nil {
			return fmt.Errorf("invalid module number: %w", err)
		}
		if n == 0 {
			return fmt.Errorf("module number can't be zero")
		}
		num = int(num)
		modname = args[2]
	}

	mod, err := ld.addModule(num, modname)
	if err != nil {
		return err
	}
	if symfile != "" {
		return ld.readSymfile(mod, symfile)
	}
	return nil
}

func (ld *Linker) scriptReloc(args []string) error {
	var patchlist []string
	for i := range args {
		if args[i] == "=" {
			patchlist = args[i+1:]
			args = args[:i]
			break
		}
	}

	if len(args) != 4 {
		return errors.New("wrong number of arguments to RELOC")
	}
	// RELOC [seg] [module] [symbol]
	n, err := strconv.ParseUint(args[1], 10, 0)
	if err != nil {
		return fmt.Errorf("invalid segment number: %w", err)
	}
	if n == 0 {
		return fmt.Errorf("segment number can't be zero")
	}
	seg := int(n)
	modname := args[2]
	if strings.ToUpper(modname) == "SEGMENT" {
		// RELOC [seg] SEGMENT [number]
		n, err := strconv.ParseInt(args[3], 10, 0)
		if err != nil {
			return fmt.Errorf("invalid segment: %w", err)
		}
		patches, err := parsePatchlist(patchlist)
		if err != nil {
			return err
		}
		return ld.addRelocInternal(seg, int(n), patches)
	} else {
		symbol := args[3]
		// TODO orginals
		if !ld.hasModule(modname) {
			return fmt.Errorf("no such module: %s", modname)
		}
		//symb, err := ld.lookup(modname, symbol)
		//if err != nil {
		//	return fmt.Errorf("module %s: no such symbol %s", modname, symbol) // XXX wrap err?
		//}
		patches, err := parsePatchlist(patchlist)
		if err != nil {
			return err
		}
		symb := symbol // XXX
		return ld.addRelocExternal(seg, symb, patches)
	}
}

// Parses a patchlist into a sequance of spans.
//
// A patchlist is a list of increasing hexadecimal addresses, with each address
// followed by either a plus sign or a minus sign.
//
// 	0+ 124- abc-
//
// An empty patchlist is valid and corresponds to 0+
func parsePatchlist(list []string) ([]RelocSpan, error) {
	if len(list) == 0 {
		return []RelocSpan{{0, MaxSpan, true}}, nil
	}
	var spans []RelocSpan
	for _, s := range list {
		desc := !strings.HasSuffix(s, "-")
		if t := strings.TrimRight(s, "+-"); len(t) != len(s)-1 {
			if len(t) == len(s) {
				return nil, fmt.Errorf("invalid address: %q has no direction", s)
			} else {
				return nil, fmt.Errorf("invalid address: %q has multiple signs", s)
			}
		} else {
			s = t
		}
		n, err := strconv.ParseInt(s, 16, 16)
		if err != nil {
			return nil, fmt.Errorf("invalid address: %w", err)
		}
		spans = append(spans, RelocSpan{Low: uint(n), Desc: desc})
	}
	for i := range spans {
		if i == len(spans)-1 {
			spans[i].High = MaxSpan
		} else {
			spans[i].High = spans[i+1].Low
		}
	}
	return spans, nil
}

// MaxSpan is the largest possible value for a span address
const MaxSpan = 1<<16 - 1

type RelocSpan struct {
	Low  uint // start of the span, inclusive
	High uint // end of the span, inclusive
	Desc bool // ascending (false) or descending (true)
}

// TODO: stubs
func (ld *Linker) hasModule(name string) bool { return false }
func (ld *Linker) addRelocExternal(segment int, symb string /*Symbol*/, patches []RelocSpan) error {
	return nil
}
func (ld *Linker) addRelocInternal(segment, toSegment int, patches []RelocSpan) error { return nil }
func (ld *Linker) readSymfile(mod *Module, filename string) error                     { return nil }
