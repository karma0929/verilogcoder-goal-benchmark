module TopModule (
    input  logic clk,
    input  logic reset,
    output reg [3:0] q
);

    logic [3:0] next_q;

    // Combinational logic to determine the next state of the counter
    always @(*) begin
        if (q == 9)
            next_q = 0;
        else
            next_q = q + 1;
    end

    // Sequential logic to update the counter
    always @(posedge clk) begin
        if (reset) begin
            q <= 0;
        end else begin
            q <= next_q;
        end
    end

endmodule