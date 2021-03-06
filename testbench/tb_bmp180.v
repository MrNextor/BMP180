// command BMP180
    `define READ_CC   4'b0001 // reading calibration coefficients
    `define MSR_PRS0  4'b0010 // measurement pressure (OSS0)
    `define MSR_PRS1  4'b0011 // measurement pressure (OSS1)
    `define MSR_PRS2  4'b0100 // measurement pressure (OSS2)
    `define MSR_PRS3  4'b0101 // measurement pressure (OSS3)
    `define SOFT_RST  4'b0110 // soft reset BMP180
    `define CHECK     4'b0111 // check chip id BMP180
    `define MSR_TMP   4'b1000 // measurement temperature
    
    
`timescale 10 ns/ 1 ns
module tb_bmp180;
    parameter FPGA_CLK             = 50_000_000;           // FPGA frequency 50 MHz
    parameter I2C_CLK              = 100_000;              // I2C bus frequency 100 KHz     
    parameter ADDR_I2C_SZ          = 7;                    // addr on I2C bus width
    parameter DATA_I2C_SZ          = 8;                    // data on I2C bus width 
    parameter DATA_ROM_SZ          = 8;                    // word width in ROM    
    parameter ADDR_ROM_SZ          = 4;                    // addr width in ROM 
    parameter ADDR_OPM_SZ          = 4;                    // addr width in RAM 
    parameter DATA_OPM_SZ          = 16;                   // word width in RAM
    parameter FL_SZ                = 8;                    // command execution flag width
    parameter T_MSR_MX             = 0.0255;               // maximum conversion time 25,5 mS ((oss = 3)
    parameter integer N_CLK_MSR_MX = FPGA_CLK * T_MSR_MX;  // number of clocks 50 MHz (25,5 mS, 1_275_000 clk)
    parameter CNT_MSR_MX_SZ        = $clog2(N_CLK_MSR_MX); // conversion time counter width  
    parameter DATA_ALU             = 32;                   // data ALU width
    parameter DATA_DIV             = 33;                   // data div width 

    
    reg                        CLK;             // clock 50 MHz
    reg                        RST_n;           // asynchronous reset_n
    reg [ADDR_ROM_SZ-1:0]      I_COMM;          // command for BMP180  
    wire [ADDR_ROM_SZ-1:0]     addr_rom_o;      // word address in ROM     
    wire [DATA_ROM_SZ-1:0]     data_rom;        // word in ROM
    wire                       en_i2c;          // enable I2C bus  
    wire [ADDR_I2C_SZ-1:0]     addr_i2c;        // addr on I2C bus
    wire                       rw;              // RW I2C bus 
    wire [DATA_I2C_SZ-1:0]     data_wr_i2c;     // data for writing on I2C bus     
    wire                       IO_SCL;          // serial clock I2C bus 
    wire                       IO_SDA;          // serial data I2C bus    
    wire                       busy_i2c;        // master I2C busy signal
    wire                       en_cnt;          // I_EN counter     
    wire                       rst_cnt;         // reset counter
    wire [DATA_I2C_SZ-1:0]     data_rd_i2c;     // readed data from I2C bus
    wire [23:0]                rxd_buff;        // buffer of received data from BMP180   
    wire                       we;              // RAM write enable signal
    wire [ADDR_OPM_SZ-1:0]     addr_opm;        // word addr in RAM (output) 
    wire [DATA_OPM_SZ-1:0]     data_opm;        // word by addr in RAM (output)
    wire [DATA_ALU-1:0]        srcA;            // srcA
    wire [DATA_ALU-1:0]        srcB;            // srcB    
    wire [DATA_ALU-1:0]        rsl_alu;         // result alu
    wire                       en_div;          // enable devision
    wire [DATA_DIV-1:0]        num;             // numerator
    wire [DATA_DIV-1:0]        den;             // denomerator     
    wire                       fn_div;          // end of division
    wire signed [DATA_DIV-1:0] rsl_div;         // result division        
    wire [CNT_MSR_MX_SZ-1:0]   cnt;             // counter clock
    wire signed [15:0]         O_T_VALUE;       // current temperature
    wire signed [18:0]         O_P_VALUE;       // current pressure          
    wire [FL_SZ-1:0]           O_FL;            // command execution flag     
    wire                       O_ERR;           // chip id error (BMP180) or error state of FSM
    wire [4:0]                 O_CNT_RS_ERR;    // counter chip id error (BMP180) or error state of FSM 
    wire                       O_ACK_FL;        // flag in case of error on the bus   
    wire [4:0]                 O_CNT_RS_ACK_FL; // counter error ACK from BMP180
    reg                        en_sda_slv;      // enable signal to simulate input sda from the slave
    reg                        sda_slv;         // input sda from the slave
    reg [DATA_I2C_SZ-1:0]      CC;
    integer                    k;
    
    
    top_bmp180 dut
        (
         .CLK(CLK), 
         .RST_n(RST_n), 
         .I_COMM(I_COMM),
         .O_FL(O_FL),
         .O_T_VALUE(O_T_VALUE),
         .O_P_VALUE(O_P_VALUE),
         .O_ACK_FL(O_ACK_FL),
         .O_CNT_RS_ACK_FL(O_CNT_RS_ACK_FL),
         .O_ERR(O_ERR),
         .O_CNT_RS_ERR(O_CNT_RS_ERR),
         .IO_SCL(IO_SCL), 
         .IO_SDA(IO_SDA)
        );  

    assign IO_SDA = en_sda_slv ? sda_slv : 1'bz; 
    assign num = dut.num;
    assign den = dut.den;
    assign srcA = dut.srcA;
    assign srcB = dut.srcB;
    assign en_div = dut.en_div;
    assign fn_div = dut.fn_div;
    assign rsl_div = dut.rsl_div;
    assign data_rd_i2c = dut.data_rd_i2c;
    assign busy_i2c = dut.busy_i2c;
    assign addr_i2c = dut.addr_i2c;
    assign rw = dut.rw;
    assign data_wr_i2c = dut.data_wr_i2c;
    assign we = dut.we;
    assign en_i2c = dut.en_i2c;
    assign addr_opm = dut.addr_opm;
    assign data_opm = dut.data_opm;    
    assign addr_rom_o = dut.addr_rom_o;
    assign data_rom = dut.data_rom;
    assign rst_cnt = dut.rst_cnt;
    assign cnt = dut.cnt;
    assign en_cnt = dut.en_cnt;
    assign rsl_alu = dut.rsl_alu;
    assign rxd_buff = dut.rxd_buff;
    
    initial begin
      CLK = 1'b1;
      RST_n = 1'b1;
      en_sda_slv = 1'b0;
//    start reset
      #1; RST_n = 0;
//    stop reset
      #2; RST_n = 1;
      
//    start reading of calibration coefficients
      I_COMM = `READ_CC;
      #9251; en_sda_slv = 1'b1; sda_slv = 1'b0; // ACK from the slave that received the command   
      #1000; en_sda_slv = 1'b0;
      ack_data_ack_comm;                        // ACK from the slave that received bytes, ACK from the slave that received the command  
      // calibration coefficients reading process, the slave transmits 22 bytes
      CC = 8'h01; slv_tr_svr_bytes_1;           // 1
      CC = 8'h98; slv_tr_svr_bytes_1;           // 152; AC1
      CC = 8'hFF; slv_tr_svr_bytes_1;           // 255
      CC = 8'hB8; slv_tr_svr_bytes_1;           // 184; AC2
      CC = 8'hC7; slv_tr_svr_bytes_1;           // 199
      CC = 8'hD1; slv_tr_svr_bytes_1;           // 209; AC3
      CC = 8'h7F; slv_tr_svr_bytes_1;           // 127
      CC = 8'hE5; slv_tr_svr_bytes_1;           // 229; AC4
      CC = 8'h7F; slv_tr_svr_bytes_1;           // 127
      CC = 8'hF5; slv_tr_svr_bytes_1;           // 245; AC5
      CC = 8'h5A; slv_tr_svr_bytes_1;           // 90
      CC = 8'h71; slv_tr_svr_bytes_1;           // 113; AC6
      CC = 8'h18; slv_tr_svr_bytes_1;           // 24
      CC = 8'h2E; slv_tr_svr_bytes_1;           // 46; B1
      CC = 8'h00; slv_tr_svr_bytes_1;           // 0
      CC = 8'h04; slv_tr_svr_bytes_1;           // B2
      CC = 8'h80; slv_tr_svr_bytes_1;           // 128
      CC = 8'h00; slv_tr_svr_bytes_1;           // 0; MB
      CC = 8'hDD; slv_tr_svr_bytes_1;           // 221
      CC = 8'hF9; slv_tr_svr_bytes_1;           // 249; MC
      CC = 8'h0B; slv_tr_svr_bytes_1;           // 11
      CC = 8'h34; slv_tr_svr_bytes_1;           // 52; MD
      en_sda_slv = 1'b0;  
