module clk_div_msrmnt 
    #(parameter FPGA_CLK = 50_000_000,                      // FPGA frequency 50 MHz
      parameter T_MSR_MX  = 0.0255,                         // maximum conversion time 25,5 mS 
      parameter integer N_CLK_MSR_MX = FPGA_CLK * T_MSR_MX, // number of clocks 50 MHz
      parameter CNT_MSR_MX_SZ = $clog2(N_CLK_MSR_MX))       // counter width
    (CLK, RST_n, I_EN, I_RST, 
     O_CNT);
    

//  input signals    
    input wire CLK;   // clock 50 MHz
    input wire RST_n; // asynchronous reset_n
    input wire I_EN;  // I_EN counter
    input wire I_RST; // reset counter
//  output signals
    output reg [CNT_MSR_MX_SZ-1:0] O_CNT; // counter clock    
 
//  counter clk 
    always @(posedge CLK or negedge RST_n) begin
      if (!RST_n)
        O_CNT     <= {CNT_MSR_MX_SZ{1'b0}};
      else
        begin
          if (I_EN)
            O_CNT <= O_CNT + 1'b1;
          else if (I_RST)
            O_CNT <= {CNT_MSR_MX_SZ{1'b0}};
        end
    end

    
endmodule