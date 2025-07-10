`timescale 1ns / 1ps

module datapath (
    input wire clk,
    input wire reset,
    output wire [31:0] Adr,
    output wire [31:0] WriteData,
    input wire [31:0] ReadData,
    output wire [31:0] Instr,
    output wire [3:0] ALUFlags,
    input wire PCWrite,
    input wire RegWrite,
    input wire IRWrite,
    input wire AdrSrc,
    input wire [1:0] RegSrc,
    input wire [1:0] ALUSrcA,
    input wire [1:0] ALUSrcB,
    input wire [1:0] ResultSrc,
    input wire [1:0] ImmSrc,
    input wire [3:0] ALUControl,
    input wire UMullState,
    input wire SMullCondition,
    // Nuevas entradas para FPU
    input wire FPUOp,
    input wire FPRegWrite,
    input wire [1:0] FPUSrcA,
    input wire [1:0] FPUSrcB,
    input wire [2:0] FPUControl
);

    wire [31:0] PC;
    wire [31:0] ExtImm;
    wire [31:0] SrcA;
    wire [31:0] SrcB;
    wire [31:0] Result;
    wire [31:0] Data;
    wire [31:0] RD1;
    wire [31:0] RD2;
    wire [31:0] A;
    wire [31:0] ALUResult;
    wire [31:0] ALUOut;
    wire [3:0] RA1;
    wire [3:0] RA2;
    wire [3:0] WA3;
    wire MulCondition;
    wire UMullCondition;
    wire SMullCondition_internal;
    
    // Nuevas señales para FPU
    wire [31:0] FPUSrcAData;
    wire [31:0] FPUSrcBData;
    wire [31:0] FPUResult;
    wire [31:0] FPUOut;
    wire [3:0] FPUFlags;
    wire [4:0] FPRA1;
    wire [4:0] FPRA2;
    wire [4:0] FPWA3;
    wire FADDCondition;
    wire FMULCondition;

    // Detectar MUL y UMULL
    assign MulCondition    = (Instr[27:21] == 7'b0000000) && (Instr[7:4] == 4'b1001);
    assign UMullCondition  = (Instr[27:21] == 7'b0000100) && (Instr[7:4] == 4'b1001);
    assign SMullCondition_internal = (Instr[27:21] == 7'b0000110) && (Instr[7:4] == 4'b1001);

    // Detectar instrucciones de punto flotante
    assign FADDCondition = (Instr[27:26] == 2'b00) && (Instr[25:20] == 6'b010000) && (Instr[7:4] == 4'b0000);
    assign FMULCondition = (Instr[27:26] == 2'b00) && (Instr[25:20] == 6'b010001) && (Instr[7:4] == 4'b0000);

    // Combinar condiciones para los muxes
    wire LongMullCondition = UMullCondition | SMullCondition_internal;
    wire FPCondition = FADDCondition | FMULCondition;

    // PC Register
    flopenr #(32) pcreg (
        .clk(clk),
        .reset(reset),
        .en(PCWrite),
        .d(Result),
        .q(PC)
    );

    // Dirección para memoria
    mux2 #(32) adrmux (
        .d0(PC),
        .d1(Result),
        .s(AdrSrc),
        .y(Adr)
    );

    // Registro de instrucción
    flopenr #(32) instreg (
        .clk(clk),
        .reset(reset),
        .en(IRWrite),
        .d(ReadData),
        .q(Instr)
    );

    // Registro de datos leídos de memoria
    flopr #(32) datareg (
        .clk(clk),
        .reset(reset),
        .d(ReadData),
        .q(Data)
    );

    // Multiplexores de lectura de registros (enteros)
    mux2 #(4) ra1mux (
        .d0(LongMullCondition ? Instr[3:0] : 
             MulCondition ? Instr[3:0] :
                            Instr[19:16]),
        .d1(4'b1111),
        .s(RegSrc[0]),
        .y(RA1)
    );

    mux2 #(4) ra2mux (
        .d0(LongMullCondition ? Instr[11:8] : 
             MulCondition ? Instr[11:8] :
                            Instr[3:0]),
        .d1(Instr[15:12]),
        .s(RegSrc[1]),
        .y(RA2)
    );

    // Registro de escritura (corregido para alternar entre RdLo y RdHi en UMULL)
    assign WA3 = LongMullCondition ?
                 (UMullState ? Instr[15:12] : Instr[19:16]) :
                 (MulCondition ? Instr[19:16] : Instr[15:12]);

    // Banco de registros enteros
    regfile rf (
        .clk(clk),
        .we3(RegWrite),
        .ra1(RA1),
        .ra2(RA2),
        .wa3(WA3),
        .wd3(Result),
        .r15(Result),
        .rd1(RD1),
        .rd2(RD2)
    );

    // Multiplexores para registros de punto flotante
    // Para instrucciones FP, usamos los campos de la instrucción para direccionar registros S
    assign FPRA1 = {1'b0, Instr[19:16]};  // Rs -> S(Rs)
    assign FPRA2 = {1'b0, Instr[3:0]};    // Rm -> S(Rm)
    assign FPWA3 = {1'b0, Instr[15:12]};  // Rd -> S(Rd)

    // Banco de registros de punto flotante (S0-S31)
    fpregfile fprf (
        .clk(clk),
        .we3(FPRegWrite),
        .ra1(FPRA1),
        .ra2(FPRA2),
        .wa3(FPWA3),
        .wd3(FPUOut),
        .rd1(FPUSrcAData),
        .rd2(FPUSrcBData)
    );

    // Registros temporales para datos leídos (enteros)
    floprdual #(32) regdual (
        .clk(clk),
        .reset(reset),
        .d1(RD1),
        .d2(RD2),
        .q1(A),
        .q2(WriteData)
    );

    // Extensión de inmediato
    extend ext (
        .Instr(Instr[23:0]),
        .ImmSrc(ImmSrc),
        .ExtImm(ExtImm)
    );

    // Multiplexores para entradas del ALU
    mux2 #(32) srcamux (
        .d0(A),
        .d1(PC),
        .s(ALUSrcA),
        .y(SrcA)
    );

    mux3 #(32) srcbmux (
        .d0(WriteData),
        .d1(ExtImm),
        .d2(32'd4),
        .s(ALUSrcB),
        .y(SrcB)
    );

    // ALU
    alu alu_inst (
        .SrcA(SrcA),
        .SrcB(SrcB),
        .ALUControl(ALUControl),
        .SMullCondition(SMullCondition),
        .ALUResult(ALUResult),
        .ALUFlags(ALUFlags)
    );

    // Registro de salida del ALU
    flopr #(32) aluoutreg (
        .clk(clk),
        .reset(reset),
        .d(ALUResult),
        .q(ALUOut)
    );

    // FPU
    fpu fpu_inst (
        .SrcA(FPUSrcAData),
        .SrcB(FPUSrcBData),
        .FPUControl(FPUControl),
        .FPUResult(FPUResult),
        .FPUFlags(FPUFlags)
    );

    // Registro de salida del FPU
    flopr #(32) fpuoutreg (
        .clk(clk),
        .reset(reset),
        .d(FPUResult),
        .q(FPUOut)
    );

    // Selección de resultado para escribir en registro
    mux3 #(32) resultmux (
        .d0(ALUOut),
        .d1(Data),
        .d2(ALUResult),
        .s(ResultSrc),
        .y(Result)
    );

endmodule