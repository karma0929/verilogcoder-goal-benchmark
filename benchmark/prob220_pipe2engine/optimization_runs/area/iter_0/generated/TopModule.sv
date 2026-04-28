module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic in_valid,
    input  logic [31:0] in_a,
    input  logic [31:0] in_b,
    input  logic [1:0] in_mode,
    output logic out_valid,
    output logic [31:0] out_y,
    output logic [3:0] out_tag
);

    // Wires to connect modules
    logic [1:0] state_next;

    // Instantiate the control FSM
    control_fsm fsm (
        .clk(clk),
        .reset(reset),
        .in_valid(in_valid),
        .in_a(in_a),
        .in_b(in_b),
        .in_mode(in_mode),
        .state_next(state_next),
        .out_valid(out_valid),
        .out_y(out_y),
        .out_tag(out_tag)
    );

endmodule
