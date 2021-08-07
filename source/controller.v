// command BMP180
    `define READ_CC   4'b0001 // reading calibration coefficients
    `define MSR_PRS0  4'b0010 // measurement pressure (OSS0)
    `define MSR_PRS1  4'b0011 // measurement pressure (OSS1)
    `define MSR_PRS2  4'b0100 // measurement pressure (OSS2)
    `define MSR_PRS3  4'b0101 // measurement pressure (OSS3)
    `define SOFT_RST  4'b0110 // soft reset BMP180
    `define CHECK     4'b0111 // check chip id BMP180
    `define MSR_TMP   4'b1000 // measurement temperature


module controller
    #(parameter FPGA_CLK    = 50_000_000, // FPGA frequency 50 MHz
      parameter ADDR_I2C_SZ = 7,          // addr on I2C bus width
      parameter DATA_I2C_SZ = 8,          // data on I2C bus width
      parameter ADDR_ROM_SZ = 4,          // addr width in ROM 
      parameter DATA_ROM_SZ = 8,          // word width in ROM 
      parameter ADDR_OPM_SZ = 4,          // addr width in RAM 
      parameter RXD_SZ      = 24,         // buffer of received data from BMP180 (width)
      parameter DATA_OPM_SZ = 16)         // word width in RAM
    (CLK, RST_n, I_COMM, I_DATA_ROM, I_DATA_RD_I2C, I_BUSY, I_CNT, I_FL,
     O_EN_I2C, O_ADDR_I2C, O_RW, O_DATA_WR_I2C, O_FL, O_ERR, O_EN_RAM, O_ADDR_ROM, O_WE, O_ADDR_OPM, O_DATA_WR_OPM, O_EN_CNT, O_RST_CNT, O_OSS, O_RXD_BUFF, O_UT_CALC, O_UP_CALC);
   

    localparam CHIP_ID          = 8'h55; // chip id BMP180 = 0x55
    localparam CNT_RS_I_BUSY_SZ = 2;     // rising edge counter I_BUSY width
    localparam CNT_FL_I_BUSY_SZ = 5;     // falling edge counter I_BUSY width
    localparam FL_SZ            = 8;     // command execution flag width
//  addr reg BMP180
    localparam ADDR_BMP180 = 7'h77; // addr BMP180 on I2C bus
    localparam ADDR_MSR    = 8'hF4; // addr reg measurement control
    localparam ADDR_MSB    = 8'hF6; // addr reg out_msb
    localparam ADDR_SRST   = 8'hE0; // addr reg soft reset
//  conversion time    
    localparam T_MSR_0 = 0.0045; // conversion time 4,5 mS (oss = 0)
    localparam T_MSR_1 = 0.0075; // conversion time 7,5 mS (oss = 1)
    localparam T_MSR_2 = 0.0135; // conversion time 13,5 mS (oss = 2)
    localparam T_MSR_3 = 0.0255; // maximum conversion time 25,5 mS (oss = 3)
    localparam integer N_CLK_MSR_0 = FPGA_CLK * T_MSR_0;  // number of clocks 50 MHz (4,5 mS, 225_000 clk)
    localparam integer N_CLK_MSR_1 = FPGA_CLK * T_MSR_1;  // number of clocks 50 MHz (7,5 mS, 375_000 clk)
    localparam integer N_CLK_MSR_2 = FPGA_CLK * T_MSR_2;  // number of clocks 50 MHz (13,5 mS, 675_000 clk)
    localparam integer N_CLK_MSR_3 = FPGA_CLK * T_MSR_3;  // number of clocks 50 MHz (25,5 mS, 1_275_000 clk)
    localparam CNT_MSR_MX_SZ       = $clog2(N_CLK_MSR_3); // conversion time counter width
//  addr in RAM BMP180 reg 
    localparam AC1 = 4'd10;      // addr in RAM value reg AC1
    localparam AC2 = AC1 - 1'b1; // addr in RAM value reg AC2
    localparam AC3 = AC2 - 1'b1; // addr in RAM value reg AC3
    localparam AC4 = AC3 - 1'b1; // addr in RAM value reg AC4
    localparam AC5 = AC4 - 1'b1; // addr in RAM value reg AC5
    localparam AC6 = AC5 - 1'b1; // addr in RAM value reg AC6
    localparam B1  = AC6 - 1'b1; // addr in RAM value reg B1
    localparam B2  = B1  - 1'b1; // addr in RAM value reg B2
    localparam MB  = B2  - 1'b1; // addr in RAM value reg MB
    localparam MC  = MB  - 1'b1; // addr in RAM value reg MC
    localparam MD  = MC  - 1'b1; // addr in RAM value reg MD
