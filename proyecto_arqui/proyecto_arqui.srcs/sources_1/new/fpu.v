`timescale 1ns / 1ps
module fpu (
    input wire [31:0] SrcA,
    input wire [31:0] SrcB,
    input wire [3:0] ALUControl,
    input wire [3:0] InstrRd,      // Para detectar si es 16 o 32 bits
    output reg [31:0] FPUResult
);
    
    // Detectar si es operación de 16 bits (basado en el registro destino)
    // Asumimos que registros pares (R0, R2, R4...) son para 32 bits
    // y registros impares (R1, R3, R5...) son para 16 bits
    wire is_16bit = InstrRd[0];
    
    // Señales para IEEE 754 de 32 bits
    wire signA_32, signB_32;
    wire [7:0] expA_32, expB_32;
    wire [22:0] mantA_32, mantB_32;
    
    // Señales para IEEE 754 de 16 bits (half precision)
    wire signA_16, signB_16;
    wire [4:0] expA_16, expB_16;
    wire [9:0] mantA_16, mantB_16;
    
    // Extraer campos para 32 bits
    assign signA_32 = SrcA[31];
    assign expA_32 = SrcA[30:23];
    assign mantA_32 = SrcA[22:0];
    
    assign signB_32 = SrcB[31];
    assign expB_32 = SrcB[30:23];
    assign mantB_32 = SrcB[22:0];
    
    // Extraer campos para 16 bits (de los 16 bits bajos)
    assign signA_16 = SrcA[15];
    assign expA_16 = SrcA[14:10];
    assign mantA_16 = SrcA[9:0];
    
    assign signB_16 = SrcB[15];
    assign expB_16 = SrcB[14:10];
    assign mantB_16 = SrcB[9:0];
    
    // Mantisas extendidas (con bit implícito)
    wire [23:0] mantA_32_ext = {1'b1, mantA_32};
    wire [23:0] mantB_32_ext = {1'b1, mantB_32};
    wire [10:0] mantA_16_ext = {1'b1, mantA_16};
    wire [10:0] mantB_16_ext = {1'b1, mantB_16};
    
    // CAMBIO: Operaciones para 32 bits - ahora son reg
    reg [24:0] sum_mant_32, diff_mant_32;
    reg [47:0] mul_mant_32;
    reg [7:0] exp_diff_32;
    reg [7:0] result_exp_32;
    reg [22:0] result_mant_32;
    reg result_sign_32;
    
    // CAMBIO: Operaciones para 16 bits - ahora son reg
    reg [11:0] sum_mant_16, diff_mant_16;
    reg [21:0] mul_mant_16;
    reg [4:0] exp_diff_16;
    reg [4:0] result_exp_16;
    reg [9:0] result_mant_16;
    reg result_sign_16;
    
    always @(*) begin
        case (ALUControl)
            4'b1001: begin  // FADD
                if (is_16bit) begin
                    // FADD 16 bits - Implementación simplificada
                    if (expA_16 == expB_16) begin
                        // Mismo exponente, sumar mantisas
                        sum_mant_16 = mantA_16_ext + mantB_16_ext;
                        result_exp_16 = expA_16;
                        result_mant_16 = sum_mant_16[10:1];
                        result_sign_16 = signA_16;  // Simplificado
                        FPUResult = {16'h0000, result_sign_16, result_exp_16, result_mant_16};
                    end else begin
                        // Diferentes exponentes - implementación simplificada
                        FPUResult = SrcA;  // Retornar el operando A como resultado por defecto
                    end
                end else begin
                    // FADD 32 bits - Implementación simplificada
                    if (expA_32 == expB_32) begin
                        // Mismo exponente, sumar mantisas
                        sum_mant_32 = mantA_32_ext + mantB_32_ext;
                        result_exp_32 = expA_32;
                        result_mant_32 = sum_mant_32[22:0];
                        result_sign_32 = signA_32;  // Simplificado
                        FPUResult = {result_sign_32, result_exp_32, result_mant_32};
                    end else begin
                        // Diferentes exponentes - implementación simplificada
                        FPUResult = SrcA;  // Retornar el operando A como resultado por defecto
                    end
                end
            end
            
            4'b1010: begin  // FMUL
                if (is_16bit) begin
                    // FMUL 16 bits
                    mul_mant_16 = mantA_16_ext * mantB_16_ext;
                    result_exp_16 = expA_16 + expB_16 - 5'd15;  // Bias para 16 bits es 15
                    result_mant_16 = mul_mant_16[20:11];  // Tomar los bits más significativos
                    result_sign_16 = signA_16 ^ signB_16;
                    FPUResult = {16'h0000, result_sign_16, result_exp_16, result_mant_16};
                end else begin
                    // FMUL 32 bits
                    mul_mant_32 = mantA_32_ext * mantB_32_ext;
                    result_exp_32 = expA_32 + expB_32 - 8'd127;  // Bias para 32 bits es 127
                    result_mant_32 = mul_mant_32[46:24];  // Tomar los bits más significativos
                    result_sign_32 = signA_32 ^ signB_32;
                    FPUResult = {result_sign_32, result_exp_32, result_mant_32};
                end
            end
            
            default: FPUResult = 32'h00000000;
        endcase
    end
    
endmodule