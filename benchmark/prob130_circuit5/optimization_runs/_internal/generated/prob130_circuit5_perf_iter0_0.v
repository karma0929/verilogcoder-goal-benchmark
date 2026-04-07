module TopModule (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic [3:0] c,
    input  logic [3:0] d,
    input  logic [3:0] e,
    output logic [3:0] q
);
    // Revised combinational logic to determine the output q based on the inputs a, b, c, d, e
    always @(*) begin
        case (c)
            4'b0000: q = b;
            4'b0001: q = e;
            4'b0010: q = a;
            4'b0011: q = d;
            default: q = 4'b1111; // Output 1111 for c >= 4
        endcase
    end
endmodule