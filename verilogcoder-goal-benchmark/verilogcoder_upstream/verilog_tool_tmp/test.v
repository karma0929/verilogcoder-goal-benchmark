module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    output logic out
);

    // Combinational logic to determine the output
    always @(*) begin
        out = ~(a == 0 && b == 0 && c == 0);
    end

endmodule