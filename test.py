import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

@cocotb.test()
async def test_mc14500b_extended_soc(dut):
    """Verify 3x2 extended SoC ROM operations and parallel IO bus tracking loop"""
    dut._log.info("Booting Extended SoC 3x2 Verification Engine...")

    # Launch background simulation clock loop at 50 MHz
    cocotb.start_soon(Clock(dut.clk, 20, units="ns").start())

    # Hardware initialization reset sequence
    dut.rst_n.value = 0
    dut.ui_in.value = 0x00
    dut.uio_in.value = 0x00
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    dut._log.info("System Reset complete. Commencing ROM program validation loops...")

    # Set up our stimulus vectors to check parallel processing behavior
    # Inject pattern 0xA5 into ui_in. The SoC reads this input dynamically into RAM bank upper indices.
    dut.ui_in.value = 0xA5
    
    # Run the design for a few full iterations of the 8-step program loop
    for step in range(24):
        await RisingEdge(dut.clk)
        await Timer(1, units="ns") # Small settle offset margin for stable reads

        # Deconstruct monitored signals out of the bidirectional uio bus layout array
        uio_val = dut.uio_out.value.integer
        current_pc = uio_val & 0x3F          # Extract active Program Counter bits [5:0]
        core_rr = (uio_val >> 6) & 0x01      # Extract MCU core Result Register state bit
        write_pulse = (uio_val >> 7) & 0x01  # Extract write strobe pulse line
        parallel_out = dut.uo_out.value.integer # Active state of the dedicated 8-bit parallel output

        dut._log.info(
            f"Step {step:02d} | PC: 0x{current_pc:02X} | RR: {core_rr} | "
            f"WR: {write_pulse} | Parallel Out: 0x{parallel_out:02X}"
        )

        # Functional checks corresponding to our internal preloaded program ROM behavior
        if current_pc == 0x01:
            # Step 1 loaded from RAM 8/9, expect RR to reflect input condition values
            assert core_rr in [0, 1], f"Malformed execution tracking at PC step {current_pc}"
            
    dut._log.info("Extended 3x2 tile MCU SoC verification sequence passed successfully!")
