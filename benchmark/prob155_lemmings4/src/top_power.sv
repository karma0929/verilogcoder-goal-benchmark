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

    reg dir;          // 0 = left, 1 = right
    reg falling;
    reg digging_r;
    reg dead;
    reg [4:0] fall_counter;

    always @(posedge clk or posedge areset) begin
        if (areset) begin
            dir        <= 1'b0;
            falling    <= 1'b0;
            digging_r  <= 1'b0;
            dead       <= 1'b0;
        end else if (dead) begin
            dir        <= dir;
            falling    <= 1'b0;
            digging_r  <= 1'b0;
            dead       <= 1'b1;
        end else if (falling) begin
            if (ground) begin
                if (fall_counter >= 5'd20) begin
                    dead      <= 1'b1;
                    falling   <= 1'b0;
                    digging_r <= 1'b0;
                end else begin
                    falling   <= 1'b0;
                    digging_r <= 1'b0;
                    dead      <= 1'b0;
                end
            end
        end else if (digging_r) begin
            if (!ground) begin
                digging_r <= 1'b0;
                falling   <= 1'b1;
            end
        end else begin
            if (!ground) begin
                falling <= 1'b1;
            end else if (dig) begin
                digging_r <= 1'b1;
            end else if (!dir && bump_left) begin
                dir <= 1'b1;
            end else if (dir && bump_right) begin
                dir <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (falling) begin
            if (fall_counter < 5'd20)
                fall_counter <= fall_counter + 5'd1;
        end else begin
            fall_counter <= 5'd0;
        end
    end

    assign walk_left  = !dead && !falling && !digging_r && !dir;
    assign walk_right = !dead && !falling && !digging_r &&  dir;
    assign aaah       = !dead && falling;
    assign digging    = !dead && digging_r;

endmodule