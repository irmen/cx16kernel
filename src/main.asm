.cpu  'w65c02'
.enc  'screen'

.include "kernel.asm"
.include "shell.asm"


* = $0080
	; zeropage variables from $80 - $ff
	.dsection ZeroPage
	.cerror *>$ff, "ZeroPage too large"

* = $0200
	; kernel vectors and variables from $200 - $3ff
	.dsection KernelVariables
	.cerror *>$03ff, "KernelVariables too large"
	
* = $c000
	; the actual kernel rom $c000 - $fff9
	.dsection Kernel
	.dsection CharSet
	.dsection UserShell
	.cerror *>$fff9, "Kernel rom too large"

* = $fffa
	; the three hardware CPU vectors $fffa - $ffff
	.dsection CpuVectors
	.cerror *>$ffff, "CpuVectors too large"
	
