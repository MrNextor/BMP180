module mult
    #(parameter DATA_ALU = 32) // data width
     (I_A, I_B, I_SG,
      O_RSL);


//  input signals
    input wire [DATA_ALU-1:0] I_A;  // srcA
    input wire [DATA_ALU-1:0] I_B;  // srcB
    input wire                I_SG; // singed mult
//  output signals
    output reg signed [DATA_ALU-1:0] O_RSL;  // result alu

    always @(*) begin
      if (I_SG)
        O_RSL = $signed(I_A) * $signed(I_B); // signed
      else
        O_RSL = I_A * I_B;                   // unsigned
    end
    
    
endmodule