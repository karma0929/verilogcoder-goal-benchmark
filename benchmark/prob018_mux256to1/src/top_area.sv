module TopModule (
    input  logic [255:0] in,
    input  logic [7:0]   sel,
    output logic         out
);

    // Combinational logic to select the output bit based on the selector
    assign out = in[sel];

endmodule
