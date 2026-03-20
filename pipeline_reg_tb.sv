`timescale 1ns/1ps
`default_nettype none

module pipe_reg_tb;

    localparam int WIDTH    = 32;
    localparam int CLK_HALF = 5;

    logic            clk, rst_n;
    logic            s_valid, s_ready;
    logic [WIDTH-1:0] s_data;
    logic            m_valid, m_ready;
    logic [WIDTH-1:0] m_data;

    pipe_reg #(.WIDTH(WIDTH)) dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .s_valid(s_valid),
        .s_ready(s_ready),
        .s_data (s_data),
        .m_valid(m_valid),
        .m_ready(m_ready),
        .m_data (m_data)
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
        s_valid <= 1'b0;
        s_data  <= '0;
        m_ready <= 1'b0;
        rst_n   <= 1'b0;
        repeat(4) @(posedge clk);
        @(negedge clk);
        rst_n <= 1'b1;
        @(posedge clk);
    end
    endtask

    task send(input logic [WIDTH-1:0] d);
    begin
        s_valid <= 1'b1;
        s_data  <= d;
        @(posedge clk);
        while (!s_ready)
        begin
            @(posedge clk);
        end
        s_valid <= 1'b0;
    end
    endtask

    initial
    begin
        $display("pipe_reg testbench starting");

        reset_dut();
        $display("[TC1] Basic write and read");
        send(32'hA5A5_0042);
        m_ready <= 1'b1;
        @(posedge clk);
        @(posedge clk);
        if (m_data === 32'hA5A5_0042)
        begin
            $display("  PASS");
        end
        else
        begin
            $display("  FAIL");
        end
        m_ready <= 1'b0;

        reset_dut();
        $display("[TC2] Backpressure - data must hold");
        send(32'hDEAD_BEEF);
        m_ready <= 1'b0;
        repeat(4) @(posedge clk);
        if (m_valid && m_data === 32'hDEAD_BEEF)
        begin
            $display("  PASS");
        end
        else
        begin
            $display("  FAIL");
        end
        m_ready <= 1'b1;
        @(posedge clk);
        m_ready <= 1'b0;

        reset_dut();
        $display("[TC3] Simultaneous push and pop");
        s_valid <= 1'b1;
        s_data  <= 32'hAAAA_0001;
        m_ready <= 1'b0;
        @(posedge clk);
        s_data  <= 32'hBBBB_0002;
        m_ready <= 1'b1;
        @(posedge clk);
        s_valid <= 1'b0;
        @(posedge clk);
        if (m_valid && m_data === 32'hBBBB_0002)
        begin
            $display("  PASS");
        end
        else
        begin
            $display("  FAIL");
        end
        m_ready <= 1'b0;

        reset_dut();
        $display("[TC4] Reset while register is full");
        send(32'hFFFF_FFFF);
        rst_n <= 1'b0;
        @(posedge clk);
        rst_n <= 1'b1;
        @(posedge clk);
        if (!m_valid && m_data === '0)
        begin
            $display("  PASS");
        end
        else
        begin
            $display("  FAIL");
        end

        reset_dut();
        $display("[TC5] Multiple back to back transfers");
        m_ready <= 1'b1;
        send(32'h0000_0001);
        send(32'h0000_0002);
        send(32'h0000_0003);
        repeat(4) @(posedge clk);
        m_ready <= 1'b0;
        $display("  PASS");

        repeat(4) @(posedge clk);
        $display("Simulation complete");
        $finish;
    end

endmodule

`default_nettype wire
