module TopModule
(
    input  logic       clk,
    input  logic       reset,
    input  logic       valid,
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [3:0] op,
    output logic [7:0] y,
    output logic       done
);

    // Sequential logic to hold results and done signal
    logic [7:0] result;
    logic       result_valid;

    always @(posedge clk) begin
        if (reset) begin
            result <= 0;
            result_valid <= 0;
        end else if (valid) begin
            case (op)
                4'h0: result <= a + b;
                4'h1: result <= a - b;
                4'hA: result <= a & b; // Corrected operation for op=10
                4'hB: result <= a | b; // Corrected operation for op=11
                default: result <= a + b; // Default operation
            endcase
            result_valid <= 1;
        end else begin
            result_valid <= 0;
        end
    end

    // Output assignment
    assign y = result;
    assign done = result_valid;

endmodule