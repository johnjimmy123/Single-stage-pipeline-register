`timescale 1ns/1ps
module pipe_reg_tb;

    localparam int width   = 32;
    localparam int clk_hlf = 5;

    logic             clk, rst_n;
    logic             in_valid, in_ready;
    logic [width-1:0] in_data;
    logic             out_valid, out_ready;
    logic [width-1:0] out_data;

    pipe_reg #(.width(width)) dut (
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
    always  #clk_hlf clk = ~clk;

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

    task send(input logic [width-1:0] d);
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
        reset_dut();

        send(32'hA5A5_0042);
        out_ready <= 1'b1;
        @(posedge clk);
        @(posedge clk);
        if (out_data === 32'hA5A5_0042)
            $display("TC1 - basic write and read : PASS");
        else
            $display("TC1 - basic write and read : FAIL");
        out_ready <= 1'b0;

        reset_dut();

        send(32'hDEAD_BEEF);
        out_ready <= 1'b0;
        repeat(4) @(posedge clk);
        if (out_valid && out_data === 32'hDEAD_BEEF)
            $display("TC2 - backpressure passed");
        else
            $display("TC2 - backpressure failed");
        out_ready <= 1'b1;
        @(posedge clk);
        out_ready <= 1'b0;

        reset_dut();

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
            $display("TC3 - simultaneous push and pop : PASS");
        else
            $display("TC3 - simultaneous push and pop : FAIL");
        out_ready <= 1'b0;

        reset_dut();

        send(32'hFFFF_FFFF);
        rst_n <= 1'b0;
        @(posedge clk);
        rst_n <= 1'b1;
        @(posedge clk);
        if (!out_valid && out_data === '0)
            $display("TC4 - reset while full : PASS");
        else
            $display("TC4 - reset while full : FAIL");

        repeat(4) @(posedge clk);
        $display("done");
        $finish;
    end

endmodule


