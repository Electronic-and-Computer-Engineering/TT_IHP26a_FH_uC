# Toolchain for SerV-Core

Toolchain and helper scripts to build software for the SerV-Core RISC-V core.

## Usage

Build custom source files with `make SRC=my_custom_file.c`.

All output files except the .hex file for Simulation will be placed in the `build/` folder.

## Helper Scripts

`makehex.py` - Convert ELF files to HEX format and saves it as .hex file. This file can be loaded into the Simulation, as shown in `test/tb.sv`.


`hex_to_c_array.py` - Convert HEX files to C arrays. This can be used to program the external SRAM using `misc\spi_memory\Arduino\SRAM_RW.ino`.

## Setup

The toolchain was tested using Ubuntu 20.04 in WSL:

```bash
sudo apt install gcc-riscv64-unknown-elf
```