//    end reading of calibration coefficients      

//    start reading of pressure (oss = 0)              
      I_COMM = `MSR_PRS0;     
      // start reading of temperature      
      ack_two_ack;                                // ACK from the slave that received the command, two ACK from the slave that received two bytes
      // restart      
      #461000; en_sda_slv = 1'b1; sda_slv = 1'b0; // ACK from the slave that received the command  
      #1000; en_sda_slv = 1'b0;         
      ack_data_ack_comm;                          // ACK from the slave that received bytes, ACK from the slave that received the command      
      CC = 8'h6D; slv_tr_svr_bytes_1; 
      CC = 8'hFA; slv_tr_svr_bytes_1;
      en_sda_slv = 1'b0;
      // end reading of temperature
      // reading of pressure   
      ack_two_ack;                                // ACK from the slave that received the command, two ACK from the slave that received two bytes
      // restart
      #461000; en_sda_slv = 1'b1; sda_slv = 1'b0; // ACK from the slave that received the command  
      #1000; en_sda_slv = 1'b0;         
      ack_data_ack_comm;                          // ACK from the slave that received bytes, ACK from the slave that received the command        
      CC = 8'h5D; slv_tr_svr_bytes_1;             
      CC = 8'h23; slv_tr_svr_bytes_1;             
      CC = 8'h00; slv_tr_svr_bytes_1;               
      en_sda_slv = 1'b0;           
//    end reading of pressure (oss = 0)

//    start reading of pressure (oss = 1)
      I_COMM = `MSR_PRS1;     
      // start reading of temperature      
      ack_two_ack;                                // ACK from the slave that received the command, two ACK from the slave that received two bytes
      // restart      
      #461000; en_sda_slv = 1'b1; sda_slv = 1'b0; // ACK from the slave that received the command  
      #1000; en_sda_slv = 1'b0;         
      ack_data_ack_comm;                          // ACK from the slave that received bytes, ACK from the slave that received the command      
      CC = 8'h6D; slv_tr_svr_bytes_1; 
      CC = 8'hFA; slv_tr_svr_bytes_1;
      en_sda_slv = 1'b0;
      // end reading of temperature
      // reading of pressure       
      ack_two_ack;                                // ACK from the slave that received the command, two ACK from the slave that received two bytes
      // restart
      #761000; en_sda_slv = 1'b1; sda_slv = 1'b0; // ACK from the slave that received the command  
      #1000; en_sda_slv = 1'b0;         
      ack_data_ack_comm;                          // ACK from the slave that received bytes, ACK from the slave that received the command        
      CC = 8'h5D; slv_tr_svr_bytes_1;             
      CC = 8'h23; slv_tr_svr_bytes_1;             
      CC = 8'h00; slv_tr_svr_bytes_1;     
      en_sda_slv = 1'b0; 
