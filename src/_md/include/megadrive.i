; -------------------------------------------------------------------------
; Mega Drive Engine
; By Ralakimus 2021
; -------------------------------------------------------------------------
; Mega Drive definitions and macros
; -------------------------------------------------------------------------

; -------------------------------------------------------------------------
; Addresses
; -------------------------------------------------------------------------

; ROM
CARTROM		EQU	$000000			; Cartridge ROM start
CARTROME	EQU	$400000			; Cartridge ROM end
CARTROMS	EQU	CARTROME-CARTROM	; Cartridge ROM size

; Expansion
EXPANSION	EQU	$400000			; Expansion memory start
EXPANSIONE	EQU	$800000			; Expansion memory end
EXPANDS		EQU	EXPANSIONE-EXPANSION	; Expansion memory size

; Z80
Z80RAM		EQU	$A00000			; Z80 RAM start
Z80RAME		EQU	$A02000			; Z80 RAM end
Z80RAMS		EQU	Z80RAME-Z80RAM		; Z80 RAM size
Z80BUS		EQU	$A11100			; Z80 bus request
Z80RESET	EQU	$A11200			; Z80 reset

; Work RAM
WORKRAM		EQU	$FFFF0000		; Work RAM start
WORKRAME	EQU	$00000000		; Work RAM end
WORKRAMS	EQU	WORKRAME-WORKRAM	; Work RAM size

; External RAM
	if (EXTRAMS<>0)&(EXTRAMS<5)
		inform 3,"External RAM size is too small. It needs to be at least 5 bytes."
	endif
EXTRAM		EQU	CARTROM+$200001		; External RAM start
EXTRAME		EQU	EXTRAM+(EXTRAMS*2)	; External RAM end
EXTRAMON	EQU	$A130F1			; External RAM enable port

; Sound
YMADDR0		EQU	$A04000			; YM2612 address port 0
YMDATA0		EQU	$A04001			; YM2612 data port 0
YMADDR1		EQU	$A04002			; YM2612 address port 1
YMDATA1		EQU	$A04003			; YM2612 data port 1
PSGCTRL		EQU	$C00011			; PSG control port

; VDP
VDPDATA		EQU	$C00000			; VDP data port
VDPCTRL		EQU	$C00004			; VDP control port
VDPHVCNT	EQU	$C00008			; VDP H/V counter
VDPDEBUG	EQU	$C0001C			; VDP debug register

; I/O
VERSION		EQU	$A10001			; Hardware version
IODATA1		EQU	$A10003			; I/O port 1 data port
IODATA2		EQU	$A10005			; I/O port 2 data port
IODATA3		EQU	$A10007			; I/O port 3 data port
IOCTRL1		EQU	$A10009			; I/O port 1 control port
IOCTRL2		EQU	$A1000B			; I/O port 2 control port
IOCTRL3		EQU	$A1000D			; I/O port 3 control port

; TMSS
TMSSSEGA	EQU	$A14000			; TMSS "SEGA" register
TMSSMODE	EQU	$A14100			; TMSS bus mode

; -------------------------------------------------------------------------
; Constants
; -------------------------------------------------------------------------

PALLNCOLORS	EQU	$10			; Colors per palette line
PALLINES	EQU	4			; Number of palette lines
VSCRLCNT	EQU	$14			; Number of vertial scroll entries
HSCRLCNT	EQU	$E0			; Number of horizontal scroll entries
SPRITECNT	EQU	$50			; Nunber of sprites

; -------------------------------------------------------------------------
; Palette line structure
; -------------------------------------------------------------------------

	rsreset
	RSRPT.W	palCol, PALLNCOLORS, 1		; Palette entries
PALLINESZ	rs.b	0			; Structure size

; -------------------------------------------------------------------------
; Palette structure
; -------------------------------------------------------------------------

	rsreset
	RSRPT.B	palLn, PALLINES, PALLINESZ	; Palette lines
PALETTESZ	rs.b	0			; Structure size

; -------------------------------------------------------------------------
; Scroll entry structure
; -------------------------------------------------------------------------

	rsreset
scrlFG		rs.w	1			; Foreground entry
scrlBG		rs.w	1			; Background entry
SCRLENTRYSZ	rs.b	0			; Structure size

; -------------------------------------------------------------------------
; Vertical scroll structure
; -------------------------------------------------------------------------

	rsreset
	RSRPT.B	vscrl, VSCRLCNT, SCRLENTRYSZ	; Scroll entries
