# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 1, unit="us")
    cocotb.start_soon(clock.start())

    TEST_VALUE = 0xA
    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Set input pins high
    dut.ui_in.value = TEST_VALUE << 4
    dut._log.info("Test project behavior")


    await ClockCycles(dut.clk, 1000) 
    assert dut.uo_out.value[7:4] == TEST_VALUE, f"Expected uio_out to be {TEST_VALUE}, got {dut.uio_out.value}"
    assert True