//    end reading of pressure (oss = 1)

//    start reading of pressure (oss = 2)
      I_COMM = `MSR_PRS2;     
      // start reading of temperature      
      ack_two_ack;                                // ACK from the slave that received the command, two ACK from the slave that received two bytes
      // restart      
      #461000; en_sda_slv = 1'b1; sda_slv = 1'b0; // ACK from the slave that received the command  
      #1000; en_sda_slv = 1'b0;         
      ack_data_ack_comm;                          // ACK from the slave that received bytes, ACK from the slave that received the command      
      CC = 8'h6D; slv_tr_svr_bytes_1; 
      CC = 8'hFA; slv_tr_svr_bytes_1;
      en_sda_slv = 1'b0;
      // end reading of temperature
      // reading of pressure       
      ack_two_ack;                                 // ACK from the slave that received the command, two ACK from the slave that received two bytes    
      // restart
      #1361000; en_sda_slv = 1'b1; sda_slv = 1'b0; // ACK from the slave that received the command  
      #1000; en_sda_slv = 1'b0;         
      ack_data_ack_comm;                          // ACK from the slave that received bytes, ACK from the slave that received the command        
      CC = 8'h5D; slv_tr_svr_bytes_1;             
      CC = 8'h23; slv_tr_svr_bytes_1;             
      CC = 8'h00; slv_tr_svr_bytes_1;      
      en_sda_slv = 1'b0; 
//    end reading of pressure (oss = 2)

//    start reading of pressure (oss = 3)
      I_COMM = `MSR_PRS3;     
      // start reading of temperature      
      ack_two_ack;                                // ACK from the slave that received the command, two ACK from the slave that received two bytes
      // restart      
      #461000; en_sda_slv = 1'b1; sda_slv = 1'b0; // ACK from the slave that received the command  
      #1000; en_sda_slv = 1'b0;         
      ack_data_ack_comm;                          // ACK from the slave that received bytes, ACK from the slave that received the command      
      CC = 8'h6D; slv_tr_svr_bytes_1; 
      CC = 8'hFA; slv_tr_svr_bytes_1;
      en_sda_slv = 1'b0;
      // end reading of temperature
      // reading of pressure     
      ack_two_ack;                                // ACK from the slave that received the command, two ACK from the slave that received two bytes       
      // restart
      #2561000; en_sda_slv = 1'b1; sda_slv = 1'b0; // ACK from the slave that received the command  
      #1000; en_sda_slv = 1'b0;         
      ack_data_ack_comm;                          // ACK from the slave that received bytes, ACK from the slave that received the command        
      CC = 8'h5D; slv_tr_svr_bytes_1;             
      CC = 8'h23; slv_tr_svr_bytes_1;             
      CC = 8'h00; slv_tr_svr_bytes_1;      
      en_sda_slv = 1'b0;  
