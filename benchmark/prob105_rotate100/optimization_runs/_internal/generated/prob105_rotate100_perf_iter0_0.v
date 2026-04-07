module TopModule
(
    input  logic        clk,
    input  logic        load,
    input  logic [1:0]  ena,
    input  logic [99:0] data,
    output logic [99:0] q
);

    // Internal register to hold the data
    logic [99:0] internal_reg;

    // Sequential logic to load data into the register
    always @(posedge clk) begin
        if (load) begin
            internal_reg <= data;
        end
        else begin
            case (ena)
                2'b01: internal_reg <= {internal_reg[0], internal_reg[99:1]};  // Rotate right
                2'b10: internal_reg <= {internal_reg[98:0], internal_reg[99]}; // Rotate left
                default: internal_reg <= internal_reg; // No rotation
            endcase
        end
    end

    // Output assignment
    assign q = internal_reg;

endmodule