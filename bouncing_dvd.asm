b start

@include header.asm

@include logo.asm

shiftPalette:
stmfd r13!,{r0-r2}
mov r0,0x5000000
orr r0,r0,0x200

ldrh r1,[r0,2]
orr r0,r0,2

shiftPalLoop:
ldrh r2,[r0,2]
strh r2,[r0]+2!

tst r0,0xC
bne shiftPalLoop

sub r0,r0,2
strh r1,[r0]

ldmfd r13!,{r0-r2}
bx r14

start:
mov r0,0x4000000
ldr r1,=0x1440
strh r1,[r0]

mov r1,0x7000000
ldr r2,=%10000000000010100100000000010100 ; 32x16 obj at (10,20)
str r2,[r1]

mov r2,1 ; char 1
strh r2,[r1,4]

; DMA tranfer palette to 0x5000200
addr r2,palette
str r2,[r0,0xD4]

mov r2,0x5000000
orr r2,r2,0x200
str r2,[r0,0xD8]

ldr r2,=(%10000000000 << 21 | 8) ; 8 16-bit transfers: 1 per palette color
str r2,[r0,0xDC]

; DMA transfer obj to 0x6010000
addr r2,logo
str r2,[r0,0xD4]

mov r2,0x6000000
orr r2,r2,0x10000
orr r2,r2,0x20 ; obj is char 1
str r2,[r0,0xD8]

ldr r2,=(%10000100000 << 21 | 64) ; 64 32-bit transfers: 1 per pixel row in 8x8 obj
str r2,[r0,0xDC]

mov r2,%11 ; bits: xy 0:- 1:+

loop:
waitVBlankEnd:
ldrh r3,[r0,0x4]
tst r3,1
beq waitVBlankEnd
waitVBlankStart:
ldrh r3,[r0,0x4]
tst r3,1
bne waitVBlankStart

; x
ldrh r3,[r1,2]
mov r4,r3 lsl 23 ; only want coords
mov r4,r4 lsr 23 ; "

and r3,r3,%1111111000000000

cmp r4,0
orrle r2,r2,%10
blle shiftPalette

cmp r4,(240-32)
andge r2,r2,%01
blge shiftPalette

tst r2,%10
subeq r4,r4,1
addne r4,r4,1

orr r3,r3,r4
strh r3,[r1,2]

; y
ldrh r3,[r1]
and r4,r3,%11111111 ; only want coords

and r3,r3,%1111111100000000

cmp r4,0
orrle r2,r2,%01
blle shiftPalette

cmp r4,(160-16)
andge r2,r2,%10
blge shiftPalette

tst r2,%01
subeq r4,r4,1
addne r4,r4,1

orr r3,r3,r4
strh r3,[r1] ; can't strb the coords because OAM expects halfword (16-bit) writes :(
b loop
