module TopModule (
    input  logic        clk,
    input  logic        load,
    input  logic [1:0]  ena,
    input  logic [99:0] data,
    output logic [99:0] q
);

    // Register to store the input data
    logic [99:0] data_reg;

    // Sequential logic to load the data register
    always @(posedge clk) begin
        if (load)
            data_reg <= data;
        else if (ena == 2'b01)  // Rotate left
            data_reg <= {data_reg[98:0], data_reg[99]};
        else if (ena == 2'b10)  // Rotate right
            data_reg <= {data_reg[0], data_reg[99:1]};
    end

    // Output assignment
    assign q = data_reg;

endmodule
