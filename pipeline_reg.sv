`default_nettype none

module pipe_reg #(
    parameter int width = 32
) (
    input  logic             clk,
    input  logic             rst_n,

    input  logic             in_valid,
    output logic             in_ready,
    input  logic [width-1:0] in_data,

    output logic             out_valid,
    input  logic             out_ready,
    output logic [width-1:0] out_data
);

    logic [width-1:0] data_q;
    logic             full;

    assign out_valid = full;
    assign in_ready  = !full || (out_valid && out_ready);

    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            full   <= 1'b0;
            data_q <= '0;
        end
        else
        begin
            if (in_valid && in_ready && !(out_valid && out_ready))
            begin
                data_q <= in_data;
                full   <= 1'b1;
            end
            else if (out_valid && out_ready && !(in_valid && in_ready))
            begin
                out_data <= data_q;
                full <= 1'b0;
            end
            else if (in_valid && in_ready && out_valid && out_ready)
            begin
                data_q <= in_data;
            end
        end
    end

endmodule

`default_nettype wire
