module fpu (
  input wire [31:0] a, b,
  input wire op, // 0: ADD, 1: MUL
  input wire precision, // 0: half (16-bit), 1: single (32-bit)
  output reg [31:0] result,
  output reg overflowFlag
);
  reg [31:0] a_fp, b_fp, res_fp;
  reg overflow;
  
  function [31:0] half2single;
    input [15:0] h;
    reg sign;
    reg [4:0] exp;
    reg [9:0] frac;
    reg [7:0] exp_s;
    begin
      sign = h[15];
      exp = h[14:10];
      frac = h[9:0];
      if (exp == 0)
        exp_s = 0;
      else if (exp == 5'b11111)
        exp_s = 8'hFF;
      else
        exp_s = exp - 5'd15 + 8'd127;
      half2single = {sign, exp_s, frac, 13'b0};
    end
  endfunction
  
  function [15:0] single2half;
    input [31:0] s;
    reg sign;
    reg [7:0] exp;
    reg [22:0] frac;
    reg [4:0] exp_h;
    begin
      sign = s[31];
      exp = s[30:23];
      frac = s[22:0];
      if (exp == 0)
        exp_h = 0;
      else if (exp == 8'hFF)
        exp_h = 5'b11111;
      else
        exp_h = exp - 8'd127 + 5'd15;
      single2half = {sign, exp_h, frac[22:13]};
    end
  endfunction
  
  always @(*) begin
    if (precision) begin
      a_fp = a;
      b_fp = b;
    end else begin
      a_fp = half2single(a[15:0]);
      b_fp = half2single(b[15:0]);
    end
    
    overflow = 0;
    case (op)
      1'b0: res_fp = $bitstoreal($realtobits($bitstoreal(a_fp) + $bitstoreal(b_fp)));
      1'b1: res_fp = $bitstoreal($realtobits($bitstoreal(a_fp) * $bitstoreal(b_fp)));
      default: res_fp = 32'bx;
    endcase
    
    if (precision) begin
      overflow = (res_fp[30:23] == 8'hFF);
      result = res_fp;
    end else begin
      overflow = (res_fp[30:23] == 8'hFF);
      result = {16'b0, single2half(res_fp)};
    end
    overflowFlag = overflow;
  end
endmodule
