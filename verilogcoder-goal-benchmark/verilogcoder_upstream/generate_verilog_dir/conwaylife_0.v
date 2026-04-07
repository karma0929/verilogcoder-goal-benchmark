module TopModule (
    input  logic        clk,
    input  logic        load,
    input  logic [255:0] data,
    output logic [255:0] q
);

    logic [255:0] next_state;

    always @(*) begin
        integer i, j;
        integer left, right, top, bottom;
        integer idx_tl, idx_tm, idx_tr, idx_ml, idx_mr, idx_bl, idx_bm, idx_br, idx_center;
        integer alive_neighbors;

        for (i = 0; i < 16; i++) begin
            for (j = 0; j < 16; j++) begin
                // Calculate indices considering toroidal wrap-around
                left = (j == 0) ? 15 : j - 1;
                right = (j == 15) ? 0 : j + 1;
                top = (i == 0) ? 15 : i - 1;
                bottom = (i == 15) ? 0 : i + 1;

                // Calculate linear index for neighbors
                idx_tl = top * 16 + left;    // top-left
                idx_tm = top * 16 + j;       // top-middle
                idx_tr = top * 16 + right;   // top-right
                idx_ml = i * 16 + left;      // middle-left
                idx_mr = i * 16 + right;     // middle-right
                idx_bl = bottom * 16 + left; // bottom-left
                idx_bm = bottom * 16 + j;    // bottom-middle
                idx_br = bottom * 16 + right;// bottom-right
                idx_center = i * 16 + j;     // center

                // Count alive neighbors
                alive_neighbors = q[idx_tl] + q[idx_tm] + q[idx_tr] +
                                  q[idx_ml] + q[idx_mr] +
                                  q[idx_bl] + q[idx_bm] + q[idx_br];

                // Game of Life rules
                if (alive_neighbors == 2) begin
                    next_state[idx_center] = q[idx_center]; // Keep current state
                end else if (alive_neighbors == 3) begin
                    next_state[idx_center] = 1;            // Become alive
                end else begin
                    next_state[idx_center] = 0;            // Become dead
                end
            end
        end
    end

    always @(posedge clk) begin
        if (load) begin
            q <= data;
        end else begin
            q <= next_state;
        end
    end

endmodule