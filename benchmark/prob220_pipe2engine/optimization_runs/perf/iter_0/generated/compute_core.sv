module compute_core (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] in_a,
    input  logic [7:0] in_b,
    input  logic [2:0] in_mode,
    output logic [7:0] out_y
);

    // Corrected combinational logic to process inputs based on mode
    always @(*) begin
        case (in_mode)
            0: out_y = in_a + in_b;  // Addition
            1: out_y = in_a - in_b;  // Subtraction
            2: out_y = in_a & in_b;  // Bitwise AND
            3: out_y = in_a | in_b;  // Bitwise OR
            default: out_y = 0;      // Default case to handle unexpected modes
        endcase
    end

endmodule
