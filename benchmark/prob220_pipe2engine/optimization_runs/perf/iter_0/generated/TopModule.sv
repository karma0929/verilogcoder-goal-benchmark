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
