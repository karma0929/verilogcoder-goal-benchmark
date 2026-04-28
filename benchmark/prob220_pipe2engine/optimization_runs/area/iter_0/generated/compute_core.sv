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
