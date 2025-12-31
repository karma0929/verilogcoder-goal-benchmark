module TopModule (
    input  logic [255:0] in,
    input  logic [7:0]   sel,
    output logic         out
);

    always @(*) begin
        out = in[sel]; // Directly use sel as an index to the in vector
    end

endmodule
