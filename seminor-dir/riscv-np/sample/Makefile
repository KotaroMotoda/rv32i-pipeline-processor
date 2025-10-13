CROSS_COMPILE=/staff/kuga/Share/riscv/bin/riscv32-unknown-elf-
#CROSS_COMPILE=/opt/riscv/bin/riscv32-unknown-elf-
CC     = $(CROSS_COMPILE)gcc
AS     = $(CROSS_COMPILE)as
LD     = $(CROSS_COMPILE)ld
OBJCOPY= $(CROSS_COMPILE)objcopy
OBJDUMP= $(CROSS_COMPILE)objdump

CFLAGS  = -O -march=rv32e -mabi=ilp32e -ffreestanding 
ASFLAGS = --gstabs+ -march=rv32e -mabi=ilp32e
LDFLAGS = -nostartfiles --no-relax -Bstatic -T link.ld -nostdlib
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
