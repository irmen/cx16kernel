.PHONY:  all clean emu

all:  mykernal.bin

clean:
	rm -f *.vice-* *.bin

emu:  mykernal.bin
	x16emu -randram -sdcard ~/cx16sdcard.img -scale 2 -quality best -rom $<

mykernal.bin: src/mykernal.asm
	64tass --ascii --case-sensitive --nostart --list=myrom.list -Wall -o $@ $<

