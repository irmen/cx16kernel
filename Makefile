.PHONY:  all clean emu

all:  kernel.bin

clean:
	rm -f *.vice-* *.bin *.list

emu:  kernel.bin
	PULSE_LATENCY_MSEC=20 x16emu -randram -sdcard ~/cx16sdcard.img -scale 2 -quality best -rom $<

kernel.bin: src/main.asm src/kernel.asm src/veradefs.asm src/shell.asm src/charset.bin
	64tass --ascii --case-sensitive --nostart --list=kernel.list -Wall --no-monitor -o $@ $<

