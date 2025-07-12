module alu(
    input  [31:0] SrcA, SrcB,
    input  [3:0]  ALUControl,
    input  wire   SMullCondition,
    input  wire   FADDCondition,
    input  wire   FMULCondition,
    input  [3:0]  InstrRd,
    output reg [31:0] ALUResult,
    output wire [3:0] ALUFlags
);
    wire neg, zero, carry, overflow;
    wire [31:0] condinvb;
    wire [32:0] sum;
    wire [63:0] mul_result;
    wire signed [63:0] smul_result;
    wire [31:0] fpu_result;
    wire fpu_overflow;
    
    assign condinvb = ALUControl[0] ? ~SrcB : SrcB;
    assign sum = SrcA + condinvb + ALUControl[0];
    assign mul_result = SrcA * SrcB;
    
    // Multiplicación signed
    assign smul_result = $signed(SrcA) * $signed(SrcB);

    // Instancia del FPU sintetizable
    fpu fpu_inst (
        .a(SrcA),
        .b(SrcB),
        .op(ALUControl[1]),           // 0 para ADD, 1 para MUL
        .precision(~ALUControl[1]),   // 0 para 16-bit, 1 para 32-bit
        .result(fpu_result),
        .overflowFlag(fpu_overflow)
    );
    
    always @(*) begin
        casex (ALUControl)
            4'b000?: ALUResult = sum;                    // ADD/SUB
            4'b0010: ALUResult = SrcA & SrcB;            // AND
            4'b0011: ALUResult = SrcA | SrcB;            // ORR
            4'b0100: ALUResult = SrcB;                   // MOV (A = 0, B = val)
            4'b0101: ALUResult = mul_result[31:0];       // MUL
            4'b0110: ALUResult = SMullCondition ? smul_result[31:0] : mul_result[31:0];
            4'b0111: ALUResult = SMullCondition ? smul_result[63:32] : mul_result[63:32];
            4'b1000: ALUResult = (SrcB != 0) ? (SrcA / SrcB) : 32'hFFFFFFFF;  // DIV
            4'b1001: ALUResult = fpu_result;             // FADD 32-bit
            4'b1010: ALUResult = fpu_result;             // FMUL 32-bit
            4'b1011: ALUResult = fpu_result;             // FADD 16-bit
            4'b1100: ALUResult = fpu_result;             // FMUL 16-bit
            default: ALUResult = 32'hxxxxxxxx;
        endcase
    end
    
    // Flags para operaciones de punto flotante
    wire fp_operation = (ALUControl[3:2] == 2'b10);
    
    assign neg = fp_operation ? fpu_result[31] : ALUResult[31];
    assign zero = fp_operation ? (fpu_result == 32'b0) : (ALUResult == 32'b0);
    assign carry = fp_operation ? fpu_overflow : ((ALUControl[2:1] == 2'b00) & sum[32]);
    assign overflow = fp_operation ? fpu_overflow : ((ALUControl[2:1] == 2'b00) & ~(SrcA[31] ^ SrcB[31] ^ ALUControl[0]) & (SrcA[31] ^ sum[31]));
    assign ALUFlags = {neg, zero, carry, overflow};
    
endmodule