//    end reading of pressure (oss = 3)

//    start soft reset 
      I_COMM = `SOFT_RST;      
      ack_two_ack;                                // ACK from the slave that received the command, two ACK from the slave that received two bytes
//    end soft reset 

//    start communication check (1)
      I_COMM = `CHECK; 
      #11000; en_sda_slv = 1'b1; sda_slv = 1'b0;  // ACK from the slave that received the command  
      #1000; en_sda_slv = 1'b0;         
      ack_data_ack_comm;                          // ACK from the slave that received bytes, ACK from the slave that received the command  
      CC = 8'h55; slv_tr_byte;                    // the slave transmits one byte     
//    stop communication check     

//    start communication check (2)
      I_COMM = `CHECK;
      #12000; en_sda_slv = 1'b1; sda_slv = 1'b0;  // ACK from the slave that received the command  
      #1000; en_sda_slv = 1'b0;         
      ack_data_ack_comm;                          // ACK from the slave that received bytes, ACK from the slave that received the command  
      CC = 8'hAA; slv_tr_byte;                    // the slave transmits one byte     
//    stop communication check 

      I_COMM = 4'h0; // waiting for command 
    end   
    
    always #1 CLK = ~CLK;
    
    // initial begin
      // $dumpvars;
    // end

    initial 
    #8000000 $finish;
    
//  ACK from the slave that received bytes, ACK from the slave that received the command    
    task automatic ack_data_ack_comm; 
      begin
          #8000; en_sda_slv = 1'b1; sda_slv = 1'b0; //  ACK from the slave that received bytes
          #1000; en_sda_slv = 1'b0; 
          #11000; en_sda_slv = 1'b1; sda_slv = 1'b0; // ACK from the slave that received the command   
          #1000;         
      end
    endtask
    
//  ACK from the slave that received the command, two ACK from the slave that received two bytes
    task automatic ack_two_ack; 
      begin
          #11000; en_sda_slv = 1'b1; sda_slv = 1'b0; // ACK from the slave that received the command
          #1000; en_sda_slv = 1'b0;  
          repeat (2) //  two ACK from the slave that received two bytes 
            begin
              #8000; en_sda_slv = 1'b1; sda_slv = 1'b0; 
              #1000; en_sda_slv = 1'b0; 
            end          
      end
    endtask
    
//  the slave transmits one byte    
    task automatic slv_tr_byte; 
      begin
          for (k=7; k>=0; k=k-1)
            begin
              sda_slv = CC[k];
              #1000;
            end
          en_sda_slv = 1'b0; 
      end
    endtask 
    
//  the slave transmits several bytes    
    task automatic slv_tr_svr_bytes_1; 
      begin
          slv_tr_byte; // the slave transmits one byte
          #1000; en_sda_slv = 1'b1;       
      end
    endtask     


endmodule    