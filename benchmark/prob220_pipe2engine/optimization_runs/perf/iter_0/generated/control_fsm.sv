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
