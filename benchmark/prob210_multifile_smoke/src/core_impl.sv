module core_impl (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [1:0] op,
    output logic [7:0] y
);
    always_comb begin
        case (op)
            2'b00: y = a + b;
            2'b01: y = a ^ b;
            2'b10: y = a & b;
            default: y = a - b;
        endcase
    end
endmodule
