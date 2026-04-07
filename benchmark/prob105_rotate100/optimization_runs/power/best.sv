module TopModule (
    input  logic        clk,
    input  logic        load,
    input  logic [1:0]  ena,
    input  logic [99:0] data,
    output logic [99:0] q
);

    // Internal register to hold the data
    logic [99:0] internal_reg;

    // Sequential logic to load or retain the data
    always @(posedge clk) begin
        if (load)
            internal_reg <= data;
        else begin
            case (ena)
                2'b01: internal_reg <= {internal_reg[0], internal_reg[99:1]}; // Rotate right
                2'b10: internal_reg <= {internal_reg[98:0], internal_reg[99]}; // Rotate left
                default: internal_reg <= internal_reg; // Hold value
            endcase
        end
    end

    // Output assignment
    assign q = internal_reg;

endmodule
