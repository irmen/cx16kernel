
; The operating system Kernel.

.cpu  'w65c02'
.enc  'screen'

.include "veradefs.asm"

DEFAULT_TEXT_COLOR = $bd	; light green on dark grey
CURSOR_BLINK_SPEED = 10


	.section ZeroPage
	zp_ptr		.addr ?		; general purpos pointer variable in zeropage
	zp_byte		.byte ?		; general purpose byte var
	zp_word		.word ?		; general purpose word var
	textcolor	.byte ?		; text foreground color and background color
	screenwidth	.byte ?
	screenheight	.byte ?
	cursorx		.byte ?
	cursory		.byte ?
	cursorenabled	.byte ?
	cursorblinkst	.byte ?
	cursorblinkspd	.byte ?
	vsync_cnt_hi	.byte ?
	vsync_cnt_mi	.byte ?
	vsync_cnt_lo	.byte ?
	.endsection
	
	.section KernelVariables
	CPUIRQV		.addr ?
	CPUNMIV		.addr ?
	CPUBRKV		.addr ?
	VSYNCIRQV	.addr ?
	AFLOWIRQV	.addr ?
	LINEIRQV	.addr ?
	SPRITEIRQV	.addr ?
	.endsection
    

	.section Kernel
cpu_reset_handler:
	; this gets called when the system boots or does a software reset
	; it (re)initializes everything to a sane state,
	; sets up the interrupt handlers,
	; prints a welcome message on the screen, 
	; and then jumps into the main shell routine.	
	ldx  #$ff
	txs			; reset stack pointer to top of stack
	cld
	jsr  clear_critical_ram
	; jsr  init_io		; TODO initialize other I/O things?
	jsr  init_audio
	jsr  init_video	
	jsr  init_various
	jsr  init_irqs
	jsr  show_bootmessage
	cli			; enable interrupts
	lda  #1
	sta  cursorenabled
	jmp  shell_entrypoint

clear_critical_ram:
	ldy  #0
	lda  #0
_1	sta  $00,y		; clear ZP (and select ram bank 0)
	sta  $00fe,y		; clear cpu stack
	sta  $0200,y		; clear Variables
	sta  $0300,y		; clear Variables
	dey
	bne  _1
	rts
	
init_audio:
	; TODO silence all audio output
	rts		
	
init_various:
	; initialize various other things
	lda  #CURSOR_BLINK_SPEED
	sta  cursorblinkspd
	lda  #1
	sta  cursorblinkst
	stz  cursorenabled
	rts
	
show_bootmessage:
	lda  #<_message1
	ldy  #>_message1
	jsr  printz
	jsr  print_newline
	lda  #<_message2
	ldy  #>_message2
	jsr  printz
	jmp  print_newline
	
_message1	.text "*** custom kernel rom initialized! ***",0
_message2	.text "this is the kernel boot message.",0
	
printz:
	sta  zp_ptr
	sty  zp_ptr+1
	ldy  #0
_1	lda  (zp_ptr),y
	beq  _done
	jsr  print_char
	iny
	bne  _1
_done	rts

print_char:
	phy
	pha
	ldy  cursory
	lda  cursorx
	asl  a
	sta  zp_byte
	stz  VERA.CTRL
	stz  VERA.ADDR_H
	clc
	lda  _times128_lo,y
	adc  zp_byte
	sta  VERA.ADDR_L
	lda  _times128_hi,y
	adc  #0
	sta  VERA.ADDR_M
	pla
	sta  VERA.DATA0
	ply
	inc  cursorx
	lda  cursorx
	cmp  screenwidth
	bne  _done
	jsr  print_newline
_done	rts
	
_ := 128*range(60)
_times128_lo:
	.byte <_
_times128_hi:
	.byte >_
	
print_newline:
	stz  cursorx
	inc  cursory
	lda  cursory
	cmp  screenheight
	bne  _done
	; TODO scroll screen up
	stz  cursory	; for now we jump back to the top
_done	rts
	

init_video:
	lda  #%10000000
	sta  VERA.CTRL		; reset VERA
	stz  VERA.IEN		; disable all IRQs
	jsr  set_palette_16
	jsr  copy_charset
	lda  #DEFAULT_TEXT_COLOR
	sta  textcolor
	jsr  clear_tilemap
	jsr  setup_layers
	jmp  init_default_displaymode
	
set_palette_16:
	; tweak the first 16 colors of the color palette a little
	stz  VERA.CTRL
	lda  #(`VERA.PALETTE_BASE) | %00010000
	sta  VERA.ADDR_H
	lda  #>VERA.PALETTE_BASE
	sta  VERA.ADDR_M
	lda  #<VERA.PALETTE_BASE
	sta  VERA.ADDR_L
	ldy  #0
_lp	lda  _c64_pepto,y
	sta  VERA.DATA0
	iny
	lda  _c64_pepto,y
	sta  VERA.DATA0
	iny
	cpy  #32
	bne  _lp
	rts

_c64_pepto
	; # this is Pepto's Commodore-64 palette  http://www.pepto.de/projects/colorvic/
        .word $000  ; 0 = black
        .word $FFF  ; 1 = white
        .word $833  ; 2 = red
        .word $7cc  ; 3 = cyan
        .word $839  ; 4 = purple
        .word $5a4  ; 5 = green
        .word $229  ; 6 = blue
        .word $ef7  ; 7 = yellow
        .word $852  ; 8 = orange
        .word $530  ; 9 = brown
        .word $c67  ; 10 = light red
        .word $123  ; 11 = dark grey  --- but tweaked to be dark navy blue
        .word $777  ; 12 = medium grey
        .word $af9  ; 13 = light green
        .word $76e  ; 14 = light blue
        .word $bbb  ; 15 = light grey
	
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
	sta  VERA.DC_VIDEO		; enable layer 0
	lda  #64
	sta  VERA.DC_HSCALE		; lores
	sta  VERA.DC_VSCALE		; lores
	lda  #%01010000
	sta  VERA.L0_CONFIG		; 64x64 tile map, 1 bpp
	stz  VERA.L0_MAPBASE    	; map at $0:0000
	lda  #TILE_BASE>>9 | %00000000	; 8x8 tiles
	sta  VERA.L0_TILEBASE
	lda  #40
	sta  screenwidth
	lda  #30
	sta  screenheight
	stz  cursorx
	stz  cursory
	rts

init_default_displaymode:
	lda  VERA.DC_VIDEO
	and  #$f0
	ora  #$01
	sta  VERA.DC_VIDEO	; VGA output mode hardcoded for now
	rts
	
	
init_irqs:
	jsr  init_irq_vectors
	lda  #%00000001
	sta  VERA.IEN		; enable vsync IRQ
	rts
	
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
	tay
	and  #%00001000
	bne  _not_aflow
	lda  #%00001000
	sta  VERA.ISR
	jmp  (AFLOWIRQV)
_not_aflow	
	tya
	and  #%00000010
	beq  _not_line
	lda  #%00000010
	sta  VERA.ISR
	jmp  (LINEIRQV)
_not_line
	tya
	and  #%00000100
	beq  _not_sprcol
	lda  #%00000100
	sta  VERA.ISR
	jmp  (SPRITEIRQV)
_not_sprcol
	tya
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

	.endsection Kernel
	
	.section CharSet
charset:
	.binary "charset.bin",0,256*8          	; only the first 256 characters
	.endsection
	
	
	.section CpuVectors
NMI_VEC		.addr	cpu_nmi_handler
RESET_VEC	.addr	cpu_reset_handler
IRQ_VEC		.addr	cpu_irq_handler
	.endsection 
	
