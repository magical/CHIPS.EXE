CHIPS.EXE
====
This is a disassembly of Chip's Challenge for Windows 95.

It builds the following executable:

* CHIPS.EXE `sha256: 8e26acd67cf120bd5b512de4b4e78b80aca1579413cd04f3b2b68909a375866c`


Progress
----
The core game logic has been disassembled and extensively commented; see `logic.asm` and `movement.asm`.
Almost all of the game's memory has been mapped out; see `data.asm` and `structs.asm`.
If you are interested in the address of a particular variable, check out `variables.asm`.

Most of the rest of the code has been disassembled but may lack useful function/data labels and comments.

| Segment | Disassembled | Labels | Comments | Filename / purpose |
| --- | --- | --- | --- | --- |
| 1 | no | | | C runtime |
| 2 | yes | some | some | `seg2.asm` - UI / WinMain |
| 3 | yes | yes  | some | `logic.asm` - tile logic |
| 4 | yes | some | no   | `seg4.asm` - levelset I/O |
| 5 | yes | yes  | yes  | `seg5.asm` - tile graphics |
| 6 | yes | few  | no   | `seg6.asm` - dialog boxes |
| 7 | yes | yes  | yes  | `movement.asm` - chip & creature movement |
| 8 | yes | some | some | `sound.asm` - sound effects & MIDI |
| 9 | yes | yes  | yes  | `digits.asm` - counter graphics |
| 10 | yes | yes | some | `data.asm` |

Community
----
Join the [Bit Busters Discord][bbc].

[bbc]: https://discord.gg/Xd4dUY9

Dependencies
----
To build, you'll need the following programs installed:

* make
* nasm
* awk
* golang (optional, for building tools)

You'll also need an existing copy of `CHIPS.EXE` with the sha26sum given above,
to fill in the incomplete portions of the disassembly.

Some tools require python3, but they aren't used in the build.

Building
----

1. Copy the game executable to `base.exe` in this directory

2. Run `make`

3. (optional) Run `make check` to compare the output with the base image.
   This step requires golang.
