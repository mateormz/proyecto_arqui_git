module extend (
    Instr,
    ImmSrc,
    ExtImm
);
    input wire [23:0] Instr;
    input wire [1:0] ImmSrc;
    output reg [31:0] ExtImm;
    
    wire [7:0] imm8;
    wire [3:0] rotate;
    wire [31:0] rotated_imm;
    wire [4:0] rotate_amount;
    
    assign imm8 = Instr[7:0];
    assign rotate = Instr[11:8];
    assign rotate_amount = rotate * 2;  // Cantidad de rotación
    
    // Implementar rotación circular a la derecha
    assign rotated_imm = ({24'b0, imm8} >> rotate_amount) | 
                        ({24'b0, imm8} << (32 - rotate_amount));
    
    always @(*)
        case (ImmSrc)
            2'b00: ExtImm = rotated_imm;
            2'b01: ExtImm = {20'b00000000000000000000, Instr[11:0]};
            2'b10: ExtImm = {{6 {Instr[23]}}, Instr[23:0], 2'b00};
            default: ExtImm = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        endcase
endmodule