module opm
    #(parameter DATA_OPM_SZ = 16,  // data width in RAM 
      parameter ADDR_OPM_SZ = 4)   // addr width in RAM 
    (CLK, I_WE, I_ADDR_OPM, I_DATA_WR_OPM, 
     O_DATA, O_ADDR);
  
    
//  input signals
    input wire CLK;                             // clock 50 MHz
    input wire I_WE;                            // RAM write enable signal 
    input wire [ADDR_OPM_SZ-1:0] I_ADDR_OPM;    // word addr in RAM
    input wire [DATA_OPM_SZ-1:0] I_DATA_WR_OPM; // word to write to RAM
//  output signals    
    output [DATA_OPM_SZ-1:0] O_DATA;
    output [ADDR_OPM_SZ-1:0] O_ADDR;
//  internal signals
    reg [DATA_OPM_SZ-1:0] op_ram[0:2**ADDR_OPM_SZ-1]; // one port memory
    reg [ADDR_OPM_SZ-1:0] addr_reg;

//  write operation 
    always @(posedge CLK) begin
      if (I_WE)
        op_ram[I_ADDR_OPM] <= I_DATA_WR_OPM;
      addr_reg <= I_ADDR_OPM;       
    end
    
//  read operation    
    assign O_ADDR = addr_reg;
    assign O_DATA = op_ram[addr_reg];
    
    
endmodule