; 64tass --ascii --case-sensitive --nostart --list=myrom.list -Wall myrom.asm -o myrom.bin
.cpu  'w65c02'
.enc  'none'

    VERA_BASE           = $9F20
    VERA_ADDR_L         = VERA_BASE + $0000
    VERA_ADDR_M         = VERA_BASE + $0001
    VERA_ADDR_H         = VERA_BASE + $0002
    VERA_DATA0          = VERA_BASE + $0003
    VERA_DATA1          = VERA_BASE + $0004
    VERA_CTRL           = VERA_BASE + $0005
    VERA_IEN            = VERA_BASE + $0006
    VERA_ISR            = VERA_BASE + $0007
    VERA_IRQ_LINE_L     = VERA_BASE + $0008
    VERA_DC_VIDEO       = VERA_BASE + $0009
    VERA_DC_HSCALE      = VERA_BASE + $000A
    VERA_DC_VSCALE      = VERA_BASE + $000B
    VERA_DC_BORDER      = VERA_BASE + $000C
    VERA_DC_HSTART      = VERA_BASE + $0009
    VERA_DC_HSTOP       = VERA_BASE + $000A
    VERA_DC_VSTART      = VERA_BASE + $000B
    VERA_DC_VSTOP       = VERA_BASE + $000C
    VERA_L0_CONFIG      = VERA_BASE + $000D
    VERA_L0_MAPBASE     = VERA_BASE + $000E
    VERA_L0_TILEBASE    = VERA_BASE + $000F
    VERA_L0_HSCROLL_L   = VERA_BASE + $0010
    VERA_L0_HSCROLL_H   = VERA_BASE + $0011
    VERA_L0_VSCROLL_L   = VERA_BASE + $0012
    VERA_L0_VSCROLL_H   = VERA_BASE + $0013
    VERA_L1_CONFIG      = VERA_BASE + $0014
    VERA_L1_MAPBASE     = VERA_BASE + $0015
    VERA_L1_TILEBASE    = VERA_BASE + $0016
    VERA_L1_HSCROLL_L   = VERA_BASE + $0017
    VERA_L1_HSCROLL_H   = VERA_BASE + $0018
    VERA_L1_VSCROLL_L   = VERA_BASE + $0019
    VERA_L1_VSCROLL_H   = VERA_BASE + $001A
    VERA_AUDIO_CTRL     = VERA_BASE + $001B
    VERA_AUDIO_RATE     = VERA_BASE + $001C
    VERA_AUDIO_DATA     = VERA_BASE + $001D
    VERA_SPI_DATA       = VERA_BASE + $001E
    VERA_SPI_CTRL       = VERA_BASE + $001F
    VERA_PSG_BASE       = $1F9C0
    VERA_PALETTE_BASE   = $1FA00
    VERA_SPRITES_BASE   = $1FC00
    TILE_BASE           = $1F000

    ZP_PTR = $02        ; a pointer variable in zeropage
    
* = $c000

reset_handler:  .proc
        jsr  init_vera
        jmp  program_loop
        .endproc
        
init_vera:  .proc
        lda  #%10000000
        sta  VERA_CTRL          ; reset VERA
        stz  VERA_IEN           ; disable all IRQs
        jsr  copy_charset
        jsr  clear_tilemap
        jsr  setup_layers
        jmp  init_default_displaymode
        
copy_charset:        
        ; copy 256 characters of 8 bytes each into vram
        stz  VERA_CTRL
        lda  #(`TILE_BASE) | %00010000 
        sta  VERA_ADDR_H
        lda  #>TILE_BASE
        sta  VERA_ADDR_M
        lda  #<TILE_BASE
        sta  VERA_ADDR_L
        lda  #<chargen
        ldy  #>chargen
        sta  ZP_PTR
        sty  ZP_PTR+1
        ldx  #0
-       ldy  #8
-       lda  (ZP_PTR)
        sta  VERA_DATA0
        inc  ZP_PTR
        bne  +
        inc  ZP_PTR+1
+       dey
        bne  -
        dex
        bne  --
        rts

clear_tilemap:
        ; clear tile map, 64x64 entries + their attribute
        stz  VERA_CTRL
        lda  #%00010000
        sta  VERA_ADDR_H
        stz  VERA_ADDR_M
        stz  VERA_ADDR_L
        lda  #0
        ldy  #64
-       ldx  #64
-       sta  VERA_DATA0
        sta  VERA_DATA0
        ina
        dex
        bne -
        dey
        bne --
        rts

setup_layers:        
        lda  #%00010000
        sta  VERA_DC_VIDEO      ; enable layer 0
        lda  #64
        sta  VERA_DC_HSCALE     ; lores
        sta  VERA_DC_VSCALE     ; lores
        lda  #%01010000
        sta  VERA_L0_CONFIG     ; 64x64 tile map, 1 bpp
        stz  VERA_L0_MAPBASE    ; map at $0:0000
        lda  #TILE_BASE>>9 | %00000000      ; 8x8 tiles
        sta  VERA_L0_TILEBASE
        rts

init_default_displaymode:
        lda  VERA_DC_VIDEO
        and  #$f0
        ora  #$01
        sta  VERA_DC_VIDEO      ; VGA output mode
        rts
        
        .endproc

        
program_loop:   .proc
        jmp  program_loop
        .endproc
        

irq_handlers: .block
nmi_handler:
        ply
        plx
        pla
        rti

irq_handler:
        ply
        plx
        pla
        rti
        .endblock

chargen:    .block
        .binary "chargen.bin",0,256*8
        .endblock
        

* = $FFFA
NMI_VEC		.addr	irq_handlers.nmi_handler
RESET_VEC	.addr	reset_handler
IRQ_VEC		.addr	irq_handlers.irq_handler
