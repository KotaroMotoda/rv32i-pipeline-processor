CROSS_COMPILE=riscv64-linux-gnu-
#CROSS_COMPILE=/opt/riscv/bin/riscv32-unknown-elf-
CC     = $(CROSS_COMPILE)gcc
AS     = $(CROSS_COMPILE)as
LD     = $(CROSS_COMPILE)ld
OBJCOPY= $(CROSS_COMPILE)objcopy
OBJDUMP= $(CROSS_COMPILE)objdump

CFLAGS  = -g -march=rv32i -mabi=ilp32 -ffreestanding -nostdlib -fno-builtin
ASFLAGS = -g --gstabs+ -march=rv32i -mabi=ilp32
LDFLAGS = -m elf32lriscv_ilp32 --no-relax -Bstatic -T link.ld -nostdlib
OBJS	= startup.o sort.o

all: sort.mif sort.verilog sort.lst

sort.mif: sort.verilog
	./vlogdump2mif.py sort.verilog -s

sort.verilog: sort.elf
	$(OBJCOPY) -O verilog  $< $@

sort.lst: sort.elf
	$(OBJDUMP) -D $< > $@

sort.elf: $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

clean:
	$(RM) -rf *.verilog *.mif *.elf *.o *~
