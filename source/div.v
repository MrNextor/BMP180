module div
    #(parameter DATA_DIV = 3'd4) // data width
    (CLK, I_EN, I_NUM, I_DEN, 
     O_RSL, O_REM, O_FN);


    localparam CNT_SZ = $clog2(DATA_DIV);   // counter width
//  input signals
    input wire                       CLK;   // clock 50 MHz
    input wire                       I_EN;  // start devision
    input wire signed [DATA_DIV-1:0] I_NUM; // numerator
    input wire signed [DATA_DIV-1:0] I_DEN; // denomerator
// output signals
    output reg signed [DATA_DIV-1:0] O_RSL; // result
    output reg [DATA_DIV-1:0]        O_REM; // remainder
    output reg                       O_FN;  // end of division
//  internal signals
    reg [CNT_SZ-1:0]           cnt;     // iteration counter
    reg                        start;   // start for 2-32 iteration
    wire [DATA_DIV-1:0]        num_uns; // numerator is unsigned
    wire [DATA_DIV-1:0]        den_uns; // denomerator is unsigned
    wire [DATA_DIV-1:0]        res31;   // shift 31 bit I_NUM (unsigned)
    wire                       carry31; // carry for 31 bit
    wire signed [DATA_DIV-1:0] sub31;   // result sub I_NUM[31] (unsigned) and I_DEN (unsigned)
    reg [DATA_DIV-1:0]         rem_reg; // remainder register
    reg [DATA_DIV-1:0]         num_reg; // shift num_uns
    wire [DATA_DIV-1:0]        pr_res;
    wire                       carry;   // carry for 0-30 bit 
    wire signed [DATA_DIV-1:0] sub; 
    reg [DATA_DIV-1:0]         rsl_reg; // result register

//--------------------------------------------------------------------------     
    assign num_uns = I_NUM[DATA_DIV-1] ? (~I_NUM + 1'b1) : I_NUM; // conversion numerator in unsigned
    assign den_uns = I_DEN[DATA_DIV-1] ? (~I_DEN + 1'b1) : I_DEN; // conversion denomerator in unsigned
    assign res31 = {{DATA_DIV-1{1'b0}}, num_uns[DATA_DIV-1]};     // shift 31 bit numerator (unsigned)
    assign {carry31, sub31} = $signed(res31) - $signed(den_uns);  // result sub I_NUM[31] (unsigned) and I_DEN (unsigned)
    assign pr_res = {rem_reg[DATA_DIV-2:0], num_reg[DATA_DIV-1]};
    assign {carry, sub} = $signed(pr_res) - $signed(den_uns);

//--------------------------------------------------------------------------     
    always @(posedge CLK) begin
      if (start)
        begin
          cnt     <= cnt - 1'b1;
          rsl_reg <= {rsl_reg[DATA_DIV-2:0], !carry};
          num_reg <= num_reg << 1'b1;
          rem_reg <= carry ? pr_res : sub;
        end
      else if (I_EN)
        begin
          cnt     <= DATA_DIV - 1'b1;
          start   <= 1'b1;
          rsl_reg <= {{DATA_DIV-1{1'b0}}, !carry31};
          rem_reg <= carry31 ? res31 : sub31;
          num_reg <= num_uns << 1'b1;
          O_FN    <= 1'b0;
        end           
//--------------------------------------------------------------------------           
      if (&(!cnt))      
        begin
          O_RSL <= (I_NUM[DATA_DIV-1] ^ I_DEN[DATA_DIV-1]) ? (~rsl_reg + 1'b1) : rsl_reg;
          O_REM <= rem_reg;
          start <= 1'b0;
          O_FN  <= 1'b1;
        end
    end


endmodule 