VSCROLLSZ	rs.b	0			; Structure size

; -------------------------------------------------------------------------
; Horizontal scroll structure
; -------------------------------------------------------------------------

	rsreset
	RSRPT.B	hscrl, HSCRLCNT, SCRLENTRYSZ	; Scroll entries
HSCROLLSZ	rs.b	0			; Structure size

; -------------------------------------------------------------------------
; Sprite table entry structure
; -------------------------------------------------------------------------

	rsreset
sprY		rs.w	1			; Y position
sprSize		rs.b	1			; Sprite size
sprLink		rs.b	1			; Link data
sprTile		rs.w	1			; Tile attributes
sprX		rs.w	1			; X position
SPRENTRYSZ	rs.b	0			; Structure size

; -------------------------------------------------------------------------
; Sprite table structure
; -------------------------------------------------------------------------

	rsreset
	RSRPT.B	spr, SPRITECNT, SPRENTRYSZ	; Sprite entries
SPRTABLESZ	rs.b	0			; Structure size

; -------------------------------------------------------------------------
; YM2612 register bank structure
; -------------------------------------------------------------------------
	
	rsreset
ymAddr		rs.b	1			; Address
ymData		rs.b	1			; Data
YMREGSZ		rs.b	0			; Structure size

; -------------------------------------------------------------------------
; Request Z80 bus access
; -------------------------------------------------------------------------

Z80REQ macros
	move.w	#$100,Z80BUS			; Request Z80 bus access

; -------------------------------------------------------------------------
; Wait for Z80 bus request acknowledgement
; -------------------------------------------------------------------------

Z80WAIT macro
.Wait\@:
	btst	#0,Z80BUS			; Was the request acknowledged?
	bne.s	.Wait\@				; If not, wait
	endm

; -------------------------------------------------------------------------
; Request Z80 bus access
; -------------------------------------------------------------------------

Z80STOP macro
	Z80REQ					; Request Z80 bus access
	Z80WAIT					; Wait for acknowledgement
	endm

; -------------------------------------------------------------------------
; Release the Z80 bus
; -------------------------------------------------------------------------

Z80START macros
	move.w	#0,Z80BUS			; Release the bus

; -------------------------------------------------------------------------
; Request Z80 reset
; -------------------------------------------------------------------------

Z80RESON macros
	move.w	#0,Z80RESET			; Request Z80 reset

; -------------------------------------------------------------------------
; Cancel Z80 reset
; -------------------------------------------------------------------------

Z80RESOFF macros
	move.w	#$100,Z80RESET			; Cancel Z80 reset

; -------------------------------------------------------------------------
; Wait for DMA to finish
; -------------------------------------------------------------------------
; PARAMETERS:
;	ctrl - (OPTIONAL) VDP control port address register
; -------------------------------------------------------------------------

DMAWAIT macro ctrl
.Wait\@:
	if narg>0
		move.w	(\ctrl),ccr		; Is DMA active?
	else
		move.w	VDPCTRL,ccr		; Is DMA active?
	endif
	bvs.s	.Wait\@				; If so, wait
	endm

; -------------------------------------------------------------------------
; VDP command instruction
; -------------------------------------------------------------------------
; PARAMETERS:
;	addr - Address in VDP memory
;	type - Type of VDP memory
;	rwd  - VDP command
;	end  - Destination, or modifier if end2 is defined
;	end2 - Destination if defined
; -------------------------------------------------------------------------

VRAMWRITE	EQU	$40000000		; VRAM write
CRAMWRITE	EQU	$C0000000		; CRAM write
VSRAMWRITE	EQU	$40000010		; VSRAM write
VRAMREAD	EQU	$00000000		; VRAM read
CRAMREAD	EQU	$00000020		; CRAM read
VSRAMREAD	EQU	$00000010		; VSRAM read
VRAMDMA		EQU	VRAMWRITE|$80		; VRAM DMA
CRAMDMA		EQU	CRAMWRITE|$80		; CRAM DMA
VSRAMDMA	EQU	VSRAMWRITE|$80		; VSRAM DMA

; -------------------------------------------------------------------------

VDPCMD macro ins, addr, type, rwd, end, end2
	local	cmd
cmd	= (\type\\rwd\)|(((\addr)&$3FFF)<<16)|((\addr)/$4000)
	if narg=5
		\ins	#\#cmd,\end
	elseif narg>=6
		\ins	#(\#cmd)\end,\end2
	else
		\ins	cmd
	endif
	endm

