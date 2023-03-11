; 64tass --ascii --case-sensitive --nostart --list=myrom.list -Wall myrom.asm -o myrom.bin
.cpu  'w65c02'
.enc  'screen'

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
	

	.section ZeroPageVars
	zp_ptr		.addr ?		; a pointer variable in zeropage
	zp_byte		.byte ?		; general byte var
	zp_word		.word ?		; general word var
	textcolor	.byte ?		; text foreground color and background color
	screenwidth	.byte ?
	screenheight	.byte ?
	vsync_cnt_hi	.byte ?
	vsync_cnt_mi	.byte ?
	vsync_cnt_lo	.byte ?
	.send
	
	.section KernalVariables
	CPUIRQV		.addr ?
	CPUNMIV		.addr ?
	CPUBRKV		.addr ?
	VSYNCIRQV	.addr ?
	AFLOWIRQV	.addr ?
	LINEIRQV	.addr ?
	SPRITEIRQV	.addr ?
	; no variables here yet, if zeropage spills over put them here
	.endsection
    
* = $0080
	.dsection ZeroPageVars
	.cerror *>$ff, "ZeroPageVars too large"
* = $0200
	.dsection KernalVariables
	.cerror *>$03ff, "KernalVariables too large"
	
* = $c000
	.dsection Kernal
	.dsection CharSet
	.dsection ShellProgramPlaceholder
	.cerror *>$fffa, "Kernal rom too large"
* = $fffa
	.dsection CpuVectors
	.cerror *>$ffff, "CpuVectors too large"
	
DEFAULT_TEXT_COLOR = $bd	; light green on dark grey

	.section Kernal
cpu_reset_handler:  .proc
	ldx  #$ff
	txs			; reset stack pointer to top of stack
	cld
	jsr  clear_critical_ram
	; jsr  init_io		; TODO initialize other I/O things?
	jsr  init_audio
	jsr  init_video	
	jsr  init_irqs
	jsr  show_bootmessage
	cli			; enable interrupts
	jmp  shell_entrypoint
	.endproc

clear_critical_ram:  .proc
	ldy  #0
	lda  #0
_1	sta  $00,y		; clear ZP (and select ram bank 0)
	sta  $00fe,y		; clear cpu stack
	sta  $0200,y		; clear Variables
	sta  $0300,y		; clear Variables
	dey
	bne  _1
	rts
	.endproc
	
init_audio:  .proc
	; TODO silence all audio output
	rts		
	.endproc
	
	
show_bootmessage:  .proc
	; TODO use a print routine
	stz  VERA.CTRL
	lda  #%00010000
	sta  VERA.ADDR_H
	stz  VERA.ADDR_M
	stz  VERA.ADDR_L	
	ldx  textcolor
	ldy  #0
_lp	lda  message,y
	beq  _done
	sta  VERA.DATA0
	stx  VERA.DATA0
	iny
	bne  _lp
_done	rts	
	
message:
	.text "*** custom kernal rom initialized! ***",0
	.pend

init_video:  .proc
	lda  #%10000000
	sta  VERA.CTRL		; reset VERA
	stz  VERA.IEN		; disable all IRQs
	jsr  copy_charset
	lda  #DEFAULT_TEXT_COLOR
	sta  textcolor
	jsr  clear_tilemap
	jsr  setup_layers
	jmp  init_default_displaymode
	
copy_charset:	
	; copy 256 characters of 8 bytes each into vram
	TILE_BASE = $1F000
	stz  VERA.CTRL
	lda  #(`TILE_BASE) | %00010000 
	sta  VERA.ADDR_H
	lda  #>TILE_BASE
	sta  VERA.ADDR_M
	lda  #<TILE_BASE
	sta  VERA.ADDR_L
	lda  #<charset
	ldy  #>charset
	sta  zp_ptr
	sty  zp_ptr+1
	ldx  #0
_1	ldy  #8
_2	lda  (zp_ptr)
	sta  VERA.DATA0
	inc  zp_ptr
	bne  _3
	inc  zp_ptr+1
_3	dey
	bne  _2
	dex
	bne  _1
	rts

clear_tilemap:
	; clear tile map, 128x64 entries + their attribute
	; this covers 80x60 and 40x30 screens
	stz  VERA.CTRL
	lda  #%00010000
	sta  VERA.ADDR_H
	stz  VERA.ADDR_M
	stz  VERA.ADDR_L
	lda  #DEFAULT_TEXT_COLOR
	sta  textcolor
	lda  #' '
	ldy  #64
