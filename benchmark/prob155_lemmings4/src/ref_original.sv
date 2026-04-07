module TopModule (
  input clk,
  input areset,
  input bump_left,
  input bump_right,
  input ground,
  input dig,
  output walk_left,
  output walk_right,
  output aaah,
  output digging
);

  localparam WL=3'd0, WR=3'd1, FALLL=3'd2, FALLR=3'd3, DIGL=3'd4, DIGR=3'd5, DEAD=3'd6;

  reg [2:0] state, next;
  reg [4:0] fall_counter;

  always @(*) begin
    next = state;
    case (state)
      WL: begin
        if (!ground)       next = FALLL;
        else if (dig)      next = DIGL;
        else if (bump_left) next = WR;
        else               next = WL;
      end

      WR: begin
        if (!ground)        next = FALLR;
        else if (dig)       next = DIGR;
        else if (bump_right) next = WL;
        else                next = WR;
      end

      FALLL: begin
        if (ground) next = (fall_counter >= 5'd20) ? DEAD : WL;
        else        next = FALLL;
      end

      FALLR: begin
        if (ground) next = (fall_counter >= 5'd20) ? DEAD : WR;
        else        next = FALLR;
      end

      DIGL: begin
        if (ground) next = DIGL;
        else        next = FALLL;
      end

      DIGR: begin
        if (ground) next = DIGR;
        else        next = FALLR;
      end

      DEAD: begin
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

  always @(posedge clk or posedge areset) begin
    if (areset)
      fall_counter <= 5'd0;
    else if (state == FALLL || state == FALLR) begin
      if (fall_counter < 5'd20)
        fall_counter <= fall_counter + 5'd1;
      else
        fall_counter <= fall_counter;
    end else begin
      fall_counter <= 5'd0;
    end
  end

  assign walk_left  = (state == WL);
  assign walk_right = (state == WR);
  assign aaah       = (state == FALLL) || (state == FALLR);
  assign digging    = (state == DIGL) || (state == DIGR);

endmodule
