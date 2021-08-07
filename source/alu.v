// command ALU
    `define ALU_ADD   3'b000
    `define ALU_ADDU  3'b001
    `define ALU_SLL   3'b010
    `define ALU_SRL   3'b011
    `define ALU_SLTU  3'b100
    `define ALU_SUBU  3'b101
    `define ALU_SUB   3'b110
    `define ALU_SRA   3'b111
    

module alu
    #(parameter DATA_ALU = 32, // data width
      parameter OP_SZ = 3,     // aluControl width
      parameter SH_SZ = 5)     // shift width
     (I_A, I_B, I_OP, I_SH, 
      O_RSL);


//  input signals
    input wire [DATA_ALU-1:0] I_A;  // srcA
    input wire [DATA_ALU-1:0] I_B;  // srcB
    input wire [OP_SZ-1:0]    I_OP; // aluControl
    input wire [SH_SZ-1:0]    I_SH; // shift
//  output signals
    output reg signed [DATA_ALU-1:0] O_RSL; // result alu

//  operation alu
    always @ (*) begin
      case (I_OP)
         `ALU_ADD   : O_RSL = $signed(I_A) + $signed(I_B);
         `ALU_ADDU  : O_RSL = I_A + I_B;
         `ALU_SUB   : O_RSL = $signed(I_A) - $signed(I_B);
         `ALU_SUBU  : O_RSL = I_A - I_B;
         `ALU_SLL   : O_RSL = I_A << I_SH;
         `ALU_SRL   : O_RSL = I_A >> I_SH;
         `ALU_SRA   : O_RSL = $signed(I_A) >>> I_SH;
         `ALU_SLTU  : O_RSL = (I_A < I_B) ? 1 : 0;
         default    : O_RSL = I_A + I_B;
      endcase
    end
    
    
endmodule