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

module compute_core (
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

    // Local parameters for state definition
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;

    // State register
    logic [1:0] state;
    logic [1:0] state_next;

    // Sequential logic to handle state transitions
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_A;
        end else begin
            state <= state_next;
        end
    end

    // Combinational logic for next state logic
    always @(*) begin
        case (state)
            STATE_A: state_next = in_valid ? STATE_B : STATE_A;
            STATE_B: state_next = in_valid ? STATE_C : STATE_A;
            STATE_C: state_next = in_valid ? STATE_C : STATE_A;
        endcase
    end

    // Combinational logic for output
    always @(*) begin
        out_valid = (state == STATE_C);
    end

endmodule

module control_fsm (
    input  logic clk,
    input  logic reset,
    input  logic in_valid,
    input  logic [31:0] in_a,
    input  logic [31:0] in_b,
    input  logic [1:0] in_mode,
    output logic [1:0] state_next,
    output logic out_valid,
    output logic [31:0] out_y,
    output logic [3:0] out_tag
);

    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;

    logic [1:0] state;

    // Initialization and reset
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= STATE_A;
            out_valid <= 1'b0;
            out_y <= 32'b0;
            out_tag <= 4'b0;
        end else begin
            state <= state_next;
        end
    end

    // Combinational logic for next state and output
    always @(*) begin
        case (state)
            STATE_A: begin
                state_next = in_valid ? STATE_B : STATE_A;
                out_valid = 1'b0;
                out_y = 32'b0;  // Ensure defined output
                out_tag = 4'b0; // Ensure defined output
            end
            STATE_B: begin
                state_next = in_valid ? STATE_C : STATE_A;
                out_valid = 1'b0;
                out_y = 32'b0;  // Ensure defined output
                out_tag = 4'b0; // Ensure defined output
            end
            STATE_C: begin
                state_next = in_valid ? STATE_C : STATE_A;
                out_valid = 1'b1;
                out_y = in_a + in_b; // Example computation
                out_tag = in_mode;  // Example tag assignment
            end
            default: begin
                state_next = STATE_A;
                out_valid = 1'b0;
                out_y = 32'b0;
                out_tag = 4'b0;
            end
        endcase
    end

endmodule
