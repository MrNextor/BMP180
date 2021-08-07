`timescale 10 ns/ 1 ns
module tb_div;
    parameter DATA_DIV = 4;
    parameter CNT_SZ = $clog2(DATA_DIV); // counter width
    
    
    reg                        CLK;     // clock 50 MHz
    reg                        I_EN;    // start devision
    reg signed [DATA_DIV-1:0]  I_NUM;   // numerator                                              
    reg signed [DATA_DIV-1:0]  I_DEN;   // denomerator
    wire signed [DATA_DIV-1:0] O_RSL;   // result
    wire [DATA_DIV-1:0]        O_REM;   // remainder
    wire                       O_FN;    // end of division 
    wire [CNT_SZ-1:0]          cnt;     // iteration counter
    wire [DATA_DIV-1:0]        num_uns; // numerator is unsigned
    wire [DATA_DIV-1:0]        den_uns; // denomerator is unsigned    
    wire [DATA_DIV-1:0]        rsl_reg; // result register 
    wire [DATA_DIV-1:0]        rem_reg; // remainder register
    wire [DATA_DIV-1:0]        num_reg; // shift num_uns
    wire                       start;   // start for 2-32 iteration
    wire                       carry31; // carry for 31 bit
    wire signed [DATA_DIV-1:0] sub31;   // result sub I_NUM[31] (unsigned) and I_DEN (unsigned)
    wire                       carry;   // carry for 0-30 bit 
    wire signed [DATA_DIV-1:0] pr_res;
    wire signed [DATA_DIV-1:0] sub;    
    
    
    assign num_uns = dut.num_uns;
    assign den_uns = dut.den_uns;
    assign rsl_reg = dut.rsl_reg;
    assign start = dut.start;
    assign rem_reg = dut.rem_reg;
    assign num_reg = dut.num_reg;
    assign cnt = dut.cnt;
    assign carry31 = dut.carry31;
    assign sub31 = dut.sub31;
    assign carry = dut.carry;
    assign sub = dut.sub;    
    assign pr_res = dut.pr_res;

    div dut 
        (
         .CLK(CLK), 
         .I_EN(I_EN), 
         .I_NUM(I_NUM), 
         .I_DEN(I_DEN), 
         .O_RSL(O_RSL), 
         .O_REM(O_REM), 
         .O_FN(O_FN)
        );
    
    initial begin
      CLK = 1'b1;
      I_EN = 1'b0;
      I_NUM = -4'd6;
      I_DEN = 4'd2;
      #1; I_EN = 1'b1;
      #2; I_EN = 1'b0;
      #8; I_EN = 1'b1;
      I_NUM = 4'd7;
      I_DEN = -4'd2;
      #2; I_EN = 1'b0;
      #8; I_EN = 1'b1;
      I_NUM = -4'd4;
      I_DEN = - 4'd2;
      #2; I_EN = 1'b0;
      #8; I_EN = 1'b1;
      I_NUM = 4'd3;
      I_DEN = 4'd1;
      #2; I_EN = 1'b0;
    end

    always #1 CLK = ~CLK;
    
    initial
    #70 $finish;
    
endmodule