_1      ldx  #128
_2      sta  VERA.DATA0
	pha
	lda  textcolor
	sta  VERA.DATA0
	pla
	dex
	bne  _2
	dey
	bne  _1
	rts

setup_layers:	
	lda  #%00010000
	sta  VERA.DC_VIDEO      ; enable layer 0
	lda  #64
	sta  VERA.DC_HSCALE     ; lores
	sta  VERA.DC_VSCALE     ; lores
	lda  #%01010000
	sta  VERA.L0_CONFIG     ; 64x64 tile map, 1 bpp
	stz  VERA.L0_MAPBASE    ; map at $0:0000
	lda  #TILE_BASE>>9 | %00000000      ; 8x8 tiles
	sta  VERA.L0_TILEBASE
	lda  #40
	sta  screenwidth
	lda  #30
	sta  screenheight
	rts


init_default_displaymode:
	lda  VERA.DC_VIDEO
	and  #$f0
	ora  #$01
	sta  VERA.DC_VIDEO      ; VGA output mode hardcoded for now
	rts
	
	.endproc

init_irqs:  .proc
	jsr  init_irq_vectors
	lda  #%00000001
	sta  VERA.IEN		; enable vsync IRQ
	rts
	.endproc
	
cpu_nmi_handler:
	pha
	phx
	phy
	jmp  (CPUNMIV)
	ply
	plx
	pla
	rti

cpu_irq_handler:
	pha
	phx
	phy
	tsx
	lda  $0104,x
	and  #$10		; check break flag
	bne  _brk
	jmp  (CPUIRQV)
_brk
	jmp  (CPUBRKV)
	
	
brk_handler:
	; TODO
	bra  return_from_irq
	
nmi_handler:
	; TODO
	bra  return_from_irq
	
vsync_handler:
	inc  vsync_cnt_lo
	bne  _done
	inc  vsync_cnt_mi
	bne  _done
	inc  vsync_cnt_hi
_done	bra  return_from_irq
	
irq_handler:
	lda  VERA.ISR
	sta  zp_byte
	and  #%00001000
	bne  _not_aflow
	lda  #%00001000
	sta  VERA.ISR
	jmp  (AFLOWIRQV)
_not_aflow	
	lda  zp_byte
	and  #%00000010
	beq  _not_line
	lda  #%00000010
	sta  VERA.ISR
	jmp  (LINEIRQV)
_not_line
	lda  zp_byte
	and  #%00000100
	beq  _not_sprcol
	lda  #%00000100
	sta  VERA.ISR
	jmp  (SPRITEIRQV)
_not_sprcol
	lda  zp_byte
	and  #%00000001
	beq  _not_vsync
	lda  #%00000001
	sta  VERA.ISR
	jmp  (VSYNCIRQV)
_not_vsync
	; fall through
return_from_irq:
	ply
	plx
	pla
	rti

default_vsync_handler:
	rts
	
init_irq_vectors:	
	lda  #<irq_handler
	ldy  #>irq_handler
	sta  CPUIRQV
	sty  CPUIRQV+1
	lda  #<brk_handler
	ldy  #>brk_handler
	sta  CPUBRKV
	sty  CPUBRKV+1
	lda  #<nmi_handler
	ldy  #>nmi_handler
	sta  CPUNMIV
	sty  CPUNMIV+1
	lda  #<vsync_handler
	ldy  #>vsync_handler
	sta  VSYNCIRQV
	sty  VSYNCIRQV+1
	lda  #<return_from_irq
	ldy  #>return_from_irq
	sta  LINEIRQV
	sty  LINEIRQV+1
	sta  AFLOWIRQV
	sty  AFLOWIRQV+1
	sta  SPRITEIRQV
	sty  SPRITEIRQV+1	
	rts

	.endsection Kernal
	
	.section CharSet
charset:
	.binary "charset.bin",0,256*8          	; only the first 256 characters
	.endsection
	
	.section ShellProgramPlaceholder
shell_entrypoint:	
	; TODO use a print routine
	stz  VERA.CTRL
	lda  #%00100000
	sta  VERA.ADDR_H
	stz  VERA.ADDR_M
	lda  #64*2
	sta  VERA.ADDR_L	
	ldy  #0
_lp	lda  message,y
	beq  _done
	sta  VERA.DATA0
	iny
	bne  _lp
_done	wai
	bra  _done
	
message:
	.text "this line is from a the shell routine",0
	.endsection
	
	
	.section CpuVectors
NMI_VEC		.addr	cpu_nmi_handler
RESET_VEC	.addr	cpu_reset_handler
IRQ_VEC		.addr	cpu_irq_handler
	.endsection 
	
