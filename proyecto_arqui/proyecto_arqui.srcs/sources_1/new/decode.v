`timescale 1ns / 1ps

module decode (
    clk,
    reset,
    Op,
    Funct,
    Rd,
    InstrLow,
    FlagW,
    PCS,
    NextPC,
    RegW,
    MemW,
    IRWrite,
    AdrSrc,
    ResultSrc,
    ALUSrcA,
    ALUSrcB,
    ImmSrc,
    RegSrc,
    ALUControl
);
    input wire clk;
    input wire reset;
    input wire [1:0] Op;
    input wire [5:0] Funct;
    input wire [3:0] Rd;
    input wire [3:0] InstrLow;
    output reg [1:0] FlagW;
    output wire PCS;
    output wire NextPC;
    output wire RegW;
    output wire MemW;
    output wire IRWrite;
    output wire AdrSrc;
    output wire [1:0] ResultSrc;
    output wire [1:0] ALUSrcA;
    output wire [1:0] ALUSrcB;
    output wire [1:0] ImmSrc;
    output wire [1:0] RegSrc;
    output reg [2:0] ALUControl;
    
    wire Branch;
    wire ALUOp;
    
    mainfsm fsm(
        .clk(clk),
        .reset(reset),
        .Op(Op),
        .Funct(Funct),
        .IRWrite(IRWrite),
        .AdrSrc(AdrSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ResultSrc(ResultSrc),
        .NextPC(NextPC),
        .RegW(RegW),
        .MemW(MemW),
        .Branch(Branch),
        .ALUOp(ALUOp)
    );
    
    assign ImmSrc = Op;
    
    assign RegSrc[1] = Op == 2'b01; 
    assign RegSrc[0] = Op == 2'b10;
    
    always @(*) begin
        if (ALUOp) begin
            case (Funct[4:1])
                4'b0100: ALUControl = 3'b000;
                4'b0010: ALUControl = 3'b001;
                4'b0000: begin
                    if (InstrLow == 4'b1001)
                        ALUControl = 3'b101;
                    else
                        ALUControl = 3'b010;
                end
                4'b1100: ALUControl = 3'b011;
                4'b1101: ALUControl = 3'b100;
                default: ALUControl = 3'bxxx;
            endcase
            
            if (InstrLow == 4'b1001 && Funct[4:1] == 4'b0000) begin
                FlagW[1] = Funct[0];
                FlagW[0] = 1'b0;
            end else begin
                FlagW[1] = Funct[0];
                FlagW[0] = Funct[0] & ((ALUControl == 3'b000) | (ALUControl == 3'b001));
            end
        end
        else begin
            ALUControl = 3'b000;
            FlagW = 2'b00;
        end
    end
    
    assign PCS = ((Rd == 4'b1111) & RegW) | Branch;
endmodule