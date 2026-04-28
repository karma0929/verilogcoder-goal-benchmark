module TopModule
(
    input  logic       clk,
    input  logic       reset,
    input  logic       valid,
    input  logic [3:0] op,
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] y,
    output logic       done
);

    // Logic to process inputs based on operation code
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            y <= 0;
            done <= 0;
        end else if (valid) begin
            case (op)
                4'b0001: y <= a - b;  // Assuming op=1 corresponds to subtraction
                4'b1010: y <= (a + b) >> 2;  // Adjusted operation and shift for op=10
                4'b1011: y <= (a + b) >> 2;  // Adjusted operation and shift for op=11
                default: y <= a + b;  // Default operation is addition
            endcase
            done <= 1;
        end else begin
            done <= 0;
        end
    end

endmodule
