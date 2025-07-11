module mainfsm (
    clk,
    reset,
    Op,
    Funct,
    LongMullCondition,
    FloatCondition,  // NUEVA ENTRADA
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
    UMullState
);
    input wire clk;
    input wire reset;
    input wire [1:0] Op;
    input wire [5:0] Funct;
    input wire LongMullCondition;
    input wire FloatCondition;  // NUEVA ENTRADA
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
    
    reg [3:0] state;
    reg [3:0] nextstate;
    reg [12:0] controls;
    
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
    localparam [3:0] UNKNOWN = 12;
    
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
                    2'b11: begin  // NUEVA LÓGICA PARA OPERACIONES DE PUNTO FLOTANTE
                        if (FloatCondition)
                            nextstate = EXECUTER;  // Usar el mismo estado para operaciones aritméticas
                        else
                            nextstate = UNKNOWN;
                    end
                    default: nextstate = UNKNOWN;
                endcase
            EXECUTER: begin
                if (LongMullCondition)
                    nextstate = UMULL1;
                else  // Incluye operaciones de punto flotante
                    nextstate = ALUWB;
            end
            EXECUTEI: nextstate = ALUWB;
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
            FETCH:    controls = 13'b1_0_0_0_1_0_10_01_10_0;
            DECODE:   controls = 13'b0000001001100;
            EXECUTER: controls = 13'b0000000000001;
            EXECUTEI: controls = 13'b0000000000011;
            ALUWB:    controls = 13'b0001000000000;
            UMULL1:   controls = 13'b0001010000001;
            UMULL2:   controls = 13'b0001010000000;
            MEMADR:   controls = 13'b0000000000010;
            MEMWR:    controls = 13'b0010010000000;
            MEMRD:    controls = 13'b0000010000000;
            MEMWB:    controls = 13'b0001000100000;
            BRANCH:   controls = 13'b0_1_0_0_0_0_10_10_01_0;
            default:  controls = 13'bxxxxxxxxxxxxx;
        endcase
        
    assign {NextPC, Branch, MemW, RegW, IRWrite, AdrSrc, ResultSrc, ALUSrcA, ALUSrcB, ALUOp} = controls;
endmodule
