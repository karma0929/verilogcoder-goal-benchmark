module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic in_valid,
    input  logic [7:0] in_a,
    input  logic [7:0] in_b,
    input  logic [2:0] in_mode,
    output logic out_valid,
    output logic [7:0] out_y,
    output logic [3:0] out_tag
);

    // Instantiation of compute_core
    compute_core core (
        .clk(clk),
        .reset(reset),
        .in_a(in_a),
        .in_b(in_b),
        .in_mode(in_mode),
        .out_y(out_y)
    );

    // Instantiation of control_fsm
    control_fsm fsm (
        .clk(clk),
        .reset(reset),
        .in_valid(in_valid),
        .in_mode(in_mode),
        .out_valid(out_valid),
        .out_tag(out_tag)
    );

endmodule

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

module control_fsm (
    input  logic       clk,
    input  logic       reset,
    input  logic in_valid,
    input  logic [2:0] in_mode,
    output logic out_valid,
    output logic [3:0] out_tag
);

    // Corrected FSM logic to control output validity and tag based on mode
    always @(*) begin
        out_valid = in_valid;  // Pass through validity
        out_tag = {1'b0, in_mode};  // Corrected to ensure 4-bit tag
    end

endmodule