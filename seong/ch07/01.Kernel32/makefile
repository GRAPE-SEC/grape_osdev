# set build env and rules

NASM32 = nasm
GCC32 = x86_64-pc-linux-gcc.exe -c -m32 -ffreestanding
LD32 = x86_64-pc-linux-ld.exe -melf_i386 -T ../elf_i386.x -nostdlib -e main -Ttext 0x10200
OBJCOPY32 = x86_64-pc-linux-objcopy.exe -j .text -j .data -j .rodata -j bss -S -O binary

OBJECTDIRECTORY = Temp
SOURCEDIRECTORY = Source

#build recipes

all: prepare Kernel32.bin

prepare:
	mkdir -p $(OBJECTDIRECTORY)

$(OBJECTDIRECTORY)/Entrypoint.bin: $(SOURCEDIRECTORY)/Entrypoint.s
	$(NASM32) -o $@ $<

dep:
	@echo === Make dependancy file ===
	make -C $(OBJECTDIRECTORY) -f ../makefile InternalDependency
	@echo == Dependancy search complete ===

ExecuteInternalBuild: dep
	make -C $(OBJECTDIRECTORY) -f ../makefile Kernel32.elf

$(OBJECTDIRECTORY)/Kernel32.elf.bin: ExecuteInternalBuild
	$(OBJCOPY32) $(OBJECTDIRECTORY)/Kernel32.elf $@

Kernel32.bin: $(OBJECTDIRECTORY)/Entrypoint.bin $(OBJECTDIRECTORY)/Kernel32.elf.bin
	cat $^ > $@

clean:
	rm -f *bin
	rm -f $(OBJECTDIRECTORY)/*.*

#calls for Temps directory

CENTRYPOINTOBJECTFILE = Main.o
CSOURCEFILES = $(wildcard ../$(SOURCEDIRECTORY)/*.c)
ASSEMBLYSOURCEFILES = $(wildcard ../$(SOURCEDIRECTORY)/*.asm)
COBJECTFILES = $(SUBST Main.o, , $(notdir $(patsubst %.c,%.o,$(CSOURCEFILES))))
ASSEMBLYOBJECTFILES = $(notdir $(patsubst %.asm,%.o,$(ASSEMBLYSOURCEFILES)))

#.c to .o
%.o: ../$(SOURCEDIRECTORY)/%.c
	$(GCC32) -c $<

#.asm to .o
%.o: ../$(SOURCEDIRECTORY)/%.asm
	$(NASM32) -f elf32 -o $@ $<

InternalDependency:
	$(GCC32) -MM $(CSOURCEFILES) > Dependancy.dep

Kernel32.elf: $(CENTRYPOINTOBJECTFILE) $(COBJECTFILES) $(ASSEMBLYOBJECTFILES)
	$(LD32) -o $@ $^

ifeq (Dependancy.dep, $(wildcard Dependancy.dep))
include Dependancy.dep
endif