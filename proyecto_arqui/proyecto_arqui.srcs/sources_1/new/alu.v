`timescale 1ns / 1ps

module alu(input  [31:0] SrcA, SrcB,
    input  [2:0]  ALUControl,
    output reg [31:0] ALUResult,
    output wire [3:0] ALUFlags);
    wire neg, zero, carry, overflow;
    wire [31:0] condinvb;
    wire [32:0] sum;

    assign condinvb = ALUControl[0] ? ~SrcB : SrcB;
    assign sum = SrcA + condinvb + ALUControl[0];
    always @(*) begin
        casex (ALUControl)
            3'b00?: ALUResult = sum;             // ADD
            3'b010: ALUResult = SrcA & SrcB;     // AND
            3'b011: ALUResult = SrcA | SrcB;     // ORR
            3'b100: ALUResult = SrcB;            // MOV (A = 0, B = val)
            default: ALUResult = 32'hxxxxxxxx;
        endcase
    end

    assign neg = ALUResult[31];
    assign zero = (ALUResult == 32'b0);
    assign carry = (ALUControl[2:1] == 2'b00) & sum[32];
    assign overflow = (ALUControl[2:1] == 2'b00) & ~(SrcA[31] ^ SrcB[31] ^ ALUControl[0]) & (SrcA[31] ^ sum[31]);
    assign ALUFlags = {neg, zero, carry, overflow};
    
endmodule