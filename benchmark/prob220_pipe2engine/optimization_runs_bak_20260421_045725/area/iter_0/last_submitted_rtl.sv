module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic in,
    input  logic in_valid,
    input  logic in_a,
    input  logic in_b,
    input  logic in_mode,
    output logic out,
    output logic out_valid,
    output logic out_y,
    output logic out_tag
);
    logic [1:0] state_next;
    logic core_out;
    logic [7:0] result_y;
    logic result_tag;

    // Instantiate the control FSM
    control_fsm fsm (
        .clk(clk),
        .reset(reset),
        .in(in),
        .state_next(state_next)
    );

    // Instantiate the compute core
    compute_core core (
        .clk(clk),
        .reset(reset),
        .in(in),
        .out(core_out),
        .state_next(state_next)
    );

    // Logic to calculate out_y based on state
    always_comb begin
        case (state_next)
            2'b00: result_y = in_a;
            2'b01: result_y = in_b;
            2'b10: result_y = in_a + in_b;
            default: result_y = 0;
        endcase
    end

    // Logic to calculate out_tag based on state
    always_comb begin
        case (state_next)
            2'b00: result_tag = 0;
            2'b01: result_tag = 1;
            2'b10: result_tag = in_mode;
            default: result_tag = 0;
        endcase
    end

    // Connect the output of compute_core to the TopModule output
    assign out = core_out;
    assign out_valid = in_valid;
    assign out_y = result_y;
    assign out_tag = result_tag;
endmodule

module control_fsm (
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic [1:0] state_next
);
    // State encoding
    logic [1:0] state;

    // State transition logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 2'b00;
        end else begin
            case (state)
                2'b00: state <= in ? 2'b01 : 2'b00;
                2'b01: state <= in ? 2'b10 : 2'b01;
                2'b10: state <= in ? 2'b10 : 2'b00;
                default: state <= 2'b00;
            endcase
        end
    end

    // Output logic
    assign state_next = state;
endmodule

module compute_core (
    input  logic clk,
    input  logic reset,
    input  logic in,
    input  logic [1:0] state_next,
    output logic out
);
    // Output logic based on state
    always_comb begin
        case (state_next)
            2'b00: out = 0;
            2'b01: out = 1;
            2'b10: out = in;
            default: out = 0;
        endcase
    end
endmodule
