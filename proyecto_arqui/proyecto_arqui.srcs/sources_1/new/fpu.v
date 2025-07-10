`timescale 1ns / 1ps

module fpu(
    input  [31:0] SrcA, SrcB,
    input  [2:0]  FPUControl,
    output reg [31:0] FPUResult,
    output wire [3:0] FPUFlags
);
    // IEEE 754 Breakdown
    wire signA, signB;
    wire [7:0] expA, expB;
    wire [22:0] mantA, mantB;
    wire [23:0] mantA_norm, mantB_norm;
    wire [47:0] mult_result;
    wire [7:0] exp_diff;
    wire [23:0] mantA_shifted, mantB_shifted;
    wire [24:0] add_result;
    wire [8:0] exp_sum_pre;

    // Extra logic
    assign signA  = SrcA[31];
    assign expA   = SrcA[30:23];
    assign mantA  = SrcA[22:0];
    assign mantA_norm = (expA == 8'b0) ? {1'b0, mantA} : {1'b1, mantA};

    assign signB  = SrcB[31];
    assign expB   = SrcB[30:23];
    assign mantB  = SrcB[22:0];
    assign mantB_norm = (expB == 8'b0) ? {1'b0, mantB} : {1'b1, mantB};

    assign mult_result = mantA_norm * mantB_norm;
    assign exp_sum_pre = expA + expB - 8'd127;

    assign exp_diff = (expA > expB) ? (expA - expB) : (expB - expA);
    assign mantA_shifted = (expA >= expB) ? mantA_norm : (mantA_norm >> exp_diff);
    assign mantB_shifted = (expA >= expB) ? (mantB_norm >> exp_diff) : mantB_norm;

    assign add_result = (signA == signB) ?
                        (mantA_shifted + mantB_shifted) :
                        (mantA_shifted > mantB_shifted) ?
                        (mantA_shifted - mantB_shifted) :
                        (mantB_shifted - mantA_shifted);

    always @(*) begin
        case (FPUControl)
            3'b000: begin // FADD
                if (expA == 8'hFF || expB == 8'hFF) begin
                    FPUResult = 32'h7FC00000; // NaN
                end else if (expA == 8'h00 && mantA == 0) begin
                    FPUResult = SrcB;
                end else if (expB == 8'h00 && mantB == 0) begin
                    FPUResult = SrcA;
                end else begin
                    if (signA == signB) begin
                        FPUResult[31] = signA;
                        FPUResult[30:23] = (expA >= expB) ? expA + add_result[24] : expB + add_result[24];
                        FPUResult[22:0]  = add_result[24] ? add_result[23:1] : add_result[22:0];
                    end else begin
                        FPUResult[31] = (expA > expB) ? signA :
                                        (expB > expA) ? signB :
                                        (mantA_shifted > mantB_shifted) ? signA : signB;
                        FPUResult[30:23] = (expA >= expB) ? expA : expB;
                        FPUResult[22:0]  = add_result[22:0];
                    end
                end
            end

            3'b001: begin // FMUL
                if (expA == 8'hFF || expB == 8'hFF) begin
                    FPUResult = 32'h7FC00000; // NaN
                end else if ((expA == 8'h00 && mantA == 0) || (expB == 8'h00 && mantB == 0)) begin
                    FPUResult = 32'h00000000; // Zero
                end else begin
                    FPUResult[31] = signA ^ signB;
                    if (mult_result[47]) begin
                        FPUResult[30:23] = exp_sum_pre + 1;
                        FPUResult[22:0]  = mult_result[46:24];
                    end else begin
                        FPUResult[30:23] = exp_sum_pre;
                        FPUResult[22:0]  = mult_result[45:23];
                    end
                end
            end

            default: FPUResult = 32'h00000000;
        endcase
    end

    // Flags: [N Z C V]
    assign FPUFlags[3] = FPUResult[31];                      // N (Negative)
    assign FPUFlags[2] = (FPUResult[30:0] == 31'h0);         // Z (Zero)
    assign FPUFlags[1] = 1'b0;                               // C (not used)
    assign FPUFlags[0] = 1'b0;                               // V (not used)
endmodule
