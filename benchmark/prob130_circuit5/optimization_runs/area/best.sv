module TopModule (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic [3:0] c,
    input  logic [3:0] d,
    input  logic [3:0] e,
    output logic [3:0] q
);
    // Combinational logic to determine output q based on inputs a, b, c, d, e
    always @(*) begin
        case (c) // Select output based on the value of c
            4'b0000: q = b; // When c is 0, output b
            4'b0001: q = e; // When c is 1, output e
            4'b0010: q = a; // When c is 2, output a
            4'b0011: q = d; // When c is 3, output d
            default: q = 4'b1111; // Output f when c > 3
        endcase
    end
endmodule
