module TopModule (
    input  logic [254:0] in,
    output logic [7:0] out
);

    // Combinational logic to count the number of '1's in the input
    always @(*) begin
        int count;
        count = 0;
        for (int i = 0; i < 255; i++) begin
            count = count + in[i];
        end
        out = count;
    end

endmodule