//  description states FSM
    localparam ST_SZ          = 13;                // number of states FSM
    localparam RD_CC_ST       = 13'b0000000000001; // start reading calibration coefficients
    localparam RD_CC_RST      = 13'b0000000000010; // restart reading calibration coefficients
    localparam RD_CC_FN       = 13'b0000000000100; // reading calibration coefficients
    localparam WT_COMM        = 13'b0000000001000; // waiting for a command for BMP180
    localparam RD_TMP_ST      = 13'b0000000010000; // start reading temperature
    localparam RD_TMP_FN      = 13'b0000000100000; // finish reading temperature    
    localparam RD_PRS_ST      = 13'b0000001000000; // start reading pressure
    localparam RD_TMP_PRS_RST = 13'b0000010000000; // restart reading temperature and pressure
    localparam RD_PRS_FN      = 13'b0000100000000; // finish reading pressure
    localparam IDLE_P         = 13'b0001000000000; // waiting finish calc P
    localparam SFT_RST        = 13'b0010000000000; // start soft reset
    localparam PING           = 13'b0100000000000; // start communication check, sensor returns value 0x55
    localparam PING_RD        = 13'b1000000000000; // reading chip id    
//  input signals
    input wire                     CLK;           // clock 50 MHz
    input wire                     RST_n;         // asynchronous reset_n
    input wire [ADDR_ROM_SZ-1:0]   I_COMM;        // command for BMP180    
    input wire [DATA_ROM_SZ-1:0]   I_DATA_ROM;    // word in ROM   
    input wire [DATA_I2C_SZ-1:0]   I_DATA_RD_I2C; // readed data from I2C bus
    input wire                     I_BUSY;        // master I2C busy signal
    input wire [CNT_MSR_MX_SZ-1:0] I_CNT;         // conversion time counter
    input wire [1:0]               I_FL;          // calc module execution flag
//  output signals
    output reg                   O_EN_I2C;      // start enable I2C bus   
    output reg [ADDR_I2C_SZ-1:0] O_ADDR_I2C;    // addr BMP180 on I2C bus
    output reg                   O_RW;          // RW I2C bus 
    output reg [DATA_I2C_SZ-1:0] O_DATA_WR_I2C; // data for writing on I2C bus   
    output reg [ADDR_ROM_SZ-1:0] O_ADDR_ROM;    // command for BMP180 
    output reg                   O_EN_RAM;      // RAM transaction enable 
    output reg                   O_WE;          // WE RAM signal
    output reg [ADDR_OPM_SZ-1:0] O_ADDR_OPM;    // word addr in RAM
    output reg [DATA_OPM_SZ-1:0] O_DATA_WR_OPM; // word to write to RAM 
    output reg [FL_SZ-1:0]       O_FL;          // command execution flag     
    output reg                   O_ERR;         // chip id error (BMP180) or error state of FSM
    output reg                   O_EN_CNT;      // enable signal conversion time counter
    output reg                   O_RST_CNT;     // reset conversion time counter
    output reg [1:0]             O_OSS;         // number OSS (0 or 1 or 2 or3)    
    output reg [RXD_SZ-1:0]      O_RXD_BUFF;    // buffer of received data from BMP180    
    output reg                   O_UT_CALC;     // enable calc T
    output reg                   O_UP_CALC;     // enable calc P
