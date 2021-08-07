`timescale 10 ns/ 1 ns
module tb_i2c_master;
    parameter FPGA_CLK = 50_000_000; // FPGA frequency 50 MHz
    parameter I2C_CLK  = 400_000;    // I2C bus frequency 100 KHz
    parameter ADDR_SZ  = 7;          // address widht
    parameter DATA_SZ  = 8;          // data widht

//--------------------------------------------------------------------------         
    reg                CLK;        // clock 50 MHz
    reg                RST_n;      // asynchronous reset_n
    wire               scl;        // serial clock from clk div
    wire               rs_pr_scl;  // rising edge prev_scl for sda
    wire               fl_pr_scl;  // falling edge prev_scl for sda
    reg                I_EN;       // I2C bus enable signal from cpu
    reg                I_RW;       // read or write command   
    reg [ADDR_SZ-1:0]  I_ADDR;     // slave address
    reg [DATA_SZ-1:0]  I_DATA_WR;  // data to write to the slave                                                               
    wire               IO_SCL;     // serial clock I2C bus
    wire               IO_SDA;     // serial data I2C bus
    wire               O_ACK_FL;   // flag in case of error
    wire [DATA_SZ-1:0] O_DATA_RD;  // readed data from the slave  
    wire               O_BUSY;     // master busy signal
    reg                en_sda_slv; // enable signal  sda from the slave
    reg                sda_slv;    // sda from the slave
    integer            k;     

//--------------------------------------------------------------------------     
    assign scl = dut.scl;
    assign rs_pr_scl = dut.rs_pr_scl;
    assign fl_pr_scl = dut.fl_pr_scl;
    assign IO_SDA = en_sda_slv ? sda_slv : 1'bz;        

//--------------------------------------------------------------------------     
    i2c_master dut 
        (  
         .CLK(CLK),
         .IO_SCL(IO_SCL),
         .IO_SDA(IO_SDA),
         .I_ADDR(I_ADDR),
         .I_DATA_WR(I_DATA_WR),
         .I_EN(I_EN),
         .I_RW(I_RW),
         .O_ACK_FL(O_ACK_FL),
         .O_BUSY(O_BUSY),
         .O_DATA_RD(O_DATA_RD),
         .RST_n(RST_n)
        ); 
     
    initial begin
      CLK = 1'b1;
      RST_n = 1'b1;
      en_sda_slv = 1'b0; sda_slv = 1'b1;
//    start reset
      #1; RST_n = 0;
//    stop reset
      #2; RST_n = 1;
    
//    start of transaction (writing one byte)
      I_EN = 1'b1;
      I_RW = 1'b0;    
      I_ADDR = 7'h77; 
      I_DATA_WR = 8'hAA;
      #2313; en_sda_slv = 1'b1; sda_slv = 1'b0; // ACK command
      #250; en_sda_slv = 1'b0; sda_slv = 1'b1;      
      I_EN = 1'b0;  
      ack_data;
      
//    start of transaction (writing two bytes)
      #1250; I_EN = 1'b1;
      I_RW = 1'b0;
      I_ADDR = 7'h77; 
      I_DATA_WR = 8'hAA;
      ack_comm;
      I_DATA_WR = 8'hAB; 
      ack_data;
      I_EN = 1'b0;
      ack_data;      

//    start of transaction (reading one byte)
      #1250; I_EN = 1'b1;
      I_RW = 1'b1; 
      I_ADDR = 7'h77;
      ack_comm;
      I_EN = 1'b0;      
      slv_tx(8'h07);
      
//    start of transaction (reading two bytes)   
      #1250; I_EN = 1'b1;
      I_RW = 1'b1; 
      I_ADDR = 7'h77; 
      ack_comm;     
      slv_tx(8'hAA);
      I_EN = 1'b0;      
      slv_tx(8'hEE);
      
//    start of the fifth of transaction (writing one byte then restart and reading one byte)    
      #1250; I_EN = 1'b1;
      I_RW = 1'b0; 
      I_ADDR = 7'h77; 
      I_DATA_WR = 8'h0C; 
      ack_comm;   
      I_RW = 1'b1; 
      I_ADDR = 7'h55;       
      ack_data;
      ack_comm;        
      I_EN = 1'b0;      
      slv_tx(8'hAA);
        
//    start of the sixth of transaction (reading one byte, then restart and writing one byte)    
      #1250; I_EN = 1'b1;
      I_RW = 1'b1;
      I_ADDR = 7'h77; 
      ack_comm; 
      I_RW = 1'b0;    
      I_ADDR = 7'h55;
      I_DATA_WR = 8'hAA;       
      slv_tx(8'h88);
      ack_comm;
      I_EN = 1'b0;      
      ack_data;
    end   

//--------------------------------------------------------------------------     
    initial begin
      // $dumpvars;
      #51000 $finish;
    end

//--------------------------------------------------------------------------     
    always #1 CLK = ~CLK;

// --------------------------------------------------------------------------     
    task automatic ack_comm; 
      begin
          #2500; en_sda_slv = 1'b1; sda_slv = 1'b0;
          #250; en_sda_slv = 1'b0; sda_slv = 1'b1;      
      end
    endtask

// -------------------------------------------------------------------------- 
    task automatic ack_data;
      begin
        #2000; en_sda_slv = 1'b1; sda_slv = 1'b0; 
        #250; en_sda_slv = 1'b0; sda_slv = 1'b1;
      end
    endtask
    
// --------------------------------------------------------------------------  
    task automatic slv_tx; 
      input [7:0] data;
      begin    
          en_sda_slv = 1'b1;
          for (k=7; k>=0; k=k-1)
            begin
              sda_slv = data[k];
              #250;
            end
          en_sda_slv = 1'b0; sda_slv = 1'b1;
          #250;
      end
    endtask  
 
   
endmodule