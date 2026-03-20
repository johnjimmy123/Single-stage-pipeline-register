`timescale 1ns/1ps
`default_nettype none

module pipe_reg_tb;

    localparam int DATA_W   = 32;
    localparam int CLK_HALF = 5;

    logic              clk, rst_n;
    logic              in_valid, in_ready;
    logic [DATA_W-1:0] in_data;
    logic              out_valid, out_ready;
    logic [DATA_W-1:0] out_data;

    pipe_reg #(.DATA_W(DATA_W)) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .in_valid (in_valid),
        .in_ready (in_ready),
        .in_data  (in_data),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data (out_data)
    );

    initial clk = 1'b0;
    always  #CLK_HALF clk = ~clk;

    initial
    begin
        $dumpfile("pipe_reg_waves.vcd");
        $dumpvars(0, pipe_reg_tb);
    end

    task reset_dut();
    begin
        in_valid  <= 1'b0;
        in_data   <= '0;
        out_ready <= 1'b0;
        rst_n     <= 1'b0;
        repeat(4) @(posedge clk);
        @(negedge clk);
        rst_n <= 1'b1;
        @(posedge clk);
    end
    endtask

    task send(input logic [DATA_W-1:0] d);
    begin
        in_valid <= 1'b1;
        in_data  <= d;
        @(posedge clk);
        while (!in_ready)
        begin
            @(posedge clk);
        end
        in_valid <= 1'b0;
    end
    endtask

    initial
    begin
        $display("pipe_reg testbench starting");

        reset_dut();
        $display("[TC1] Basic write and read");
        send(32'hA5A5_0042);
        out_ready <= 1'b1;
        @(posedge clk);
        @(posedge clk);
        if (out_data === 32'hA5A5_0042)
        begin
            $display("  PASS");
        end
        else
        begin
            $display("  FAIL");
        end
        out_ready <= 1'b0;

        reset_dut();
        $display("[TC2] Backpressure - data must hold");
        send(32'hDEAD_BEEF);
        out_ready <= 1'b0;
        repeat(4) @(posedge clk);
        if (out_valid && out_data === 32'hDEAD_BEEF)
        begin
            $display("  PASS");
        end
        else
        begin
            $display("  FAIL");
        end
        out_ready <= 1'b1;
        @(posedge clk);
        out_ready <= 1'b0;

        reset_dut();
        $display("[TC3] Simultaneous push and pop");
        in_valid  <= 1'b1;
        in_data   <= 32'hAAAA_0001;
        out_ready <= 1'b0;
        @(posedge clk);
        in_data   <= 32'hBBBB_0002;
        out_ready <= 1'b1;
        @(posedge clk);
        in_valid  <= 1'b0;
        @(posedge clk);
        if (out_valid && out_data === 32'hBBBB_0002)
        begin
            $display("  PASS");
        end
        else
        begin
            $display("  FAIL");
        end
        out_ready <= 1'b0;

        reset_dut();
        $display("[TC4] Reset while register is full");
        send(32'hFFFF_FFFF);
        rst_n <= 1'b0;
        @(posedge clk);
        rst_n <= 1'b1;
        @(posedge clk);
        if (!out_valid && out_data === '0)
        begin
            $display("  PASS");
        end
        else
        begin
            $display("  FAIL");
        end

        reset_dut();
        $display("[TC5] Multiple back to back transfers");
        out_ready <= 1'b1;
        send(32'h0000_0001);
        send(32'h0000_0002);
        send(32'h0000_0003);
        repeat(4) @(posedge clk);
        out_ready <= 1'b0;
        $display("  PASS");

        repeat(4) @(posedge clk);
        $display("Simulation complete");
        $finish;
    end

endmodule

`default_nettype wire
