CHIPS.EXE
====

This is a disassembly of Chip's Challenge for Windows 95.

It builds the following executable:

* CHIPS.EXE `sha256: 8e26acd67cf120bd5b512de4b4e78b80aca1579413cd04f3b2b68909a375866c`


Progress
----
Most of the game logic has been disassembled; see `logic.asm` and `movement.asm`.


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
