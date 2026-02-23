# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotbext.uart import UartSource, UartSink

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())

    TEST_VALUE = 0xA
    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 1<<6

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    # Set input pins high
    dut.ui_in.value = TEST_VALUE << 4
    dut._log.info("Test project behavior")
    uart_sink = UartSink(dut.uart_tx, baud=9600, bits=8)

    await ClockCycles(dut.clk, 10000) 
    assert dut.uo_out.value[7:4] == TEST_VALUE, f"Expected uio_out to be {TEST_VALUE}, got {dut.uio_out.value}"
    
    rx_data = bytearray()
    while (len(rx_data) < len("Hello, World!")):
        rx_data.extend(await uart_sink.read())
    assert rx_data == b"Hello, World!", f"Expected UART output to be 'Hello, World!', got {rx_data.decode()}"

    uart_source = UartSource(dut.uart_rx, baud=9600, bits=8)
    txData = b"TEST"
    await uart_source.write(txData)
    rx_data = bytearray()
    while (len(rx_data) < len(txData)):
        rx_data.extend(await uart_sink.read())

    assert rx_data == txData, f"Expected UART input to be {txData}, got {rx_data}"
    dut._log.info("End")
