#!/usr/bin/awk
# Some instructions have two valid encodings.
#
#     89D8              mov ax,bx
#     8BC3              mov ax,bx
#
# NASM chooses the former, but CHIPS.EXE uses the latter.
# In order to build a byte-for-byte identical binary,
# we assemble these instructions manually,
# replacing "mov ax,bx" with "db 0x8B,0xC3".
{
    if ($1 == "mov" && $2 == "al,ah") { print "db 0x8a,0xc4"; next }
    if ($1 == "mov" && $2 == "dl,al") { print "db 0x8a,0xd0"; next }
    if ($1 == "mov" && $2 == "dh,cl") { print "db 0x8a,0xf1"; next }
    if ($1 == "sub" && $2 == "ah,ah") { print "db 0x2a,0xe4"; next }
    if ($1 == "sub" && $2 == "ch,ch") { print "db 0x2a,0xed"; next }
    if ($1 == "sbb" && $2 == "al,al") { print "db 0x1a,0xc0"; next }

    if      ($1 == "mov")   opcod = 0x8B;
    else if ($1 == "add")   opcod = 0x03;
    else if ($1 == "sub")   opcod = 0x2B;
    else if ($1 == "sbb")   opcod = 0x1B;
    else if ($1 == "xor")   opcod = 0x33;
    else if ($1 == "or")    opcod = 0x0B;
    else if ($1 == "cmp")   opcod = 0x3B;
    else { print; next }

    if      ($2 == "ax,ax") modrm = 0xC0;
    else if ($2 == "ax,cx") modrm = 0xC1;
    else if ($2 == "ax,dx") modrm = 0xC2;
    else if ($2 == "ax,bx") modrm = 0xC3;
    else if ($2 == "ax,sp") modrm = 0xC4;
    else if ($2 == "ax,bp") modrm = 0xC5;
    else if ($2 == "ax,si") modrm = 0xC6;
    else if ($2 == "ax,di") modrm = 0xC7;
    else if ($2 == "cx,ax") modrm = 0xC8;
    else if ($2 == "cx,cx") modrm = 0xC9;
    else if ($2 == "cx,dx") modrm = 0xCA;
    else if ($2 == "cx,bx") modrm = 0xCB;
    else if ($2 == "cx,sp") modrm = 0xCC;
    else if ($2 == "cx,bp") modrm = 0xCD;
    else if ($2 == "cx,si") modrm = 0xCE;
    else if ($2 == "cx,di") modrm = 0xCF;
    else if ($2 == "dx,ax") modrm = 0xD0;
    else if ($2 == "dx,cx") modrm = 0xD1;
    else if ($2 == "dx,dx") modrm = 0xD2;
    else if ($2 == "dx,bx") modrm = 0xD3;
    else if ($2 == "dx,sp") modrm = 0xD4;
    else if ($2 == "dx,bp") modrm = 0xD5;
    else if ($2 == "dx,si") modrm = 0xD6;
    else if ($2 == "dx,di") modrm = 0xD7;
    else if ($2 == "bx,ax") modrm = 0xD8;
    else if ($2 == "bx,cx") modrm = 0xD9;
    else if ($2 == "bx,dx") modrm = 0xDA;
    else if ($2 == "bx,bx") modrm = 0xDB;
    else if ($2 == "bx,sp") modrm = 0xDC;
    else if ($2 == "bx,bp") modrm = 0xDD;
    else if ($2 == "bx,si") modrm = 0xDE;
    else if ($2 == "bx,di") modrm = 0xDF;
    else if ($2 == "sp,ax") modrm = 0xE0;
    else if ($2 == "sp,cx") modrm = 0xE1;
    else if ($2 == "sp,dx") modrm = 0xE2;
    else if ($2 == "sp,bx") modrm = 0xE3;
    else if ($2 == "sp,sp") modrm = 0xE4;
    else if ($2 == "sp,bp") modrm = 0xE5;
    else if ($2 == "sp,si") modrm = 0xE6;
    else if ($2 == "sp,di") modrm = 0xE7;
    else if ($2 == "bp,ax") modrm = 0xE8;
    else if ($2 == "bp,cx") modrm = 0xE9;
    else if ($2 == "bp,dx") modrm = 0xEA;
    else if ($2 == "bp,bx") modrm = 0xEB;
    else if ($2 == "bp,sp") modrm = 0xEC;
    else if ($2 == "bp,bp") modrm = 0xED;
    else if ($2 == "bp,si") modrm = 0xEE;
    else if ($2 == "bp,di") modrm = 0xEF;
    else if ($2 == "si,ax") modrm = 0xF0;
    else if ($2 == "si,cx") modrm = 0xF1;
    else if ($2 == "si,dx") modrm = 0xF2;
    else if ($2 == "si,bx") modrm = 0xF3;
    else if ($2 == "si,sp") modrm = 0xF4;
    else if ($2 == "si,bp") modrm = 0xF5;
    else if ($2 == "si,si") modrm = 0xF6;
    else if ($2 == "si,di") modrm = 0xF7;
    else if ($2 == "di,ax") modrm = 0xF8;
    else if ($2 == "di,cx") modrm = 0xF9;
    else if ($2 == "di,dx") modrm = 0xFA;
    else if ($2 == "di,bx") modrm = 0xFB;
    else if ($2 == "di,sp") modrm = 0xFC;
    else if ($2 == "di,bp") modrm = 0xFD;
    else if ($2 == "di,si") modrm = 0xFE;
    else if ($2 == "di,di") modrm = 0xFF;
    else { print; next }

    printf("    db %#x,%#x\n", opcod, modrm);
}
