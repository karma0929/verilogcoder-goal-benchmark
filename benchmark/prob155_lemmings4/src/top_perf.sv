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

    localparam [6:0] WL    = 7'b0000001;
    localparam [6:0] WR    = 7'b0000010;
    localparam [6:0] FALLL = 7'b0000100;
    localparam [6:0] FALLR = 7'b0001000;
    localparam [6:0] DIGL  = 7'b0010000;
    localparam [6:0] DIGR  = 7'b0100000;
    localparam [6:0] DEAD  = 7'b1000000;

    reg [6:0] state, next;
    reg [4:0] fall_counter;

    always @(*) begin
        next = state;

        case (1'b1)
            state[0]: begin // WL
                if (!ground)
                    next = FALLL;
                else if (dig)
                    next = DIGL;
                else if (bump_left)
                    next = WR;
                else
                    next = WL;
            end

            state[1]: begin // WR
                if (!ground)
                    next = FALLR;
                else if (dig)
                    next = DIGR;
                else if (bump_right)
                    next = WL;
                else
                    next = WR;
            end

            state[2]: begin // FALLL
                if (ground)
                    next = (fall_counter >= 5'd20) ? DEAD : WL;
                else
                    next = FALLL;
            end

            state[3]: begin // FALLR
                if (ground)
                    next = (fall_counter >= 5'd20) ? DEAD : WR;
                else
                    next = FALLR;
            end

            state[4]: begin // DIGL
                if (!ground)
                    next = FALLL;
                else
                    next = DIGL;
            end

            state[5]: begin // DIGR
                if (!ground)
                    next = FALLR;
                else
                    next = DIGR;
            end

            state[6]: begin // DEAD
                next = DEAD;
            end

            default: begin
                next = WL;
            end
        endcase
    end

    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= WL;
        else
            state <= next;
    end

    always @(posedge clk) begin
        if (state == FALLL || state == FALLR) begin
            if (fall_counter < 5'd20)
                fall_counter <= fall_counter + 5'd1;
        end else begin
            fall_counter <= 5'd0;
        end
    end

    assign walk_left  = state[0];
    assign walk_right = state[1];
    assign aaah       = state[2] | state[3];
    assign digging    = state[4] | state[5];

endmodule