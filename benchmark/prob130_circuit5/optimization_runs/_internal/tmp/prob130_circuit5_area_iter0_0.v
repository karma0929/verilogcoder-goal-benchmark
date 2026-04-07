module TopModule (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic [3:0] c,
    input  logic [3:0] d,
    input  logic [3:0] e,
    output logic [3:0] q
);

    always @(*) begin
        case (c % 4)  // Ensuring correct cycling through inputs based on c
            0: q = b;
            1: q = e;
            2: q = a;
            3: q = d;
            default: q = 4'b1111;  // Handling unexpected cases
        endcase
    end

endmodule