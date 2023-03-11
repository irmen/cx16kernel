
; Commander X16 VERA chip registers

	.virtual $9f20
VERA	.block
	ADDR_L		.byte ?
	ADDR_M		.byte ?
	ADDR_H		.byte ?
	DATA0		.byte ?
	DATA1		.byte ?
	CTRL		.byte ?
	IEN		.byte ?
	ISR		.byte ?
	IRQ_LINE_L	.byte ?
	DC_VIDEO	.byte ?
	DC_HSCALE	.byte ?
	DC_VSCALE	.byte ?
	DC_BORDER	.byte ?
	DC_HSTART	= DC_VIDEO
	DC_HSTOP	= DC_HSCALE
	DC_VSTART	= DC_VSCALE
	DC_VSTOP	= DC_BORDER
	L0_CONFIG	.byte ?
	L0_MAPBASE	.byte ?
	L0_TILEBASE	.byte ?
	L0_HSCROLL_L	.byte ?
	L0_HSCROLL_H	.byte ?
	L0_VSCROLL_L	.byte ?
	L0_VSCROLL_H	.byte ?
	L1_CONFIG	.byte ?
	L1_MAPBASE	.byte ?
	L1_TILEBASE	.byte ?
	L1_HSCROLL_L	.byte ?
	L1_HSCROLL_H	.byte ?
	L1_VSCROLL_L	.byte ?
	L1_VSCROLL_H	.byte ?
	AUDIO_CTRL	.byte ?
	AUDIO_RATE	.byte ?
	AUDIO_DATA	.byte ?
	SPI_DATA	.byte ?
	SPI_CTRL	.byte ?
	
	PSG_BASE	= $1F9C0
	PALETTE_BASE	= $1FA00
	SPRITES_BASE	= $1FC00
	.bend
	.endvirtual
