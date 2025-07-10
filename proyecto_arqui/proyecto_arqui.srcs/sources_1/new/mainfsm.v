module mainfsm (
    clk,
    reset,
    Op,
    Funct,
    LongMullCondition,
    FPCondition,
    IRWrite,
    AdrSrc,
    ALUSrcA,
    ALUSrcB,
    ResultSrc,
    NextPC,
    RegW,
    MemW,
    Branch,
    ALUOp,
    UMullState,
    FPUOp
);
    input wire clk;
    input wire reset;
    input wire [1:0] Op;
    input wire [5:0] Funct;
    input wire LongMullCondition;
    input wire FPCondition;
    output wire IRWrite;
    output wire AdrSrc;
    output wire [1:0] ALUSrcA;
    output wire [1:0] ALUSrcB;
    output wire [1:0] ResultSrc;
    output wire NextPC;
    output wire RegW;
    output wire MemW;
    output wire Branch;
    output wire ALUOp;
    output wire UMullState;
    output wire FPUOp;
    
    reg [3:0] state;
    reg [3:0] nextstate;
    reg [13:0] controls;  // Aumentado para incluir FPUOp
    
    localparam [3:0] FETCH = 0;
    localparam [3:0] DECODE = 1;
    localparam [3:0] MEMADR = 2;
    localparam [3:0] MEMRD = 3;
    localparam [3:0] MEMWB = 4;
    localparam [3:0] MEMWR = 5;
    localparam [3:0] EXECUTER = 6;
    localparam [3:0] EXECUTEI = 7;
    localparam [3:0] ALUWB = 8;
    localparam [3:0] BRANCH = 9;
    localparam [3:0] UMULL1 = 10;
    localparam [3:0] UMULL2 = 11;
    localparam [3:0] FPEXECUTE = 12;  // Nuevo estado para FPU
    localparam [3:0] UNKNOWN = 13;
    
    // Señal para indicar si estamos en el segundo ciclo de UMULL
    assign UMullState = (state == UMULL1);
    
    always @(posedge clk or posedge reset)
        if (reset)
            state <= FETCH;
        else
            state <= nextstate;
    
    always @(*)
        casex (state)
            FETCH: nextstate = DECODE;
            DECODE:
                case (Op)
                    2'b00: begin
                        if (LongMullCondition)
                            nextstate = EXECUTER;
                        else if (Funct[5])
                            nextstate = EXECUTEI;
                        else
                            nextstate = EXECUTER;
                    end
                    2'b01: nextstate = MEMADR;
                    2'b10: nextstate = BRANCH;
                    2'b11: begin
                        if (FPCondition)
                            nextstate = FPEXECUTE;
                        else
                            nextstate = UNKNOWN;
                    end
                    default: nextstate = UNKNOWN;
                endcase
            EXECUTER: begin
                if (LongMullCondition)
                    nextstate = UMULL1;
                else
                    nextstate = ALUWB;
            end
            EXECUTEI: nextstate = ALUWB;
            FPEXECUTE: nextstate = FETCH;  // Las operaciones FPU toman 1 ciclo
            UMULL1: nextstate = UMULL2;
            UMULL2: nextstate = FETCH;
            MEMADR:
                if (Funct[0])
                    nextstate = MEMRD;
                else
                    nextstate = MEMWR;
            MEMRD: nextstate = MEMWB;
            MEMWB: nextstate = FETCH;
            MEMWR: nextstate = FETCH;
            ALUWB: nextstate = FETCH;
            BRANCH: nextstate = FETCH;
            default: nextstate = FETCH;
        endcase
    
    always @(*)
        case (state)
            FETCH:     controls = 14'b1_0_0_0_1_0_10_01_10_0_0;
            DECODE:    controls = 14'b0_0_0_0_0_0_10_01_10_0_0;
            EXECUTER:  controls = 14'b0_0_0_0_0_0_00_00_00_1_0;
            EXECUTEI:  controls = 14'b0_0_0_0_0_0_00_00_01_1_0;
            ALUWB:     controls = 14'b0_0_0_1_0_0_00_00_00_0_0;
            FPEXECUTE: controls = 14'b0_0_0_0_0_0_00_00_00_0_1;  // FPUOp = 1
            UMULL1:    controls = 14'b0_0_0_1_0_0_10_00_00_1_0;
            UMULL2:    controls = 14'b0_0_0_1_0_0_10_00_00_0_0;
            MEMADR:    controls = 14'b0_0_0_0_0_0_00_00_01_1_0;
            MEMWR:     controls = 14'b0_0_1_0_0_1_00_00_00_0_0;
            MEMRD:     controls = 14'b0_0_0_0_0_1_00_00_00_0_0;
            MEMWB:     controls = 14'b0_0_0_1_0_0_01_00_00_0_0;
            BRANCH:    controls = 14'b0_1_0_0_0_0_10_10_01_0_0;
            default:   controls = 14'bxxxxxxxxxxxxxx;
        endcase
        
    assign {NextPC, Branch, MemW, RegW, IRWrite, AdrSrc, ResultSrc, ALUSrcA, ALUSrcB, ALUOp, FPUOp} = controls;
endmodule