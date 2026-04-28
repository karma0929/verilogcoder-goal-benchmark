module control_fsm (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] data_in,
    output logic       valid_out
);

    // State definitions
    localparam IDLE = 1'b0,
               VALID = 1'b1;

    // State register
    logic state, next_state;

    // Sequential logic for state transitions
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = (data_in == 8'b0) ? IDLE : VALID;
            VALID: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Output logic
    always @(*) begin
        valid_out = (state == VALID);
    end

endmodule