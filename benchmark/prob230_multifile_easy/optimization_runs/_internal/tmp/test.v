module TopModule
(
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] in,
    output logic [7:0] out
);

    // Sequential logic for registering the input signal
    logic [7:0] registered_in;

    always @(posedge clk) begin
        if (reset) begin
            registered_in <= 8'b0;
        end else begin
            registered_in <= in;
        end
    end

    // Combinational logic to increment the registered value
    always @(*) begin
        out = registered_in + 1;
    end

endmodule