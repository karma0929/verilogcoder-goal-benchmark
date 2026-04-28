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
