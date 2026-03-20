# pipe_reg — Single-Stage Pipeline Register

A single-stage pipeline register implemented in synthesisable SystemVerilog with a valid/ready handshake. It sits between an upstream producer and a downstream consumer, storing one data word and handling backpressure without data loss or duplication.

## How it works

The module has one internal register (`data_q`) and a single status bit (`full`). When the register is empty it accepts data from the input side. When it holds data it presents it to the output side. If the output side is not ready, the input side is stalled until space is available.

The key line is:
```systemverilog
assign in_ready = !full || (out_valid && out_ready);
```
This means the module is ready to accept new data either when it is empty, or when the downstream is consuming the current data in the same cycle. This avoids wasting a clock cycle and allows full throughput of one transfer per cycle.

## Handshake rule

A transfer happens on any interface only when both valid and ready are high on the same rising clock edge. This is the standard valid/ready protocol used in AXI-Stream interfaces.

## Reset

The reset is asynchronous and active-low. On reset the register is cleared and out_valid goes low immediately without waiting for a clock edge.

## Files

- `pipe_reg.sv` — RTL source
- `pipe_reg_tb.sv` — Testbench
- `simulation.png` — Waveform output

## Parameters

- `width` — data bus width in bits (default 32)

## Ports

- `clk` — clock
- `rst_n` — asynchronous active-low reset
- `in_valid`, `in_ready`, `in_data` — input interface
- `out_valid`, `out_ready`, `out_data` — output interface

## Test cases

- TC1 — basic write and read
- TC2 — backpressure, data held stable when output not ready
- TC3 — simultaneous push and pop in the same clock cycle
- TC4 — reset asserted while register is full

## Simulation

```bash
iverilog -g2012 -o sim pipe_reg.sv pipe_reg_tb.sv
vvp sim
gtkwave pipe_reg_waves.vcd
```

Expected output:
```
TC1 - basic write and read : PASS
TC2 - backpressure passed
TC3 - simultaneous push and pop : PASS
TC4 - reset while full : PASS
done
```

## Waveform

Open `pipe_reg_waves.vcd` in GTKWave after simulation. Add signals `clk`, `rst_n`, `in_valid`, `in_ready`, `in_data`, `out_valid`, `out_ready`, `out_data` to see the full handshake behaviour across all test cases.
