module compute_core (
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic [1:0]  mode,
    output logic [31:0] y
);
    always_comb begin
        case (mode)
            2'b00: y = {16'd0, a} + {16'd0, b};
            2'b01: y = {16'd0, a} * {16'd0, b};
            2'b10: y = {16'd0, a} ^ {16'd0, b};
            default: y = ({16'd0, a} << 1) + ({16'd0, b} << 2);
        endcase
    end
endmodule
