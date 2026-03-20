# pipe_reg — Single-Stage Pipeline Register

A single-stage pipeline register implemented in synthesisable SystemVerilog using a standard valid/ready handshake. The module decouples an upstream producer from a downstream consumer and handles backpressure without data loss or duplication.

## Interface

```
upstream           pipe_reg             downstream
producer  ──────►  [ data_q / full ]  ──────►  consumer
          s_valid                       m_valid
          s_ready ◄──────────────────── m_ready
          s_data                        m_data
```

| Port | Direction | Description |
|------|-----------|-------------|
| clk | input | Clock |
| rst_n | input | Asynchronous active-low reset |
| s_valid | input | Upstream data valid |
| s_ready | output | Module ready to accept data |
| s_data | input | Upstream data bus |
| m_valid | output | Downstream data valid |
| m_ready | input | Downstream ready to accept |
| m_data | output | Downstream data bus |

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| WIDTH | 32 | Data bus width in bits |

## Handshake Rule

A transfer occurs when **valid AND ready are both high on the same rising clock edge**. This is the standard AXI-Stream handshake protocol.

`s_ready` is asserted when the register is empty or when the downstream is consuming data in the same cycle — this ensures full throughput with no bubble cycles.

## Files

| File | Description |
|------|-------------|
| `pipe_reg.sv` | RTL source — fully synthesisable |
| `pipe_reg_tb.sv` | Testbench with 5 directed test cases and waveform dump |

## Test Cases

| # | Test | Description |
|---|------|-------------|
| TC1 | Basic write and read | Single data word written and read back |
| TC2 | Backpressure | m_ready held low — data must remain stable |
| TC3 | Simultaneous push and pop | Upstream and downstream transfer in same cycle |
| TC4 | Reset while full | Register clears cleanly on reset |
| TC5 | Back to back transfers | Multiple consecutive writes with downstream always ready |

## Simulation

```bash
iverilog -g2012 -o sim pipe_reg.sv pipe_reg_tb.sv
vvp sim
gtkwave pipe_reg_waves.vcd
```

Expected output:
```
pipe_reg testbench starting
[TC1] Basic write and read
  PASS
[TC2] Backpressure - data must hold
  PASS
[TC3] Simultaneous push and pop
  PASS
[TC4] Reset while register is full
  PASS
[TC5] Multiple back to back transfers
  PASS
Simulation complete
```

## Waveform

After simulation, open `pipe_reg_waves.vcd` in GTKWave and add the following signals:

```
clk
rst_n
s_valid
s_ready
s_data
m_valid
m_ready
m_data
```
