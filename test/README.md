# Testbench for tt_um_ECM24_serv_soc_top

## Running the cocotb test (test.py)

This project uses a cocotb-based testbench in `test.py` (discovered as the `test` module by the Makefile) to run simulations of the top-level design via the wrapper in `tb.v`.

The test currently:

- Resets the design and enables the core
- The program is loaded into the on-chip SRAM model
- Drives a test value on the upper nibble of `ui_in`
- Checks that the same value appears on the upper nibble of `uo_out` after a number of clock cycles

### Test environment setup

From the `test` directory:

```sh
cd test

# (optional but recommended) create and activate a virtual environment
python3 -m venv .venv
source .venv/bin/activate

# install Python dependencies for the testbench
pip install -r requirements.txt
```

You also need a supported Verilog simulator (the default Makefile configuration uses Icarus Verilog: `iverilog` / `vvp`).

### Running the tests

From the `test` directory, run an RTL simulation (this will execute `test_project` in `test.py`):

```sh
make -B
```

To run a gate-level simulation instead (after hardening and copying your gate-level netlist to `test/gate_level_netlist.v`):

```sh
make -B GATES=yes
```

Waveforms are written to `tb.fst` by default.


If you wish to save the waveform in VCD format instead of FST format, edit tb.v to use `$dumpfile("tb.vcd");` and then run:

```sh
make -B FST=
```

This will generate `tb.vcd` instead of `tb.fst`.

## How to view the waveform file

Using GTKWave

```sh
gtkwave tb.fst tb.gtkw
```

Using Surfer

```sh
surfer tb.fst
```
