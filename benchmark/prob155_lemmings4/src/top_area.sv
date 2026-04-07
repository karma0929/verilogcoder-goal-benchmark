module TopModule (
    input  clk,
    input  areset,
    input  bump_left,
    input  bump_right,
    input  ground,
    input  dig,
    output walk_left,
    output walk_right,
    output aaah,
    output digging
);

    localparam [1:0] MODE_WALK = 2'b00;
    localparam [1:0] MODE_FALL = 2'b01;
    localparam [1:0] MODE_DIG  = 2'b10;
    localparam [1:0] MODE_DEAD = 2'b11;

    reg [1:0] mode, mode_n;
    reg dir, dir_n;          // 0 = left, 1 = right
    reg [4:0] fall_counter;

    always @(*) begin
        mode_n = mode;
        dir_n  = dir;

        case (mode)
            MODE_WALK: begin
                if (!ground)
                    mode_n = MODE_FALL;
                else if (dig)
                    mode_n = MODE_DIG;
                else if (!dir && bump_left)
                    dir_n = 1'b1;
                else if (dir && bump_right)
                    dir_n = 1'b0;
            end

            MODE_FALL: begin
                if (ground)
                    mode_n = (fall_counter >= 5'd20) ? MODE_DEAD : MODE_WALK;
            end

            MODE_DIG: begin
                if (!ground)
                    mode_n = MODE_FALL;
            end

            MODE_DEAD: begin
                mode_n = MODE_DEAD;
            end

            default: begin
                mode_n = MODE_WALK;
                dir_n  = 1'b0;
            end
        endcase
    end

    always @(posedge clk or posedge areset) begin
        if (areset) begin
            mode <= MODE_WALK;
            dir  <= 1'b0;
        end else begin
            mode <= mode_n;
            dir  <= dir_n;
        end
    end

    always @(posedge clk) begin
        if (mode == MODE_FALL) begin
            if (fall_counter < 5'd20)
                fall_counter <= fall_counter + 5'd1;
        end else begin
            fall_counter <= 5'd0;
        end
    end

    assign walk_left  = (mode == MODE_WALK) && !dir;
    assign walk_right = (mode == MODE_WALK) &&  dir;
    assign aaah       = (mode == MODE_FALL);
    assign digging    = (mode == MODE_DIG);

endmodule