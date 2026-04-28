module TopModule
(
    input  logic       clk,
    input  logic       reset,
    input  logic       in_valid,
    input  logic       in_a,
    input  logic       in_b,
    input  logic       in_mode,
    output logic       out_valid,
    output logic       out_y,
    output logic       out_tag
);

    always @(posedge clk) begin
        if (reset) begin
            out_valid <= 0;
            out_y <= 0;
            out_tag <= 0;
        end else if (in_valid) begin
            out_valid <= 1;
            case (in_mode)
                1'b0: out_y <= in_a & in_b;  // AND operation
                1'b1: out_y <= in_a | in_b;  // OR operation
                default: out_y <= 0;  // Default case to handle unexpected modes
            endcase
            out_tag <= in_mode;  // Just forwarding the mode as tag
        end else begin
            out_valid <= 0;
            out_y <= 0;  // Ensure out_y is reset when in_valid is not asserted
        end
    end

endmodule