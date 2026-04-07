module TopModule (
    input  logic       clk,
    input  logic       load,
    input  logic [1:0] ena,
    input  logic [99:0] data,
    output logic [99:0] q
);

    // Internal signals
    logic [99:0] reg_data;

    // Sequential logic for loading and rotating data
    always @(posedge clk) begin
        if (load) begin
            reg_data <= data;
        end else begin
            case (ena)
                2'b01: reg_data <= {reg_data[0], reg_data[99:1]};  // Rotate right
                2'b10: reg_data <= {reg_data[98:0], reg_data[99]}; // Rotate left
                default: reg_data <= reg_data;                     // Hold
            endcase
        end
    end

    // Output assignment
    assign q = reg_data;

endmodule