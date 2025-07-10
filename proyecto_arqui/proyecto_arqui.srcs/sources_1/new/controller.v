module controller (
    clk,
    reset,
    Instr,
    ALUFlags,
    PCWrite,
    MemWrite,
    RegWrite,
    IRWrite,
    AdrSrc,
    RegSrc,
    ALUSrcA,
    ALUSrcB,
    ResultSrc,
    ImmSrc,
    ALUControl,
    UMullState,
    SMullCondition,
    // Nuevas señales para FPU
    FPUOp,
    FPRegWrite,
    FPUSrcA,
    FPUSrcB,
    FPUControl
);
    input wire clk;
    input wire reset;
    input wire [31:0] Instr;
    input wire [3:0] ALUFlags;
    output wire PCWrite;
    output wire MemWrite;
    output wire RegWrite;
    output wire IRWrite;
    output wire AdrSrc;
    output wire [1:0] RegSrc;
    output wire [1:0] ALUSrcA;
    output wire [1:0] ALUSrcB;
    output wire [1:0] ResultSrc;
    output wire [1:0] ImmSrc;
    output wire [3:0] ALUControl;
    output wire UMullState;
    output wire SMullCondition;
    
    // Nuevas salidas para FPU
    output wire FPUOp;
    output wire FPRegWrite;
    output wire [1:0] FPUSrcA;
    output wire [1:0] FPUSrcB;
    output wire [2:0] FPUControl;
    
    wire [1:0] FlagW;
    wire PCS;
    wire NextPC;
    wire RegW;
    wire MemW;

    decode dec(
        .clk(clk),
        .reset(reset),
        .Op(Instr[27:26]),
        .Funct(Instr[25:20]),
        .Rd(Instr[15:12]),
        .InstrLow(Instr[7:4]),
        .UMullState(UMullState),
        .FlagW(FlagW),
        .PCS(PCS),
        .NextPC(NextPC),
        .RegW(RegW),
        .MemW(MemW),
        .IRWrite(IRWrite),
        .AdrSrc(AdrSrc),
        .ResultSrc(ResultSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ImmSrc(ImmSrc),
        .RegSrc(RegSrc),
        .ALUControl(ALUControl),
        .UMullCondition(),  // NO CONECTAR (no se usa afuera)
        .SMullCondition(SMullCondition),
        // Conexiones FPU
        .FPUOp(FPUOp),
        .FPRegWrite(FPRegWrite),
        .FPUSrcA(FPUSrcA),
        .FPUSrcB(FPUSrcB),
        .FPUControl(FPUControl)
    );
    
    condlogic cl(
        .clk(clk),
        .reset(reset),
        .Cond(Instr[31:28]),
        .ALUFlags(ALUFlags),
        .FlagW(FlagW),
        .PCS(PCS),
        .NextPC(NextPC),
        .RegW(RegW),
        .MemW(MemW),
        .PCWrite(PCWrite),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite)
    );
endmodule