module TopModule(
    input logic clk,
    input logic reset,
    input logic in_valid,
    input logic [31:0] in_a,
    input logic [31:0] in_b,
    input logic [1:0] in_mode,
    output logic out_valid,
    output logic [31:0] out_y,
    output logic [1:0] out_tag
);
    logic [1:0] state;

    control_fsm fsm(
        .clk(clk),
        .reset(reset),
        .in(in_valid),
        .state_next(state),
        .state(state)
    );

    compute_core core(
        .clk(clk),
        .reset(reset),
        .state(state),
        .in_a(in_a),
        .in_b(in_b),
        .in_mode(in_mode),
        .out_valid(out_valid),
        .out_y(out_y),
        .out_tag(out_tag)
    );
endmodule

module control_fsm (
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic [1:0] state_next,
    input  logic [1:0] state
);

    // State definitions
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;

    // Combinational logic for next state determination
    always @(*) begin
        case (state)
            STATE_A: state_next = in ? STATE_B : STATE_A;
            STATE_B: state_next = in ? STATE_C : STATE_A;
            STATE_C: state_next = in ? STATE_C : STATE_A;
        endcase
    end

endmodule

module compute_core(
    input logic clk,
    input logic reset,
    input logic [1:0] state,
    input logic [31:0] in_a,
    input logic [31:0] in_b,
    input logic [1:0] in_mode,
    output logic out_valid,
    output logic [31:0] out_y,
    output logic [1:0] out_tag
);
    always @(posedge clk) begin
        if (reset) begin
            out_y <= 0;
            out_valid <= 0;
            out_tag <= 0;
        end else begin
            case (in_mode)
                2'b00: out_y <= in_a + in_b;
                2'b01: out_y <= in_a - in_b;
                2'b10: out_y <= in_a & in_b;
                2'b11: out_y <= in_a | in_b;
            endcase
            out_valid <= 1;
            out_tag <= in_mode;
        end
    end
endmodule
