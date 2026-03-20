`default_nettype none

module pipe_reg #(
    parameter int WIDTH = 32
) (
    input  logic             clk,
    input  logic             rst_n,

    input  logic             s_valid,
    output logic             s_ready,
    input  logic [WIDTH-1:0] s_data,

    output logic             m_valid,
    input  logic             m_ready,
    output logic [WIDTH-1:0] m_data
);

    logic [WIDTH-1:0] data_q;
    logic             full;

    assign m_valid = full;
    assign m_data  = data_q;
    assign s_ready = !full || (m_valid && m_ready);

    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            full   <= 1'b0;
            data_q <= '0;
        end
        else
        begin
            if (s_valid && s_ready && !(m_valid && m_ready))
            begin
                data_q <= s_data;
                full   <= 1'b1;
            end
            else if (m_valid && m_ready && !(s_valid && s_ready))
            begin
                full <= 1'b0;
            end
            else if (s_valid && s_ready && m_valid && m_ready)
            begin
                data_q <= s_data;
            end
        end
    end

endmodule

`default_nettype wire
