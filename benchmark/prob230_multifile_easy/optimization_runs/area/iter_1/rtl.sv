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

    // Logic to perform operations based on op code
    always @(posedge clk) begin
        if (reset) begin
            y <= 0;
            done <= 0;
        end else if (valid) begin
            case (op)
                4'b0000: y <= a + b; // Addition
                4'b0001: y <= a - b; // Subtraction
                4'b1010: y <= a & b; // Bitwise AND
                4'b1011: y <= a | b; // Bitwise OR
                default: y <= 0;
            endcase
            done <= 1;
        end else begin
            done <= 0;
        end
    end

endmodule
