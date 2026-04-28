module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic in_valid,
    input  logic in_a,
    input  logic in_b,
    input  logic in_mode,
    output logic out_valid,
    output logic out_y,
    output logic out_tag
);

    logic enable_computation;

    // Instance of control_fsm
    control_fsm fsm (
        .clk(clk),
        .reset(reset),
        .in_valid(in_valid),
        .enable_computation(enable_computation)
    );

    // Instance of compute_core
    compute_core core (
        .clk(clk),
        .reset(reset),
        .in_valid(in_valid),
        .in_a(in_a),
        .in_b(in_b),
        .in_mode(in_mode),
        .enable_computation(enable_computation),
        .out_valid(out_valid),
        .out_y(out_y),
        .out_tag(out_tag)
    );

endmodule

module compute_core (
    input  logic clk,
    input  logic reset,
    input  logic in_valid,
    input  logic in_a,
    input  logic in_b,
    input  logic in_mode,
    input  logic enable_computation,
    output logic out_valid,
    output logic out_y,
    output logic out_tag
);

    // Internal signals
    logic [1:0] state;
    logic [1:0] next_state;

    // State definitions
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;

    // State transition logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_A;
        end else if (in_valid && enable_computation) begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        if (enable_computation) begin
            case (state)
                STATE_A: next_state = in_a ? STATE_B : STATE_A;
                STATE_B: next_state = in_b ? STATE_C : STATE_A;
                STATE_C: next_state = in_mode ? STATE_C : STATE_A;
                default: next_state = STATE_A;
            endcase
        end else begin
            next_state = state; // Hold state when computation is not enabled
        end
    end

    // Output logic
    always @(*) begin
        out_valid = (state == STATE_C) && enable_computation;
        out_y = (state == STATE_B) && enable_computation;
        out_tag = (state == STATE_A) && enable_computation;
    end

endmodule

module control_fsm (
    input  logic clk,
    input  logic reset,
    input  logic in_valid,
    output logic enable_computation
);

    // State definitions
    localparam IDLE = 1'b0;
    localparam ACTIVE = 1'b1;

    // State register
    logic state;
    logic next_state;

    // State transition logic
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = in_valid ? ACTIVE : IDLE;
            ACTIVE: next_state = in_valid ? ACTIVE : IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Output logic
    assign enable_computation = (state == ACTIVE);

endmodule