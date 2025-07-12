module fpu (
  input wire [31:0] a, b,
  input wire op, // 0: ADD, 1: MUL
  input wire precision, // 0: half (16-bit), 1: single (32-bit)
  output reg [31:0] result,
  output reg overflowFlag
);
  reg [31:0] a_fp, b_fp, res_fp;
  reg overflow;
  
  // Conversión de half precision a single precision
  function [31:0] half2single;
    input [15:0] h;
    reg sign;
    reg [4:0] exp_h;
    reg [9:0] frac_h;
    reg [7:0] exp_s;
    reg [22:0] frac_s;
    begin
      sign = h[15];
      exp_h = h[14:10];
      frac_h = h[9:0];
      
      if (exp_h == 0) begin
        exp_s = 0;
        frac_s = 0;
      end else if (exp_h == 5'b11111) begin
        exp_s = 8'hFF;
        frac_s = {frac_h, 13'b0};
      end else begin
        exp_s = exp_h - 5'd15 + 8'd127;
        frac_s = {frac_h, 13'b0};
      end
      
      half2single = {sign, exp_s, frac_s};
    end
  endfunction
  
  // Conversión de single precision a half precision
  function [15:0] single2half;
    input [31:0] s;
    reg sign;
    reg [7:0] exp_s;
    reg [22:0] frac_s;
    reg [4:0] exp_h;
    reg [9:0] frac_h;
    begin
      sign = s[31];
      exp_s = s[30:23];
      frac_s = s[22:0];
      
      if (exp_s == 0) begin
        exp_h = 0;
        frac_h = 0;
      end else if (exp_s == 8'hFF) begin
        exp_h = 5'b11111;
        frac_h = frac_s[22:13];
      end else begin
        exp_h = exp_s - 8'd127 + 5'd15;
        frac_h = frac_s[22:13];
        // Saturación para evitar overflow
        if (exp_h > 5'd30) begin
          exp_h = 5'b11111;
          frac_h = 0;
        end else if (exp_h < 1) begin
          exp_h = 0;
          frac_h = 0;
        end
      end
      
      single2half = {sign, exp_h, frac_h};
    end
  endfunction
  
  // Suma de punto flotante IEEE 754
  function [31:0] fp_add;
    input [31:0] a, b;
    reg sign_a, sign_b, sign_res;
    reg [7:0] exp_a, exp_b, exp_res;
    reg [23:0] frac_a, frac_b, frac_res;
    reg [8:0] exp_diff;
    reg [24:0] frac_sum;
    reg [4:0] shift_count;
    integer i;
    begin
      // Extraer campos
      sign_a = a[31];
      exp_a = a[30:23];
      frac_a = {1'b1, a[22:0]};
      
      sign_b = b[31];
      exp_b = b[30:23];
      frac_b = {1'b1, b[22:0]};
      
      // Casos especiales
      if (exp_a == 0) begin
        fp_add = b;
      end else if (exp_b == 0) begin
        fp_add = a;
      end else if (exp_a == 8'hFF || exp_b == 8'hFF) begin
        fp_add = 32'h7FC00000; // NaN
      end else begin
        // Alinear exponentes
        if (exp_a > exp_b) begin
          exp_diff = exp_a - exp_b;
          exp_res = exp_a;
          if (exp_diff > 24) begin
            frac_b = 0;
          end else begin
            frac_b = frac_b >> exp_diff;
          end
        end else begin
          exp_diff = exp_b - exp_a;
          exp_res = exp_b;
          if (exp_diff > 24) begin
            frac_a = 0;
          end else begin
            frac_a = frac_a >> exp_diff;
          end
        end
        
        // Realizar suma o resta
        if (sign_a == sign_b) begin
          frac_sum = frac_a + frac_b;
          sign_res = sign_a;
        end else begin
          if (frac_a >= frac_b) begin
            frac_sum = frac_a - frac_b;
            sign_res = sign_a;
          end else begin
            frac_sum = frac_b - frac_a;
            sign_res = sign_b;
          end
        end
        
        // Normalizar resultado
        if (frac_sum[24]) begin
          frac_sum = frac_sum >> 1;
          exp_res = exp_res + 1;
        end else if (frac_sum[23] == 0) begin
          // Encontrar el primer bit 1
          shift_count = 0;
          for (i = 22; i >= 0; i = i - 1) begin
            if (frac_sum[i] && shift_count == 0) begin
              shift_count = 23 - i;
            end
          end
          frac_sum = frac_sum << shift_count;
          exp_res = exp_res - shift_count;
        end
        
        // Verificar overflow/underflow
        if (exp_res >= 8'hFF) begin
          fp_add = {sign_res, 8'hFF, 23'b0}; // Infinito
        end else if (exp_res == 0) begin
          fp_add = {sign_res, 31'b0}; // Cero
        end else begin
          fp_add = {sign_res, exp_res, frac_sum[22:0]};
        end
      end
    end
  endfunction
  
  // Multiplicación de punto flotante IEEE 754
  function [31:0] fp_mul;
    input [31:0] a, b;
    reg sign_a, sign_b, sign_res;
    reg [7:0] exp_a, exp_b;
    reg [8:0] exp_res;
    reg [23:0] frac_a, frac_b;
    reg [47:0] frac_mul;
    reg [22:0] frac_res;
    begin
      // Extraer campos
      sign_a = a[31];
      exp_a = a[30:23];
      frac_a = {1'b1, a[22:0]};
      
      sign_b = b[31];
      exp_b = b[30:23];
      frac_b = {1'b1, b[22:0]};
      
      sign_res = sign_a ^ sign_b;
      
      // Casos especiales
      if (exp_a == 0 || exp_b == 0) begin
        fp_mul = {sign_res, 31'b0}; // Cero
      end else if (exp_a == 8'hFF || exp_b == 8'hFF) begin
        fp_mul = {sign_res, 8'hFF, 23'b0}; // Infinito
      end else begin
        // Multiplicar exponentes
        exp_res = exp_a + exp_b - 8'd127;
        
        // Multiplicar mantisas
        frac_mul = frac_a * frac_b;
        
        // Normalizar
        if (frac_mul[47]) begin
          frac_res = frac_mul[46:24];
          exp_res = exp_res + 1;
        end else begin
          frac_res = frac_mul[45:23];
        end
        
        // Verificar overflow/underflow
        if (exp_res >= 9'd255) begin
          fp_mul = {sign_res, 8'hFF, 23'b0}; // Infinito
        end else if (exp_res <= 0) begin
          fp_mul = {sign_res, 31'b0}; // Cero
        end else begin
          fp_mul = {sign_res, exp_res[7:0], frac_res};
        end
      end
    end
  endfunction
  
  always @(*) begin
    // Convertir entradas según la precisión
    if (precision) begin
      a_fp = a;
      b_fp = b;
    end else begin
      a_fp = half2single(a[15:0]);
      b_fp = half2single(b[15:0]);
    end
    
    // Realizar operación
    case (op)
      1'b0: res_fp = fp_add(a_fp, b_fp);
      1'b1: res_fp = fp_mul(a_fp, b_fp);
      default: res_fp = 32'bx;
    endcase
    
    // Detectar overflow
    overflow = (res_fp[30:23] == 8'hFF);
    
    // Convertir resultado según la precisión
    if (precision) begin
      result = res_fp;
    end else begin
      result = {16'b0, single2half(res_fp)};
    end
    
    overflowFlag = overflow;
  end
endmodule