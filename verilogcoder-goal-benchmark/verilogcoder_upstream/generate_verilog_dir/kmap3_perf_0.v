module TopModule(
    input  logic a,
    input  logic b,
    input  logic c,
    output logic out
);

    // Combinational logic to implement the Karnaugh map
    assign out = ~(~a & ~b & ~c);

endmodule