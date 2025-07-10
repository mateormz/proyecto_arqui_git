module decode (
    clk,
    reset,
    Op,
    Funct,
    Rd,
    InstrLow,
    UMullState,
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
    ALUControl,
    UMullCondition,
    SMullCondition,
    // Nuevas se�ales para FPU
    FPUOp,
    FPRegWrite,
    FPUSrcA,
    FPUSrcB,
    FPUControl
);
    input wire clk;
    input wire reset;
    input wire [1:0] Op;
    input wire [5:0] Funct;
    input wire [3:0] Rd;
    input wire [3:0] InstrLow;
    input wire UMullState;
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
    output reg [3:0] ALUControl;
    output wire UMullCondition;
    output wire SMullCondition;
    
    // Nuevas salidas para FPU
    output wire FPUOp;
    output wire FPRegWrite;
    output wire [1:0] FPUSrcA;
    output wire [1:0] FPUSrcB;
    output wire [2:0] FPUControl;
    
    wire Branch;
    wire ALUOp;
    wire MulCondition;
    wire FADDCondition;
    wire FMULCondition;
    
    // Detectar cuando Op=00 (bits 27:26) y Funct[5:2]=0000 (bits 25:22) y InstrLow=1001
    assign MulCondition = (Op == 2'b00) && (Funct[5:1] == 5'b00000) && (InstrLow == 4'b1001);
    
    assign UMullCondition = (Op == 2'b00) && (Funct[5:1] == 5'b00100) && (InstrLow == 4'b1001);
    
    assign SMullCondition = (Op == 2'b00) && (Funct[5:1] == 5'b00110) && (InstrLow == 4'b1001);

    // Detectar instrucciones de punto flotante
    // NO ESTA ASI FADD: Op=11, Funct[5:4]=00, Funct[3:0]=0000, InstrLow=1010
    // VADD: Op=11 (bits 27:26), Funct[5:4]=11 (bits 25:24), Funct[3:2]=00 (bits 23:22), InstrLow[3:0]=1010
    assign FADDCondition = (Op == 2'b11) && (Funct[5:4] == 2'b11) && (Funct[3:2] == 2'b00) && (InstrLow == 4'b1010);
    
    // NO ESTA ASI FMUL: Op=11, Funct[5:4]=00, Funct[3:0]=0000, InstrLow=1001
    // VMUL: Op=11 (bits 27:26), Funct[5:4]=11 (bits 25:24), Funct[3:2]=10 (bits 23:22), InstrLow[3:0]=1010
    assign FMULCondition = (Op == 2'b11) && (Funct[5:4] == 2'b11) && (Funct[3:2] == 2'b10) && (InstrLow == 4'b1010);
    // Combinar condiciones de multiplicaci�n larga
    wire LongMullCondition = UMullCondition | SMullCondition;
    
    // Combinar condiciones de punto flotante
    wire FPCondition = FADDCondition | FMULCondition;
    
    mainfsm fsm(
        .clk(clk),
        .reset(reset),
        .Op(Op),
        .Funct(Funct),
        .LongMullCondition(LongMullCondition),
        .FPCondition(FPCondition),
        .IRWrite(IRWrite),
        .AdrSrc(AdrSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ResultSrc(ResultSrc),
        .NextPC(NextPC),
        .RegW(RegW),
        .MemW(MemW),
        .Branch(Branch),
        .ALUOp(ALUOp),
        .UMullState(UMullState),
        .FPUOp(FPUOp)
    );
    
    assign ImmSrc = Op;
    
    assign RegSrc[1] = Op == 2'b01; 
    assign RegSrc[0] = Op == 2'b10;
    
    // Se�ales para FPU
    assign FPRegWrite = FPUOp;
    assign FPUSrcA = 2'b00;  // Siempre desde registro FP
    assign FPUSrcB = 2'b00;  // Siempre desde registro FP
    assign FPUControl = FADDCondition ? 3'b000 : 
                       FMULCondition ? 3'b001 : 3'b000;
    
    always @(*) begin
        if (ALUOp) begin
            // Primero verificar si es una operaci�n UMULL
            if (LongMullCondition) begin  // UMULL o SMULL
                ALUControl = UMullState ? 4'b0111 : 4'b0110;  // 111 para parte alta, 110 para parte baja
            end
            // Luego verificar si es una operaci�n MUL
            else if (MulCondition) begin
                ALUControl = 4'b0101;  // C�digo para MUL
            end else begin
                case (Funct[4:1])
                    4'b0100: ALUControl = 4'b0000;  // ADD
                    4'b0010: ALUControl = 4'b0001;  // SUB
                    4'b0000: ALUControl = 4'b0010;  // AND
                    4'b1100: ALUControl = 4'b0011;  // ORR
                    4'b1101: ALUControl = 4'b0100;  // MOV
                    4'b0011: ALUControl = 4'b1000;  // DIV
                    default: ALUControl = 4'bxxxx;
                endcase
            end
            
            // Configuraci�n de FlagW
            if (LongMullCondition) begin
                FlagW[1] = Funct[0] & UMullState;  // S bit para UMULL, solo en segundo ciclo
                FlagW[0] = 1'b0;                   // UMULL no afecta carry flag
            end else if (MulCondition) begin
                FlagW[1] = Funct[0];  // S bit para MUL
                FlagW[0] = 1'b0;      // MUL no afecta carry flag
            end else begin
                FlagW[1] = Funct[0];
                FlagW[0] = Funct[0] & ((ALUControl == 4'b0000) | (ALUControl == 4'b0001));
            end
        end
        else begin
            ALUControl = 4'b0000;
            FlagW = 2'b00;
        end
    end
    
    assign PCS = ((Rd == 4'b1111) & RegW) | Branch;
endmodule