module TopModule
(
    input  logic        clk,
    input  logic        load,
    input  logic [1:0]  ena,
    input  logic [99:0] data,
    output logic [99:0] q
);

    // 100-bit register to store the data
    logic [99:0] reg_data;

    // Sequential logic for loading or retaining data
    always @(posedge clk) begin
        if (load)
            reg_data <= data;
        else if (ena == 2'b01) // Rotate right
            reg_data <= {reg_data[0], reg_data[99:1]};
        else if (ena == 2'b10) // Rotate left
            reg_data <= {reg_data[98:0], reg_data[99]};
    end

    // Output assignment
    assign q = reg_data;

endmodule
