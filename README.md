CHIPS.EXE
====
This is a disassembly of Chip's Challenge for Windows 95.

It builds the following executable:

* CHIPS.EXE `sha256: 8e26acd67cf120bd5b512de4b4e78b80aca1579413cd04f3b2b68909a375866c`


Progress
----
All of the code has been disassembled.

The core game logic has been extensively commented; see `logic.asm` and `movement.asm`.
Almost all of the game's memory has been mapped out; see `data.asm` and `structs.asm`.
If you are interested in the address of a particular variable, check out `variables.asm`.

The rest of the code has been disassembled but may lack useful function/data labels and comments.

| Segment | Disassembled | Labels | Comments | Filename / purpose |
| --- | --- | --- | --- | --- |
| 1 | yes | func | few  | `crt.asm` - C runtime |
| 2 | yes | some | some | `seg2.asm` - UI / WinMain |
| 3 | yes | yes  | some | `logic.asm` - tile logic |
| 4 | yes | some | no   | `seg4.asm` - levelset I/O |
| 5 | yes | yes  | yes  | `seg5.asm` - tile graphics |
| 6 | yes | few  | no   | `seg6.asm` - dialog boxes |
| 7 | yes | yes  | yes  | `movement.asm` - chip & creature movement |
| 8 | yes | some | some | `sound.asm` - sound effects & MIDI |
| 9 | yes | yes  | yes  | `digits.asm` - counter graphics |
| 10 | yes | yes | some | `data.asm` |

News
----
- **2020-11-21** Every segment has been disassembled!
  You can now build `chips.exe` from scratch, without a copy of the original game.
  Thanks to @zrax for supplying the last segment (`crt.asm`).

- **2020-11-21** Code segments are now completely shiftable, meaning that you can
  add/remove instructions without worring about changing code offsets.

- **2020-11-14** We have a linker! Building now requires Go (to build the linker).

Community
----
Join the [Bit Busters Discord][bbc].

[bbc]: https://discord.gg/Xd4dUY9

Dependencies
----
To build, you'll need the following programs installed:

* make
* nasm >= 2.14
* awk
* golang

Go is required for building the linker and (optionally) some other tools.

Some tools require python3, but they aren't used in the build.

Building
----

1. (optional) Copy the game executable to `base.exe` in this directory

2. Run `make`

3. (optional) Run `make check` to compare the output with the base image.
