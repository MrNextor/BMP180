// commands for BMP180
//
// AA - reading calibration coefficients
//
// commands for register "Measurement Control"
// 2E - measurement temperature (conversion time = 4.5 mS)
// 34 - measurement pressure (conversion time = 4.5 mS)
// 74 - measurement pressure (conversion time = 7.5 mS)
// B4 - measurement pressure (conversion time = 13.5 mS) 
// F4 - measurement pressure (conversion time = 25.5 mS)
// 
// B6 - soft reset
// D0 - chip-id : This value is fixed in BMP180 to 0x55 and can be used to check whether communication is functioning

module rom
    #(parameter ADDR_ROM_SZ = 4,              // addr width in ROM 
      parameter DATA_ROM_SZ = 8)              // word width in ROM
    (CLK, I_ADDR_ROM, O_ADDR_ROM, O_DATA_ROM);
    
    
//  input signals    
    input wire                    CLK;        // clock 50 MHz
    input wire [ADDR_ROM_SZ-1:0]  I_ADDR_ROM; // word addr in ROM
//  output signals    
    output reg [DATA_ROM_SZ-1:0]  O_DATA_ROM; // word in ROM
    output wire [ADDR_ROM_SZ-1:0] O_ADDR_ROM; // word addr in ROM
//  internal signals
    reg [DATA_ROM_SZ-1:0] rom_array [0:2**ADDR_ROM_SZ-1]; // ROM array
    reg [ADDR_ROM_SZ-1:0] addr_reg; 
    
    
//-------------------------------------------------------------------------- 
    assign O_ADDR_ROM = addr_reg;
    
//  read ROM content from file
    initial begin
      $readmemh("../comm_bmp180.txt", rom_array); 
    end

//  read operation  
    always @(posedge CLK) begin
      addr_reg   <= I_ADDR_ROM;
      O_DATA_ROM <= rom_array[I_ADDR_ROM];
    end
    
    
endmodule