//  internal signals
    reg [ST_SZ-1:0]            st;               // current state of FSM
    reg [ST_SZ-1:0]            nx_st;            // next state of FSM
    reg                        nx_o_en_i2c;      // next enable signal I2C bus
    reg [ADDR_I2C_SZ-1:0]      nx_o_addr_i2c;    // next addr on I2C bus
    reg                        nx_o_rw;          // next RW I2C bus     
    reg [DATA_I2C_SZ-1:0]      nx_o_data_wr_i2c; // next data for writing on I2C bus 
    reg                        pr_i_busy;        // previous I_BUSY
    reg                        cr_i_busy;        // current I_BUSY
    wire                       rs_i_busy;        // rising edge I_BUSY
    wire                       fl_i_busy;        // falling edge I_BUSY
    reg [CNT_RS_I_BUSY_SZ-1:0] cnt_rs_i_busy;    // rising edge counter I_BUSY
    reg [CNT_RS_I_BUSY_SZ-1:0] nx_cnt_rs_i_busy; // next rising edge counter I_BUSY  
    reg [CNT_FL_I_BUSY_SZ-1:0] cnt_fl_i_busy;    // falling edge counter I_BUSY
    reg [CNT_FL_I_BUSY_SZ-1:0] nx_cnt_fl_i_busy; // next falling edge counter I_BUSY
    reg [ADDR_ROM_SZ-1:0]      nx_o_addr_rom;    // next command for BMP180
    reg                        nx_o_en_ram;      // next RAM transaction enable     
    reg                        nx_o_we;          // next WE RAM signal  
    reg [ADDR_OPM_SZ-1:0]      nx_o_addr_opm;    // next word addr in RAM
    reg [DATA_OPM_SZ-1:0]      nx_o_data_wr_opm; // next word to write to RAM
    reg                        nx_o_en_cnt;      // next enable signal conversion time counter   
    reg                        nx_o_rst_cnt;     // next reset conversion time counter
    reg [ADDR_ROM_SZ-1:0]      comm_reg;         // latching I_COMM
    reg [ADDR_ROM_SZ-1:0]      nx_comm_reg;      // next latching I_COMM
    reg [FL_SZ-1:0]            nx_o_fl;          // next command execution flag 
    reg                        nx_o_err;         // next chip id error (BMP180)
    reg [1:0]                  cnt_for_wr;       // counter for coefficient buffer
    reg [1:0]                  nx_cnt_for_wr;    // counter for coefficient buffer
    reg [RXD_SZ-1:0]           nx_o_rxd_buff;    // next buffer of received data from BMP180
    reg [1:0]                  nx_o_oss;         // next number OSS (0 or 1 or 2 or3)
    reg                        nx_o_ut_calc;     // next enable calc T
    reg                        nx_o_up_calc;     // enable calc P  
    
//  determining of rissing edge and falling edge I_BUSY
    assign rs_i_busy =  cr_i_busy & !pr_i_busy;
    assign fl_i_busy = !cr_i_busy &  pr_i_busy; 

