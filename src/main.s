; -------------------------------------------------------------------------
; Scaling demo
; By Ralakimus 2021
; -------------------------------------------------------------------------
; Main source file
; -------------------------------------------------------------------------

; -------------------------------------------------------------------------
; Constants
; -------------------------------------------------------------------------

BUFWIDTH	EQU	256			; Buffer width in pixels
BUFHEIGHT	EQU	224			; Buffer height in pixels

BUFWIDTHTILE	EQU	(BUFWIDTH+((8-(BUFWIDTH%8))%8))/8
BUFHEIGHTTILE	EQU	(BUFHEIGHT+((8-(BUFHEIGHT%8))%8))/8

BUFSIZE		EQU	(BUFWIDTHTILE*BUFHEIGHTTILE*$20)/2

; -------------------------------------------------------------------------
; Variables
; -------------------------------------------------------------------------

	rsset	LOCALVARS
bufferHigh	rs.b	BUFSIZE			; High word buffer
bufferLow	rs.b	BUFSIZE			; Low word buffer

scale		rs.l	1			; Scale value
vsyncFlag	rs.b	1			; VSync flag
bufferID	rs.b	1			; Buffer ID

vdpReg1		rs.w	1			; VDP register 1 cache

; -------------------------------------------------------------------------
; Main program
; -------------------------------------------------------------------------

Main:
	move.w	#$4EF9,vInterrupt.w		; Set up V-INT
	move.l	#VInt,vInterrupt+2.w

	lea	VDPCTRL,a0			; VDP control port
	move.w	#$8238,(a0)			; Plane A = $E000
	move.w	#$8B00,(a0)			; Scroll by screen
	move.w	#$8C00,(a0)			; H32 mode
	move.w	#$8114,vdpReg1			; Disable V-INT and screen
	move.w	vdpReg1,(a0)

	move.l	#$40000010,(a0)			; Scroll down
	move.l	#$00080008,-4(a0)

	DMA68K	GraphicPal,0,$20,CRAM,a0	; Load palette

	move.w	#$8F80,(a0)			; Stream tile data vertically
	moveq	#2-1,d4				; Number of tilemaps to draw
	move.l	#$60800003,d0			; VDP command
	moveq	#1,d1				; First tile

.Map:
	moveq	#BUFWIDTHTILE-1,d2		; Width of map in tiles

.Column:
	move.l	d0,(a0)				; Set VDP command
	moveq	#BUFHEIGHTTILE-1,d3		; Height of map in tiles

.Tile:
	move.w	d1,-4(a0)			; Write tile
	addq.w	#1,d1				; Next tile
	dbf	d3,.Tile			; Loop until column is drawn
	addi.l	#$20000,d0			; Next column
	dbf	d2,.Column			; Loop until map is drawn
	
	move.l	#$60C00003,d0			; VDP command
	dbf	d4,.Map				; Loop until both maps are drawn

	move.w	#4,scale			; Set scale value
	bra.s	.StartRender			; Start rendering

; -------------------------------------------------------------------------

.Loop:
	move	#$2000,sr			; Enable interrupts
	move.w	vdpReg1,d0			; Enable V-INT
	ori.b	#$20,d0
	move.w	d0,vdpReg1
	move.w	d0,VDPCTRL
	st	vsyncFlag			; Set VSync flag

.VSync:
	tst.b	vsyncFlag			; Are we synchronized?
	bne.s	.VSync				; If not, wait

	move.w	vdpReg1,d0			; Enable V-INT
	ori.b	#$40,d0
	move.w	d0,vdpReg1
	move.w	d0,VDPCTRL

	subi.l	#$800,scale			; Scale up

.StartRender:
	bsr.s	Render				; Render
	bra.s	.Loop				; Loop

; -------------------------------------------------------------------------
; Render
; -------------------------------------------------------------------------

Render:
	move	#$2700,sr			; Disable interrupts
	movea.l	sp,a6				; Save SP

	lea	bufferHigh,a0			; Clear buffers
	move.w	#(BUFSIZE*2)/32-1,d0
	moveq	#0,d1

.Clear:
	rept	32/4
		move.l	d1,(a0)+
	endr
	dbf	d0,.Clear

	moveq	#0,d0				; Clear d0
	moveq	#0,d7				; Clear d7

	lea	GraphicArt,a0			; Get graphic data
	move.w	(a0)+,d7			; Get width
	move.w	(a0)+,d0			; Get height
	movea.l	(a0)+,a1			; Get low nibble pixel data
	adda.l	a0,a1
	
	move.b	scale+1,-(sp)			; Get scale
	move.w	(sp)+,d2
	move.b	scale+2,d2
	tst.w	d2				; Is the scale 0?
	beq.w	.End				; If so, exit

	lsl.l	#8,d7				; Get number of columns to draw
	divu.w	d2,d7
	cmpi.w	#BUFWIDTH,d7			; Is it larger than the buffer width?
	bcs.s	.GotColumns			; If not, branch
	move.w	#BUFWIDTH,d7			; Cap at buffer width

.GotColumns:
	subq.w	#1,d7				; Subtract 1 for dbf
	bmi.w	.End				; If there are no columns to draw, exit

	lsl.l	#8,d0				; Get number of rows to draw
	divu.w	d2,d0
	cmpi.w	#BUFHEIGHT,d0			; Is it larger than the buffer height?
	bcs.s	.GotRows			; If not, branch
	move.w	#BUFHEIGHT,d0			; Cap at buffer height