; -------------------------------------------------------------------------
; VDP DMA from 68000 memory to VDP memory
; -------------------------------------------------------------------------
; PARAMETERS:
;	src  - Source address in 68000 memory
;	dest - Destination address in VDP memory
;	len  - Length of data in bytes
;	type - Type of VDP memory
;	ctrl - (OPTIONAL) VDP control port address register
; -------------------------------------------------------------------------

DMA68K macro src, dest, len, type, ctrl
	if narg>4
		move.l	#$94009300|((((\len)/2)&$FF00)<<8)|(((\len)/2)&$FF),(\ctrl)
		move.l	#$96009500|((((\src)/2)&$FF00)<<8)|(((\src)/2)&$FF),(\ctrl)
		move.w	#$9700|(((\src)>>17)&$7F),(\ctrl)
		VDPCMD	move.w,\dest,\type,DMA,>>16,(\ctrl)
		VDPCMD	move.w,\dest,\type,DMA,&$FFFF,-(sp)
		move.w	(sp)+,(\ctrl)
	else
		move.l	#$94009300|((((\len)/2)&$FF00)<<8)|(((\len)/2)&$FF),VDPCTRL
		move.l	#$96009500|((((\src)/2)&$FF00)<<8)|(((\src)/2)&$FF),VDPCTRL
		move.w	#$9700|(((\src)>>17)&$7F),VDPCTRL
		VDPCMD	move.w,\dest,\type,DMA,>>16,VDPCTRL
		VDPCMD	move.w,\dest,\type,DMA,&$FFFF,-(sp)
		move.w	(sp)+,VDPCTRL
	endif
	endm

; -------------------------------------------------------------------------
; VDP DMA fill VRAM with byte
; Auto-increment should be set to 1 beforehand.
; -------------------------------------------------------------------------
; PARAMETERS:
;	byte - Byte to fill VRAM with
;	addr - Address in VRAM
;	len  - Length of fill in bytes
;	ctrl - (OPTIONAL) VDP control port address register
; -------------------------------------------------------------------------

DMAFILL macro byte, addr, len, ctrl
	if narg>3
		move.l	#$94009300|((((\len)-1)&$FF00)<<8)|(((\len)-1)&$FF),(\ctrl)
		move.w	#$9780,(\ctrl)
		move.l	#$40000080|(((\addr)&$3FFF)<<16)|(((\addr)&$C000)>>14),(\ctrl)
		move.w	#(\byte)<<8,-4(\ctrl)
		DMAWAIT	\ctrl
	else
		move.l	#$94009300|((((\len)-1)&$FF00)<<8)|(((\len)-1)&$FF),VDPCTRL
		move.w	#$9780,VDPCTRL
		move.l	#$40000080|(((\addr)&$3FFF)<<16)|(((\addr)&$C000)>>14),VDPCTRL
		move.w	#(\byte)<<8,VDPDATA
		DMAWAIT
	endif
	endm

; -------------------------------------------------------------------------
; VDP DMA copy region of VRAM to another location in VRAM
; Auto-increment should be set to 1 beforehand.
; -------------------------------------------------------------------------
; PARAMETERS:
;	src  - Source address in VRAM
;	dest - Destination address in VRAM
;	len  - Length of copy in bytes
;	ctrl - (OPTIONAL) VDP control port address register
; -------------------------------------------------------------------------

DMACOPY macro src, dest, len, ctrl
	if narg>3
		move.l	#$94009300|((((\len)-1)&$FF00)<<8)|(((\len)-1)&$FF),(\ctrl)
		move.l	#$96009500|(((\src)&$FF00)<<8)|((\src)&$FF),(\ctrl)
		move.w	#$97C0,(\ctrl)
		move.l	#$0000C0|(((\dest)&$3FFF)<<16)|(((\dest)&$C000)>>14),(\ctrl)
		DMAWAIT	\ctrl
	else
		move.l	#$94009300|((((\len)-1)&$FF00)<<8)|(((\len)-1)&$FF),VDPCTRL
		move.l	#$96009500|(((\src)&$FF00)<<8)|((\src)&$FF),VDPCTRL
		move.w	#$97C0,VDPCTRL
		move.l	#$0000C0|(((\dest)&$3FFF)<<16)|(((\dest)&$C000)>>14),VDPCTRL
		DMAWAIT
	endif
	endm

; -------------------------------------------------------------------------