//  determining the next state of FSM and singals    
    always @(*) begin
      nx_st = st;
      nx_o_addr_i2c = O_ADDR_I2C;
      nx_o_rw = O_RW;
      nx_o_data_wr_i2c = O_DATA_WR_I2C;
      nx_o_en_i2c = O_EN_I2C;
      nx_cnt_rs_i_busy = cnt_rs_i_busy;
      nx_cnt_fl_i_busy = cnt_fl_i_busy;
      nx_o_en_ram = O_EN_RAM;
      nx_o_we = O_WE;  
      nx_o_addr_opm = O_ADDR_OPM;
      nx_o_data_wr_opm = O_DATA_WR_OPM;
      nx_o_addr_rom = O_ADDR_ROM;
      nx_o_en_cnt = O_EN_CNT;
      nx_o_rst_cnt = O_RST_CNT;
      nx_comm_reg = comm_reg;
      nx_o_fl = O_FL;
      nx_o_err = O_ERR;
      nx_cnt_for_wr = cnt_for_wr;
      nx_o_oss = O_OSS;
      nx_o_rxd_buff = O_RXD_BUFF;
      nx_o_ut_calc = O_UT_CALC;
      nx_o_up_calc = O_UP_CALC;
      case (st)
          RD_CC_ST       : begin
                             nx_o_addr_rom = `READ_CC;          // ROM return 8'hAA
                             if (I_COMM == `READ_CC || comm_reg == `READ_CC) 
                               begin
                                 nx_o_en_i2c = 1'b1;            // start of a transaction on the bus I2C
                                 nx_o_addr_i2c = ADDR_BMP180;   // setting addr BMP180
                                 nx_o_rw = 1'b0;                // write
                                 nx_o_data_wr_i2c = I_DATA_ROM; // reg addr AC1 (calibration coefficients)
                                 nx_o_fl[0] = 1'b1;             // transaction execution flag
                                 if (rs_i_busy)
                                   begin
                                     nx_o_en_i2c = 1'b0;        // stop of a transaction on the bus I2C
                                     nx_st = RD_CC_RST;
                                   end
                               end
                           end 
          RD_CC_RST      : begin
                             if (fl_i_busy)  
                               begin
                                 nx_o_en_i2c = 1'b1;          // restart I2C bus
                                 nx_o_addr_i2c = ADDR_BMP180; // setting addr BMP180
                                 nx_o_rw = 1'b1;              // reading from reg addr AC1 (calibration coefficients)
                                 nx_cnt_fl_i_busy = 22;       // setting counter = 22 (rxd 22 bytes from reg addr AC1, AC2, AC3, AC4, AC5, AC6, B1, B2, MB, MC, MD)
                                 nx_o_addr_opm = AC1 + 1'b1;  // setting addr to RAM
                                 nx_o_en_ram = 1'b1;
                                 nx_st = RD_CC_FN;
                               end                  
                           end
          RD_CC_FN       : begin
                             if (fl_i_busy)
                               begin
                                 nx_cnt_for_wr = cnt_for_wr + 1'b1;
                                 nx_cnt_fl_i_busy = cnt_fl_i_busy - 1'b1; 
                                 nx_o_rxd_buff = {O_RXD_BUFF[15:0], I_DATA_RD_I2C};
                               end
                             if (cnt_for_wr == 2'b10)
                               begin
                                 nx_cnt_for_wr = 2'b0;
                                 nx_o_data_wr_opm = O_RXD_BUFF[15:0];     // setting data to writing to RAM
                                 nx_o_we = 1'b1;                          // setting I_WE to writing to RAM             
                                 nx_o_addr_opm = O_ADDR_OPM - 1'b1;       // setting addr for RAM
                               end
                             if (rs_i_busy)
                               begin
                                 nx_o_we = 1'b0;                          // stop writing to RAM
                               end
                             if (cnt_fl_i_busy == 1)
                               nx_o_en_i2c = 1'b0;                        // stop reading, txd ACK
                             if (&(!cnt_fl_i_busy))                       // when = 0
                               begin
                                 nx_o_fl[0] = 1'b0;                       // end of reading calibration coefficients
                                 nx_st = WT_COMM;
                               end
                           end     
          WT_COMM        : begin
                             nx_o_we = 1'b0;       // stop write to RAM
                             nx_o_en_ram = 1'b0;
                             nx_comm_reg = I_COMM; // latching I_COMM
                             case (I_COMM)
                                `READ_CC  :   nx_st = RD_CC_ST;
                                `MSR_PRS0 : begin
                                              nx_o_en_i2c = 1'b1;          // start of a transaction on the bus I2C
                                              nx_o_addr_i2c = ADDR_BMP180; // setting addr BMP180
                                              nx_o_rw = 1'b0;              // write
                                              nx_o_data_wr_i2c = ADDR_MSR; // reg addr "Measurement control"
                                              nx_o_err = 1'b0;             // zero error
                                              nx_o_fl[2:1] = 2'b11;        // transaction execution flag (pressurve and temperature measurement) 
                                              nx_o_oss = 2'b0;             // setting reg OSS = 0
                                              nx_o_addr_rom = `MSR_TMP;    // ROM return 8'h2E
                                              nx_st = RD_TMP_ST;
                                            end
                                `MSR_PRS1 : begin
                                              nx_o_en_i2c = 1'b1;          // start of a transaction on the bus I2C
                                              nx_o_addr_i2c = ADDR_BMP180; // setting addr BMP180
                                              nx_o_rw = 1'b0;              // write
                                              nx_o_data_wr_i2c = ADDR_MSR; // reg addr "Measurement control"
                                              nx_o_err = 1'b0;             // zero error
                                              nx_o_fl[3] = 1'b1;           // transaction execution flag (pressurve measurement)
                                              nx_o_fl[1] = 1'b1;           // transaction execution flag (temperature measurement)
                                              // nx_o_oss = 2'b0;             // for simulation setting reg OSS = 0
                                              nx_o_oss = 2'b01;            // for FPGA setting reg OSS = 1
                                              nx_o_addr_rom = `MSR_TMP;    // ROM return 8'h2E
                                              nx_st = RD_TMP_ST;
                                            end
                                `MSR_PRS2 : begin
                                              nx_o_en_i2c = 1'b1;          // start of a transaction on the bus I2C
                                              nx_o_addr_i2c = ADDR_BMP180; // setting addr BMP180
                                              nx_o_rw = 1'b0;              // write
                                              nx_o_data_wr_i2c = ADDR_MSR; // reg addr "Measurement control"
                                              nx_o_err = 1'b0;             // zero error
                                              nx_o_fl[4] = 1'b1;           // transaction execution flag (pressurve measurement)
                                              nx_o_fl[1] = 1'b1;           // transaction execution flag (temperature measurement)
                                              // nx_o_oss = 2'b0;             // for simulation setting reg OSS = 0
                                              nx_o_oss = 2'b10;            // for FPGA setting reg OSS = 2
                                              nx_o_addr_rom = `MSR_TMP;    // ROM return 8'h2E
                                              nx_st = RD_TMP_ST;
                                            end
                                `MSR_PRS3 : begin
                                              nx_o_en_i2c = 1'b1;          // start of a transaction on the bus I2C
                                              nx_o_addr_i2c = ADDR_BMP180; // setting addr BMP180
                                              nx_o_rw = 1'b0;              // write
                                              nx_o_data_wr_i2c = ADDR_MSR; // reg addr "Measurement control"
                                              nx_o_err = 1'b0;             // zero error
                                              nx_o_fl[5] = 1'b1;           // transaction execution flag (pressurve measurement)
                                              nx_o_fl[1] = 1'b1;           // transaction execution flag (temperature measurement)
                                              // nx_o_oss = 2'b0;             // for simulation setting reg OSS = 0
                                              nx_o_oss = 2'b11;            // for FPGA setting reg OSS = 3
                                              nx_o_addr_rom = `MSR_TMP;    // ROM return 8'h2E
                                              nx_st = RD_TMP_ST;
                                            end
                                `SOFT_RST : begin
                                              nx_o_en_i2c = 1'b1;           // start of a transaction on the bus I2C
                                              nx_o_addr_i2c = ADDR_BMP180;  // setting addr BMP180
                                              nx_o_rw = 1'b0;               // write
                                              nx_o_data_wr_i2c = ADDR_SRST; // reg addr soft reset
                                              nx_o_err = 1'b0;              // zero error
                                              nx_o_fl[6] = 1'b1;            // transaction execution flag
                                              nx_o_addr_rom = `SOFT_RST;
                                              nx_st = SFT_RST;
                                            end
                                `CHECK    : begin
                                              nx_o_en_i2c = 1'b1;            // start of a transaction on the bus I2C
                                              nx_o_addr_i2c = ADDR_BMP180;   // setting addr BMP180
                                              nx_o_rw = 1'b0;                // write
                                              nx_o_err = 1'b0;               // zero error
                                              nx_o_fl[7] = 1'b1;             // transaction execution flag
                                              nx_o_addr_rom = `CHECK;
                                              nx_st = PING;
                                            end
                                default   : begin
                                              nx_st = WT_COMM;
                                            end
                             endcase
                           end
          RD_TMP_ST      : begin
                             if (rs_i_busy)
                               begin
                                 nx_o_data_wr_i2c = I_DATA_ROM;           // data for write in reg "Measurement control"
                                 nx_cnt_rs_i_busy = cnt_rs_i_busy + 1'b1;
                               end          
                             if (cnt_rs_i_busy == 2'b10)
                               begin
                                 nx_o_en_i2c = 1'b0;                      // stop of a transaction on the bus I2C
                                 if (fl_i_busy)
                                   nx_o_en_cnt = 1'b1;                    // start counter clocks
                               end
                             if (I_CNT >= N_CLK_MSR_0 - 1'b1)
                               begin
                                 nx_o_en_i2c = 1'b1;                      // start of a transaction on the bus I2C
                                 nx_o_addr_i2c = ADDR_BMP180;             // setting addr BMP180
                                 nx_o_rw = 1'b0;                          // write
                                 nx_o_data_wr_i2c = ADDR_MSB;             // Out MSB (0xF6)
                                 if (rs_i_busy)
                                   begin 
                                     nx_o_en_i2c = 1'b0;                  // stop of a transaction on the bus I2C
                                     nx_st = RD_TMP_PRS_RST;
                                   end      
                               end 
                           end
          RD_TMP_PRS_RST : begin
                             nx_o_en_cnt = 1'b0;                          // stop counter clocks
                             nx_o_rst_cnt = 1'b1;                         // setting zero counter clocks
                             nx_cnt_rs_i_busy = {CNT_RS_I_BUSY_SZ{1'b0}}; // zero counter I_BUSY
                             if (fl_i_busy)  
                               begin
                                 nx_o_en_i2c = 1'b1;                      // restart I2C bus
                                 nx_o_addr_i2c = ADDR_BMP180;             // setting addr BMP180
                                 nx_o_rw = 1'b1;                          // reading Out MSB (0xF6)
                                 if (O_FL[1])
                                   begin
                                     nx_cnt_fl_i_busy = 2;                // setting counter I_BUSY = 2 (rxd two bytes from Out MSB, Out LSB)                            
                                     nx_st = RD_TMP_FN;
                                   end
                                 else
                                   begin
                                     nx_cnt_fl_i_busy = 3;                // setting counter I_BUSY = 3 (rxd free bytes from Out MSB, Out LSB, Out XLSB)                            
                                     nx_st = RD_PRS_FN;
                                   end
                               end          
                           end    
          RD_TMP_FN      : begin
                             nx_o_rst_cnt = 1'b0; 
                             nx_o_addr_rom = comm_reg;
                             if (fl_i_busy)
                               begin 
                                 nx_cnt_fl_i_busy = cnt_fl_i_busy - 1'b1;
                                 nx_o_rxd_buff = {O_RXD_BUFF[15:0], I_DATA_RD_I2C}; // latching rxd in buffer
                               end
                             if (cnt_fl_i_busy == 1'b1)
                               nx_o_en_i2c = 1'b0;                                  // stop of a transaction on I2C bus
                             if (&(!cnt_fl_i_busy))                                 // when = 0
                               begin
                                 nx_o_en_i2c = 1'b1;                                // start of a transaction on the bus I2C
                                 nx_o_addr_i2c = ADDR_BMP180;                       // setting addr BMP180
                                 nx_o_rw = 1'b0;                                    // write
                                 nx_o_data_wr_i2c = ADDR_MSR;                       // reg addr "Measurement control"
                                 nx_o_ut_calc = 1'b1;
                                 nx_st = RD_PRS_ST;
                               end         
                           end
          RD_PRS_ST      : begin
                             nx_o_fl[1] = I_FL[0];
                             nx_o_ut_calc = 1'b0;
                             if (rs_i_busy)
                               begin
                                 nx_o_data_wr_i2c = I_DATA_ROM;           // data for write in reg "Measurement control"
                                 nx_cnt_rs_i_busy = cnt_rs_i_busy + 1'b1;
                               end          
                             if (cnt_rs_i_busy == 2'b10)
                               begin
                                 nx_o_en_i2c = 1'b0;                      // stop of a transaction on the bus I2C
                                 if (fl_i_busy)
                                   nx_o_en_cnt = 1'b1;                    // start counter clocks
                               end
                             case (comm_reg)
                                `MSR_PRS0 : begin
                                              if (I_CNT >= N_CLK_MSR_0 - 1'b1)
                                                begin
                                                  nx_o_en_i2c = 1'b1;             // start of a transaction on the bus I2C
                                                  nx_o_addr_i2c = ADDR_BMP180;    // setting addr BMP180
                                                  nx_o_rw = 1'b0;                 // write
                                                  nx_o_data_wr_i2c = ADDR_MSB;    // Out MSB (0xF6)
                                                  if (rs_i_busy)
                                                    begin 
                                                      nx_o_en_i2c = 1'b0;         // stop of a transaction on the bus I2C
                                                      nx_st = RD_TMP_PRS_RST; 
                                                    end                    
                                                 end 
                                            end
                                `MSR_PRS1 : begin
                                              if (I_CNT >= N_CLK_MSR_1 - 1'b1) 
                                                 begin
                                                   nx_o_en_i2c = 1'b1;             // start of a transaction on the bus I2C
                                                   nx_o_addr_i2c = ADDR_BMP180;    // setting addr BMP180
                                                   nx_o_rw = 1'b0;                 // write
                                                   nx_o_data_wr_i2c = ADDR_MSB;    // Out MSB (0xF6)
                                                   if (rs_i_busy)
                                                     begin 
                                                       nx_o_en_i2c = 1'b0;         // stop of a transaction on the bus I2C
                                                       nx_st = RD_TMP_PRS_RST;
                                                     end                    
                                                 end 
                                            end
                                `MSR_PRS2 : begin
                                              if (I_CNT >= N_CLK_MSR_2 - 1'b1)
                                                 begin
                                                   nx_o_en_i2c = 1'b1;             // start of a transaction on the bus I2C
                                                   nx_o_addr_i2c = ADDR_BMP180;    // setting addr BMP180
                                                   nx_o_rw = 1'b0;                 // write
                                                   nx_o_data_wr_i2c = ADDR_MSB;    // Out MSB (0xF6)
                                                   if (rs_i_busy)
                                                     begin 
                                                       nx_o_en_i2c = 1'b0;         // stop of a transaction on the bus I2C
                                                       nx_st = RD_TMP_PRS_RST;
                                                     end                    
                                                 end 
                                            end
                                `MSR_PRS3 : begin
                                              if (I_CNT >= N_CLK_MSR_3 - 1'b1) 
                                                 begin
                                                   nx_o_en_i2c = 1'b1;             // start of a transaction on the bus I2C
                                                   nx_o_addr_i2c = ADDR_BMP180;    // setting addr BMP180
                                                   nx_o_rw = 1'b0;                 // write
                                                   nx_o_data_wr_i2c = ADDR_MSB;    // Out MSB (0xF6)
                                                   if (rs_i_busy)
                                                     begin 
                                                       nx_o_en_i2c = 1'b0;         // stop of a transaction on the bus I2C
                                                       nx_st = RD_TMP_PRS_RST; 
                                                     end                    
                                                 end 
                                            end
                                default   : begin
                                              nx_st = WT_COMM;
                                              nx_o_err = 1'b1;                     // error
                                            end
                             endcase
                           end
          RD_PRS_FN      : begin
                             nx_o_rst_cnt = 1'b0; 
                             if (fl_i_busy)
                               begin 
                                 nx_cnt_fl_i_busy = cnt_fl_i_busy - 1'b1;
                                 nx_o_rxd_buff = {O_RXD_BUFF[15:0], I_DATA_RD_I2C}; // latching rxd in buffer
                               end
                             if (cnt_fl_i_busy == 1'b1)
                               nx_o_en_i2c = 1'b0;                                  // stop of a transaction on the bus I2C
                             if (&(!cnt_fl_i_busy))                                 // when = 0
                               begin
                                 nx_o_up_calc = 1'b1;
                                 nx_st = IDLE_P;
                               end
                           end
          IDLE_P         : begin
                             if (!I_FL[1])
                               begin
                                 nx_o_up_calc = 1'b0;
                                 nx_o_fl = {FL_SZ{1'b0}};
                                 nx_st = WT_COMM;
                               end
                           end
          SFT_RST        : begin
                             if (rs_i_busy)
                               begin
                                 nx_o_data_wr_i2c = I_DATA_ROM;                   // soft reset 
                                 nx_cnt_rs_i_busy = cnt_rs_i_busy + 1'b1;
                               end
                             if (cnt_rs_i_busy == 2'b10)
                               begin
                                 nx_o_en_i2c = 1'b0;                              // stop of a transaction on the bus I2C
                                 if (fl_i_busy)
                                   begin
                                     nx_cnt_rs_i_busy = {CNT_RS_I_BUSY_SZ{1'b0}}; // zero counter I_BUSY
                                     nx_o_fl = {FL_SZ{1'b0}};                     // zero flags
                                     nx_st = WT_COMM;
                                   end
                               end  
                           end             
          PING           : begin
                             nx_o_data_wr_i2c = I_DATA_ROM;   // reg addr chip ip
                             if (rs_i_busy)
                                 nx_o_en_i2c = 1'b0;          // stop of a transaction on the bus I2C         
                             if (fl_i_busy)  
                               begin
                                 nx_o_en_i2c = 1'b1;          // restart I2C bus
                                 nx_o_addr_i2c = ADDR_BMP180; // setting addr BMP180
                                 nx_o_rw = 1'b1;              // read
                                 nx_st = PING_RD;             // nx_st is PING
                               end                  
                           end
          PING_RD        : begin
                             if (rs_i_busy)
                               nx_o_en_i2c = 1'b0;             // stop of a transaction on the bus I2C 
                             if (fl_i_busy)
                               begin
                                 nx_o_fl = {FL_SZ{1'b0}};      // zero flags
                                 nx_st = WT_COMM;
                                 if (I_DATA_RD_I2C != CHIP_ID)
                                   nx_o_err = 1'b1;            // error if read data != 0x55                                   
                               end
                           end          
          default        : begin
                             nx_st = WT_COMM;
                             nx_o_err = 1'b1;
                             nx_o_en_i2c = 1'b0;
                             nx_o_addr_i2c = {ADDR_I2C_SZ{1'b0}};
                             nx_o_rw = 1'b0;
                             nx_o_data_wr_i2c = {DATA_I2C_SZ{1'b0}};
                             nx_cnt_rs_i_busy = {CNT_RS_I_BUSY_SZ{1'b0}};
                             nx_cnt_fl_i_busy = {CNT_FL_I_BUSY_SZ{1'b0}};
                             nx_o_en_ram = 1'b0;
                             nx_o_addr_opm = {ADDR_OPM_SZ{1'b0}};
                             nx_o_data_wr_opm = {DATA_OPM_SZ{1'b0}}; 
                             nx_o_addr_rom = {ADDR_ROM_SZ{1'b0}};
                             nx_o_we = 1'b0;
                             nx_o_en_cnt = 1'b0;
                             nx_o_rst_cnt = 1'b1;
                             nx_comm_reg = {ADDR_ROM_SZ{1'b0}};
                             nx_o_fl = {FL_SZ{1'b0}};
                             nx_cnt_for_wr = 2'b0;
                             nx_o_oss = 2'b0;                     
                             nx_o_rxd_buff = {RXD_SZ{1'b0}};
                             nx_o_ut_calc = 1'b0;
                             nx_o_up_calc = 1'b0;
                           end
      endcase
    end 
    
//  latching the next state of FSM and signals, every clock     
    always @(posedge CLK or negedge RST_n) begin
      if (!RST_n)
        begin
          st            <= RD_CC_ST;     
          O_EN_I2C      <= 1'b0;       
          O_ADDR_I2C    <= {ADDR_I2C_SZ{1'b0}};
          O_RW          <= 1'b0;
          O_DATA_WR_I2C <= {DATA_I2C_SZ{1'b0}};
          cr_i_busy     <= 1'b0;
          pr_i_busy     <= 1'b0;
          cnt_rs_i_busy <= {CNT_RS_I_BUSY_SZ{1'b0}};
          cnt_fl_i_busy <= {CNT_FL_I_BUSY_SZ{1'b0}};    
          O_EN_RAM      <= 1'b0;
          O_ADDR_ROM    <= {ADDR_ROM_SZ{1'b0}};
          O_WE          <= 1'b0;          
          O_ADDR_OPM    <= {ADDR_OPM_SZ{1'b0}};
          O_DATA_WR_OPM <= {DATA_OPM_SZ{1'b0}};
          O_EN_CNT      <= 1'b0;
          O_RST_CNT     <= 1'b0;
          comm_reg      <= {ADDR_ROM_SZ{1'b0}};
          O_FL          <= {FL_SZ{1'b0}};
          O_ERR         <= 1'b0;
          cnt_for_wr    <= 2'b0;
          O_OSS         <= 2'b0;        
          O_RXD_BUFF    <= {RXD_SZ{1'b0}};
          O_UT_CALC     <= 1'b0;
          O_UP_CALC     <= 1'b0;
        end
      else
        begin
          st            <= nx_st;        
          O_EN_I2C      <= nx_o_en_i2c;          
          O_ADDR_I2C    <= nx_o_addr_i2c;
          O_RW          <= nx_o_rw;
          O_DATA_WR_I2C <= nx_o_data_wr_i2c;
          cr_i_busy     <= I_BUSY;
          pr_i_busy     <= cr_i_busy; 
          cnt_rs_i_busy <= nx_cnt_rs_i_busy;
          cnt_fl_i_busy <= nx_cnt_fl_i_busy;
          O_EN_RAM      <= nx_o_en_ram;
          O_ADDR_ROM    <= nx_o_addr_rom;
          O_WE          <= nx_o_we;          
          O_ADDR_OPM    <= nx_o_addr_opm; 
          O_DATA_WR_OPM <= nx_o_data_wr_opm;
          O_EN_CNT      <= nx_o_en_cnt; 
          O_RST_CNT     <= nx_o_rst_cnt;
          comm_reg      <= nx_comm_reg;
          O_FL          <= nx_o_fl;
          O_ERR         <= nx_o_err;
          cnt_for_wr    <= nx_cnt_for_wr;
          O_OSS         <= nx_o_oss; 
          O_RXD_BUFF    <= nx_o_rxd_buff;          
          O_UT_CALC     <= nx_o_ut_calc;
          O_UP_CALC     <= nx_o_up_calc;
        end
    end
 
    
endmodule