.GotRows:
	subq.w	#1,d0				; Get number of extra rows
	bmi.w	.End				; If there are no rows to draw, exit

	lea	.ColumnDraws(pc),a2		; Get column draw routines
	lsl.w	#3,d0
	movea.l	(a2,d0.w),a3
	movea.l	4(a2,d0.w),a4

	lea	.Buffers(pc),a2			; Column buffers

	moveq	#0,d0				; Source X fraction
	moveq	#0,d1				; Source X integer

	move.w	scale+2,d2			; Scale fraction
	moveq	#0,d3				; Scale integer
	move.w	scale,d3

; -------------------------------------------------------------------------

.FirstColumn:
	moveq	#0,d4				; Source Y fraction
	movea.l	(a2),sp				; Get buffer

	move.l	a0,d5				; Draw first pixel
	add.l	(a0),d5
	movea.l	d5,a5
	move.b	(a5),(sp)+

	jmp	(a3)				; Draw rest of column

; -------------------------------------------------------------------------

.NextHighColumn:
	add.w	d2,d0				; Add X fraction part
	addx.w	d3,d1				; Add X integer part
	moveq	#0,d4				; Source Y fraction
	movea.l	(a2),sp				; Get buffer

	move.w	d1,d6				; Get column table offset
	add.w	d6,d6
	add.w	d6,d6

	move.l	a0,d5				; Draw first pixel
	add.l	(a0,d6.w),d5
	movea.l	d5,a5
	move.b	(a5),(sp)+

	jmp	(a3)				; Draw rest of column

.HighColumnDone:
	dbf	d7,.NextLowColumn		; Loop until all columns are drawn
	movea.l	a6,sp				; Restore SP

.End:
	rts

; -------------------------------------------------------------------------

.NextLowColumn:
	add.w	d2,d0				; Add X fraction part
	addx.w	d3,d1				; Add X integer part
	moveq	#0,d4				; Source Y fraction
	movea.l	(a2)+,sp			; Get buffer

	move.w	d1,d6				; Get column table offset
	add.w	d6,d6
	add.w	d6,d6

	move.l	a1,d5				; Draw first pixel
	add.l	(a1,d6.w),d5
	movea.l	d5,a5
	move.b	(a5),d6
	or.b	d6,(sp)+

	jmp	(a4)				; Draw rest of column

.LowColumnDone:
	dbf	d7,.NextHighColumn		; Loop until all columns are drawn
	movea.l	a6,sp				; Restore SP
	rts

; -------------------------------------------------------------------------

.Buffers:					; Column buffers
c	=	1
	rept	BUFWIDTH
		if ((c&7)<2)
			dc.l	bufferHigh+((c/8)*BUFHEIGHT*2)
		elseif ((c&7)<4)
			dc.l	bufferHigh+((c/8)*BUFHEIGHT*2)+1
		elseif ((c&7)<6)
			dc.l	bufferLow+((c/8)*BUFHEIGHT*2)
		else
			dc.l	bufferLow+((c/8)*BUFHEIGHT*2)+1
		endif
c		=	c+2
	endr

; -------------------------------------------------------------------------

.ColumnDraws:					; Column draw routines
	dc.l	.HighColumnDone
	dc.l	.LowColumnDone
c	=	2
	rept	BUFHEIGHT-1
		dc.l	.ColumnDraw\#c\_0
		dc.l	.ColumnDraw\#c\_1
c		=	c+1
	endr

; -------------------------------------------------------------------------

c	=	2
	rept	BUFHEIGHT-1
d	=	0
	rept	2
.ColumnDraw\#c\_\#d\:
	rept	c-1
		add.w	d2,d4			; Add Y fraction part
		addx.l	d3,d5			; Add Y integer part
		movea.l	d5,a5			; Get pixel
		if d=0
			move.b	(a5),(sp)+
		else
			move.b	(a5),d6
			or.b	d6,(sp)+
		endif
	endr
	
	if d=0					; Exit out
		jmp	.HighColumnDone
	else
		jmp	.LowColumnDone
	endif

d	=	d+1
	endr
c	=	c+1
	endr

; -------------------------------------------------------------------------
; Vertical interrupt
; -------------------------------------------------------------------------

VInt:
	move	#$2700,sr			; Disable interrupts
	PUSHA.L					; Push all registers
	
	lea	VDPCTRL,a0			; VDP control port
	move.w	(a0),d0				; Reset V-INT occurance flag
	clr.b	vsyncFlag			; Clear VSync flag

	move.w	vdpReg1,d0			; Disable V-INT
	andi.b	#~$20,d0
	move.w	d0,(a0)
	move.w	#$8F04,(a0)			; Set VDP auto increment to 4 (skip every other word)

	bchg	#0,bufferID			; Swap buffers
	bne.s	.Buffer2			; If we are using buffer 2, branch

.Buffer1:
	DMA68K	bufferHigh,$20,BUFSIZE,VRAM,a0
	DMA68K	bufferLow,$22,BUFSIZE,VRAM,a0
	move.w	#$8F02,(a0)			; Reset VDP auto increment back to 2
	move.l	#$7C000003,(a0)			; Show buffer 1
	move.l	#0,-4(a0)
	bra.s	.Done

.Buffer2:
	DMA68K	bufferHigh,$20+(BUFSIZE*2),BUFSIZE,VRAM,a0
	DMA68K	bufferLow,$22+(BUFSIZE*2),BUFSIZE,VRAM,a0
	move.w	#$8F02,(a0)			; Reset VDP auto increment back to 2
	move.l	#$7C000003,(a0)			; Show buffer 2
	move.l	#$01000100,-4(a0)

.Done:
	POPA.L					; Pop all registers
	rte

; -------------------------------------------------------------------------
; Data
; -------------------------------------------------------------------------

GraphicArt:
	incbin	"data/graphic.art.bin"
	even
GraphicPal:
	incbin	"data/graphic.pal.bin"
	even

; -------------------------------------------------------------------------
