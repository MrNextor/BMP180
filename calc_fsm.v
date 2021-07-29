// command ALU
    `define ALU_ADD   3'b000
    `define ALU_ADDU  3'b001
    `define ALU_SLL   3'b010
    `define ALU_SRL   3'b011
    `define ALU_SLTU  3'b100
    `define ALU_SUBU  3'b101
    `define ALU_SUB   3'b110
    `define ALU_SRA   3'b111


module calc_fsm
    #(parameter ADDR_OPM_SZ = 4,  // addr width in RAM 
      parameter DATA_OPM_SZ = 16, // word width in RAM
      parameter DATA_ALU    = 32, // data ALU width
      parameter OP_SZ       = 3,  // aluControl width
      parameter SH_SZ       = 5,  // shift width
      parameter RXD_SZ      = 24, // buffer of received data from BMP180 (width)
      parameter DATA_DIV    = 33) // data div width
      (CLK, RST_n, I_RXD_BUFF, I_UT_CALC, I_UP_CALC, I_OSS, I_DATA_RAM, I_RSL_ALU, I_RSL_MULT, I_RSL_DIV, I_FN_DIV,
       O_WE, O_ADDR_OPM, O_DATA_WR_OPM, O_A, O_B, O_OP, O_SH, O_SG, O_EN_DIV, O_NUM, O_DEN, O_T_VALUE, O_P_VALUE, O_FL);
     
    
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
//  addr in RAM current T and P
    localparam T_CURR = AC1 + 1'b1;    // addr in RAM value O_T_VALUE[15:0]
    localparam P_LSB  = T_CURR + 1'b1; // ddrr in RAM value O_P_VALUE[15:0]
    localparam P_MSB  = P_LSB + 1'b1;  // ddrr in RAM value O_P_VALUE[18:16]
//  description states FSM
    localparam ST_SZ     = 6;
    localparam IDLE_UT   = 6'b000001; // waiting I_UT_CALC
    localparam T_ST_CALC = 6'b000010; // start calculate true temperature
    localparam T_FN_CALC = 6'b000100; // finish calculate true temperature
    localparam IDLE_UP   = 6'b001000; // waiting I_UP_CALC
    localparam P_ST_CALC = 6'b010000; // start calculate true pressure
    localparam P_FN_CALC = 6'b100000; // finish calculate true pressure
//  input signals
    input wire                       CLK;        // clock 50 MHz
    input wire                       RST_n;      // asynchronous reset_n
    input wire [RXD_SZ-1:0]          I_RXD_BUFF; // buffer of received data from BMP180
    input wire                       I_UT_CALC;  // enable calc T
    input wire                       I_UP_CALC;  // enable calc P
    input [1:0]                      I_OSS;      // number OSS (0 or 1 or 2 or3)
    input wire [DATA_OPM_SZ-1:0]     I_DATA_RAM; // raeded word in RAM
    input wire [DATA_ALU-1:0]        I_RSL_ALU;  // result alu
    input wire [DATA_ALU-1:0]        I_RSL_MULT; // result mult
    input wire signed [DATA_DIV-1:0] I_RSL_DIV;  // result division 
    input wire                       I_FN_DIV;   // end of division
//  output signals
    output reg                   O_WE;          // WE RAM signal
    output reg [ADDR_OPM_SZ-1:0] O_ADDR_OPM;    // word addr in RAM
    output reg [DATA_OPM_SZ-1:0] O_DATA_WR_OPM; // word to write to RAM 
    output reg [DATA_ALU-1:0]    O_A;           // srcA
    output reg [DATA_ALU-1:0]    O_B;           // srcB
    output reg [OP_SZ-1:0]       O_OP;          // aluControl
    output reg [SH_SZ-1:0]       O_SH;          // shift
    output reg                   O_SG;          // singed mult
    output reg                   O_EN_DIV;      // enable devision
    output reg [DATA_DIV-1:0]    O_NUM;         // numerator
    output reg [DATA_DIV-1:0]    O_DEN;         // denomerator   
    output reg signed [15:0]     O_T_VALUE;     // current temperature
    output reg signed [18:0]     O_P_VALUE;     // current pressure    
    output reg [1:0]             O_FL;          // calc execution flag
//  internal signals
    reg [ST_SZ-1:0]           st;               // current state of FSM
    reg [ST_SZ-1:0]           nx_st;            // next state of FSM
    reg [RXD_SZ-1:0]          rxd_buff;         // buffer of received data from BMP180
    reg [RXD_SZ-1:0]          nx_rxd_buff;      // next buffer of received data from BMP18    
    reg [1:0]                 nx_o_fl;          // next calc execution flag
    reg                       nx_o_we;          // next WE RAM signal  
    reg [ADDR_OPM_SZ-1:0]     nx_o_addr_opm;    // next word addr in RAM
    reg [DATA_OPM_SZ-1:0]     nx_o_data_wr_opm; // next word to write to RAM
    reg [4:0]                 cnt_calc;         // operation counter calculation 
    reg [4:0]                 nx_cnt_calc;      // next operation counter calculation
    reg [DATA_ALU-1:0]        nx_o_a;           // next srcA
    reg [DATA_ALU-1:0]        nx_o_b;           // next srcB
    reg [OP_SZ-1:0]           nx_o_op;          // next aluControl
    reg [SH_SZ-1:0]           nx_o_sh;          // next shift  
    reg                       nx_o_sg;          // singed mult
    reg                       rsl_sltu;         // result ALU_SLTU for (17)
    reg                       nx_rsl_sltu;      // next result ALU_SLTU for (17)
    reg                       nx_o_en_div;      // next enable devision
    reg [DATA_DIV-1:0]        nx_o_num;         // next numerator 
    reg [DATA_DIV-1:0]        nx_o_den;         // next denomerator
    reg                       cr_i_fn_div;      // current I_FN_DIV
    reg                       pr_i_fn_div;      // previous I_FN_DIV
    wire                      rs_i_fn_div;      // rising edge I_FN_DIV
    reg signed [15:0]         ut_buff;          // buffer UT
    reg signed [15:0]         nx_ut_buff;       // next buffer UT
    reg signed [DATA_ALU-1:0] up_buff;          // buffer UP
    reg signed [DATA_ALU-1:0] nx_up_buff;       // next buffer UP
    reg signed [DATA_ALU-1:0] x1_buff;          // buffer X1
    reg signed [DATA_ALU-1:0] nx_x1_buff;       // next buffer X1
    reg signed [DATA_ALU-1:0] x1_1_buff;        // buffer X1_1 (intermediate results)
    reg signed [DATA_ALU-1:0] nx_x1_1_buff;     // next buffer X1_1 (intermediate results)
    reg signed [DATA_ALU-1:0] x2_buff;          // buffer X2  
    reg signed [DATA_ALU-1:0] nx_x2_buff;       // next buffer X2
    reg signed [DATA_ALU-1:0] x3_buff;          // buffer X3
    reg signed[DATA_ALU-1:0]  nx_x3_buff;       // next buffer X3
    reg signed [DATA_ALU-1:0] b3_buff;          // buffer B3
    reg signed [DATA_ALU-1:0] nx_b3_buff;       // next buffer B3
    reg [DATA_ALU-1:0]        b4_buff;          // buffer B4
    reg [DATA_ALU-1:0]        nx_b4_buff;       // next buffer B4
    reg signed [DATA_ALU-1:0] b5_buff;          // buffer B5
    reg signed [DATA_ALU-1:0] nx_b5_buff;       // next buffer B5
    reg signed [DATA_ALU-1:0] b6_buff;          // buffer B6
    reg signed [DATA_ALU-1:0] nx_b6_buff;       // next buffer B6
    reg [DATA_ALU-1:0]        b7_buff;          // buffer B7
    reg [DATA_ALU-1:0]        nx_b7_buff;       // next buffer B7
    reg signed [DATA_ALU-1:0] p_buff;           // buffer current pressure
    reg signed [DATA_ALU-1:0] nx_p_buff;        // buffer next pressure
    reg signed [15:0]         nx_o_t_value;     // next current temperature
    reg signed [18:0]         nx_o_p_value;     // next current pressure   


//  determining of rissing edge I_FN_DIV
    assign rs_i_fn_div = cr_i_fn_div & !pr_i_fn_div;
    
//  determining the next state of FSM and singals   
    always @(*) begin
      nx_st = st;
      nx_rxd_buff = rxd_buff;
      nx_o_fl = O_FL;
      nx_o_we = O_WE;  
      nx_o_addr_opm = O_ADDR_OPM;
      nx_o_data_wr_opm = O_DATA_WR_OPM;
      nx_cnt_calc = cnt_calc;
      nx_o_a = O_A;
      nx_o_b = O_B;
      nx_o_op = O_OP;
      nx_o_sh = O_SH;
      nx_o_sg = O_SG;
      nx_rsl_sltu = rsl_sltu;
      nx_o_en_div = O_EN_DIV;
      nx_o_num = O_NUM;
      nx_o_den = O_DEN;
      nx_ut_buff = ut_buff;
      nx_up_buff = up_buff;
      nx_x1_buff = x1_buff;
      nx_x1_1_buff = x1_1_buff;
      nx_x2_buff = x2_buff;
      nx_b5_buff = b5_buff;
      nx_b6_buff = b6_buff;
      nx_x3_buff = x3_buff;
      nx_b3_buff = b3_buff;
      nx_b4_buff = b4_buff;
      nx_b7_buff = b7_buff;
      nx_p_buff = p_buff;
      nx_o_t_value = O_T_VALUE;
      nx_o_p_value = O_P_VALUE;
      case (st)
          IDLE_UT   : begin
                        if (I_UT_CALC)
                          begin
                            nx_rxd_buff = I_RXD_BUFF;
                            nx_st = T_ST_CALC;
                            nx_o_fl = 2'b11;
                          end
                      end
          T_ST_CALC : begin
                        nx_cnt_calc = cnt_calc + 1'b1;
                        case (cnt_calc)
                            0       : begin                                          // MSB << 8; (1a)
                                        nx_o_a = rxd_buff[15:8];
                                        nx_o_sh = 8;
                                        nx_o_op = `ALU_SLL;
                                        nx_o_addr_opm = AC6;                         // unsigned short
                                      end
                            1       : begin                                          // (1a) + LSB; UT = MSB << 8 + LSB; (1) - long
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = {{24{rxd_buff[7]}}, rxd_buff[7:0]};
                                        nx_o_op = `ALU_ADD;
                                        nx_o_addr_opm = AC5;                         // unsigned short
                                      end
                            2       : begin                                          // UT - AC6; (3a)
                                        nx_ut_buff = I_RSL_ALU[15:0];                // latching UT
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = {16'b0, I_DATA_RAM};
                                        nx_o_op = `ALU_SUB;
                                      end
                            3       : begin                                          // (3a) * AC5; (3b)
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = {16'b0, I_DATA_RAM};
                                        nx_o_sg = 1'b1;
                                        nx_o_addr_opm = MC;    
                                      end
                            4       : begin                                          // (3b) / 2^15; X1 = (UT - AC6) * AC5 / 2^15; (3) - long
                                        nx_o_a = I_RSL_MULT;
                                        nx_o_sh = 15;
                                        nx_o_op = `ALU_SRA;
                                        nx_o_addr_opm = MD;                          // short  
                                      end
                            5       : begin                                          // MC * 2^11; (4a)
                                        nx_x1_buff = I_RSL_ALU;                      // latching X1
                                        nx_o_a = {{16{I_DATA_RAM[15]}}, I_DATA_RAM};
                                        nx_o_sh = 11;
                                        nx_o_op = `ALU_SLL;
                                      end
                            6       : begin                                          // X1 + MD; (4b)
                                        nx_x2_buff = I_RSL_ALU;                      // latching X2
                                        nx_o_a = x1_buff;
                                        nx_o_b = {{16{I_DATA_RAM[15]}}, I_DATA_RAM};
                                        nx_o_op = `ALU_ADD;
                                      end
                            7       : begin                                          // (4a) / (4b); X2 = MC * 2^11 / (X1 + MD); (4) - long
                                        nx_o_num = {x2_buff[DATA_ALU-1], x2_buff};
                                        nx_o_den = {I_RSL_ALU[DATA_ALU-1], I_RSL_ALU};
                                        nx_o_en_div = 1'b1;
                                      end
                            default : begin
                                        nx_o_en_div = 1'b0;
                                        nx_cnt_calc = 5'b0;
                                      end 
                        endcase 
                        if (rs_i_fn_div)   // B5 = X1 + X2; (5) - long
                          begin
                            nx_x2_buff = I_RSL_DIV[DATA_ALU-1:0];  // latching X2
                            nx_o_a = I_RSL_DIV[DATA_ALU-1:0];
                            nx_o_b = x1_buff;
                            nx_o_op = `ALU_ADD;
                            nx_cnt_calc = 5'b0;
                            nx_o_en_div = 1'b0;
                            nx_st = T_FN_CALC;
                          end
                      end
          T_FN_CALC : begin
                        nx_cnt_calc = cnt_calc + 1'b1;
                        case (cnt_calc)
                            0       : begin                                          // B5 + 8; (6a)
                                        nx_b5_buff = I_RSL_ALU;                      // latching B5
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = 8;
                                        nx_o_op = `ALU_ADD;
                                      end
                            1       : begin                                          // (6a) / 2^4; T = (B5 + 8) / 2^4 ; (6) - long
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_sh = 4;
                                        nx_o_op = `ALU_SRA;
                                      end
                            2       : begin                                          // B6 = B5 - 4000; (7) - long
                                        nx_o_t_value = I_RSL_ALU[15:0];              // latching T
                                        nx_o_fl[0] = 1'b0;
                                        nx_o_a = b5_buff;
                                        nx_o_b = 4000;
                                        nx_o_op = `ALU_SUB;
                                        nx_o_addr_opm = T_CURR;
                                        nx_o_we = 1'b1;
                                        nx_o_data_wr_opm = I_RSL_ALU[15:0];
                                      end
                            3       : begin                                          // B6 * B6; (8a)
                                        nx_b6_buff = I_RSL_ALU;                      // latching B6
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = I_RSL_ALU;
                                        nx_o_sg = 1'b1;
                                        nx_o_addr_opm = B2;                          // short 
                                        nx_o_we = 1'b0;
                                      end
                            4       : begin                                          // (8a) / 2^12; (8b)
                                        nx_o_a = I_RSL_MULT;
                                        nx_o_sh = 12;
                                        nx_o_op = `ALU_SRA; 
                                      end
                            5       : begin                                          // B2 * (8b); (8c)
                                        nx_x1_1_buff = I_RSL_ALU;                    // latching (8b)
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = {{16{I_DATA_RAM[15]}}, I_DATA_RAM};
                                        nx_o_sg = 1'b1;
                                        nx_o_addr_opm = AC2;                         // short 
                                      end   
                            6       : begin                                          // (8c) / 2^11; X1 = (B2 * (B6 * B6 / 2^12)) / 2^11; (8) - long
                                        nx_o_a = I_RSL_MULT;
                                        nx_o_sh = 11;
                                        nx_o_op = `ALU_SRA;
                                      end                                               
                            7       : begin                                          // AC2 * B6; (9a)
                                        nx_x1_buff = I_RSL_ALU;                      // latching X1
                                        nx_o_a = {{16{I_DATA_RAM[15]}}, I_DATA_RAM};
                                        nx_o_b = b6_buff;
                                        nx_o_sg = 1'b1;
                                      end
                            8       : begin                                          // (9a) / 2^11; X2 = AC2 * B6 / 2^11; (9) - long
                                        nx_o_a = I_RSL_MULT;
                                        nx_o_sh = 11;
                                        nx_o_op = `ALU_SRA;
                                        nx_o_addr_opm = AC1;                         // short 
                                      end
                            9       : begin                                          // X3 = X1 + X2; (10) - long
                                        nx_x2_buff = I_RSL_ALU;                      // latching X2
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = x1_buff;
                                        nx_o_op = `ALU_ADD;
                                      end
                            10      : begin                                          // AC1 * 4; (11a)
                                        nx_x3_buff = I_RSL_ALU;                      // latching X3
                                        nx_o_a = {{16{I_DATA_RAM[15]}}, I_DATA_RAM};
                                        nx_o_sh = 2;
                                        nx_o_op = `ALU_SLL;
                                      end
                            11      : begin                                          // (11a) + X3; (11b)
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = x3_buff;
                                        nx_o_op = `ALU_ADD;
                                      end
                            12      : begin                                          // (11b) << OSS; (11c)
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_sh = I_OSS;                  
                                        nx_o_op = `ALU_SLL;
                                      end
                            13      : begin                                          // (11c) + 2; (11d)
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = 2;
                                        nx_o_op = `ALU_ADD;
                                        nx_o_addr_opm = AC3;                         // short 
                                      end
                            14      : begin                                          // (11d) / 4; B3 = (((AC1 * 4 + X3) << OSS) + 2) / 4; (11) - long
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_sh = 2;
                                        nx_o_op = `ALU_SRA;
                                      end
                            15      : begin                                          // AC3 * B6; (12a)
                                        nx_b3_buff = I_RSL_ALU;                      // latching B3
                                        nx_o_a = {{16{I_DATA_RAM[15]}}, I_DATA_RAM};
                                        nx_o_b = b6_buff;
                                        nx_o_sg = 1'b1;
                                        nx_o_addr_opm = B1;                          // short 
                                      end
                            16      : begin                                          // (12a) / 2^13; X1 = AC3 * B6 / 2^13; (12) - long
                                        nx_o_a = I_RSL_MULT;
                                        nx_o_sh = 13;
                                        nx_o_op = `ALU_SRA;
                                      end
                            17      : begin                                          // B1 * (B6 * B6 / 2^12); (13a)
                                        nx_x1_buff = I_RSL_ALU;                      // latching X1
                                        nx_o_a = x1_1_buff;
                                        nx_o_b = {{16{I_DATA_RAM[15]}}, I_DATA_RAM};
                                        nx_o_sg = 1'b1;
                                      end
                            18      : begin                                          // (13a) / 2^16; X2 = (B1 * (B6 * B6 / 2^12)) / 2^16; (13) - long
                                        nx_o_a = I_RSL_MULT;
                                        nx_o_sh = 16;
                                        nx_o_op = `ALU_SRA;
                                      end                                               
                            19      : begin                                          // X1 + X2; (14a)
                                        nx_x2_buff = I_RSL_ALU;                      // latching X2
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = x1_buff;
                                        nx_o_op = `ALU_ADD;
                                      end
                            20      : begin                                          // (14a) + 2; (14b)
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = 2;
                                        nx_o_op = `ALU_ADD;
                                      end
                            21      : begin                                          // (14b) / 2^2; X3 = ((X2 + X2) + 2) / 2^2; (14) - long
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_sh = 2;
                                        nx_o_op = `ALU_SRA;
                                        nx_o_addr_opm = AC4;                         // unsigned short 
                                      end
                            22      : begin                                          // (unsigned long)(X3 + 32768); (15a)
                                        nx_x3_buff = I_RSL_ALU;                      // latching X3
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = 32768;
                                        nx_o_op = `ALU_ADDU;
                                      end
                            23      : begin                                          // (15a) * AC4; (15b)
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = {16'b0, I_DATA_RAM};
                                        nx_o_sg = 1'b0;
                                      end
                            24      : begin                                          // (15b) / 2^15; B4 = AC4 * (unsigned)(X3 + 32768) / 2^15; (15) - unsigned long
                                        nx_o_a = I_RSL_MULT;
                                        nx_o_sh = 15;
                                        nx_o_op = `ALU_SRL;
                                      end                                               
                            25      : begin
                                        nx_b4_buff = I_RSL_ALU;                      // latching B4
                                        nx_cnt_calc = 5'b0;
                                        nx_st = IDLE_UP;
                                      end 
                            default : begin
                                        nx_cnt_calc = 5'b0;
                                      end  
                        endcase          
                      end
          IDLE_UP   : begin
                        if (I_UP_CALC)
                          begin
                            nx_rxd_buff = I_RXD_BUFF;
                            nx_st = P_ST_CALC;
                          end                             
                      end
          P_ST_CALC : begin
                        nx_cnt_calc = cnt_calc + 1'b1;
                        case (cnt_calc)
                            0       : begin                                          // MSB << 16; (2a)
                                        nx_o_a = rxd_buff[23:16];
                                        nx_o_sh = 16;
                                        nx_o_op = `ALU_SLL;
                                      end
                            1       : begin                                          // LSB << 8; (2b)
                                        nx_up_buff = I_RSL_ALU;                      // latching UP
                                        nx_o_a = rxd_buff[15:8];
                                        nx_o_sh = 8;
                                        nx_o_op = `ALU_SLL;
                                      end
                            2       : begin                                          // (2a) + (2b); (2c)
                                        nx_o_a = up_buff;
                                        nx_o_b = I_RSL_ALU;
                                        nx_o_op = `ALU_ADD;
                                      end
                            3       : begin                                          // (2c) + XLSB; (2d)
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = {{24{rxd_buff[7]}}, rxd_buff[7:0]};
                                        nx_o_op = `ALU_ADD;
                                      end
                            4       : begin                                          // (2d) >> (8 - oss); UP = (MSB << 16 + LSB << 8 + XLSB) >> (8 - oss); (2) - long
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_sh = 4'd8 - I_OSS;
                                        nx_o_op = `ALU_SRA;                                      
                                      end
                            5       : begin                                          // (unsigned)UP - B3; (16a)
                                        nx_up_buff = I_RSL_ALU;                      // latching UP
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = b3_buff;
                                        nx_o_op = `ALU_SUBU;
                                      end
                            6       : begin                                          // 50_000 >> OSS; (16b)
                                        nx_b7_buff = I_RSL_ALU;                      // latching B7
                                        nx_o_a = 50000;
                                        nx_o_sh = I_OSS;
                                        nx_o_op = `ALU_SRL;
                                      end
                            7       : begin                                          // (16a) * (16b); B7 = ((unsigned)UP - B3) * (50_000 >> OSS); (16) - unsigned long
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = b7_buff;
                                        nx_o_sg = 1'b0;
                                      end    
                            8       : begin
                                        nx_b7_buff = I_RSL_MULT;
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = 32'h80000000;
                                        nx_o_op = `ALU_SLTU;
                                      end
                                      
                            9       : begin
                                        nx_o_den = {1'b0, b4_buff};
                                        nx_o_en_div = 1'b1;
                                        nx_cnt_calc = 5'b0;
                                        nx_rsl_sltu = I_RSL_ALU[0];
                                        if (I_RSL_ALU[0])                            // p = (B7 * 2) / B4; (17) - long     
                                          nx_o_num = {b7_buff, 1'b0};                // B7 * 2; (17a) // может быть переполнение в div32 
                                        else                                         // p = (B7 / B4); (17) - long
                                          nx_o_num = {1'b0, b7_buff};                
                                      end                                                                                            
                            default : begin
                                        nx_o_en_div = 1'b0;
                                        nx_cnt_calc = 5'b0;
                                      end                                                                                   
                        endcase  
                        if (rs_i_fn_div)
                          begin
                            nx_o_en_div = 1'b0;
                            nx_st = P_FN_CALC;
                            nx_cnt_calc = 5'b0;
                          end
                      end
          P_FN_CALC : begin
                        nx_cnt_calc = cnt_calc + 1'b1;
                        case (cnt_calc)
                            0       : begin                                              // p / 2^8; (18a)
                                        nx_o_sh = 8;
                                        nx_o_op = `ALU_SRA;
                                        if (rsl_sltu) 
                                          begin
                                            nx_p_buff = I_RSL_DIV[DATA_ALU-1:0];         // latching p 
                                            nx_o_a = I_RSL_DIV[DATA_ALU-1:0];
                                          end
                                        else                        
                                          begin
                                            nx_p_buff = {I_RSL_DIV[DATA_ALU-2:0], 1'b0}; // latching p
                                            nx_o_a = {I_RSL_DIV[DATA_ALU-2:0], 1'b0};
                                          end
                                      end                        
                            1       : begin                              // (18a) * (18a); X1 = (p / 2^11) * (p / 2^11); (18) - long
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = I_RSL_ALU;
                                        nx_o_sg = 1'b1;
                                      end
                            2       : begin                              // X1 * 3038; (19a)
                                        nx_x1_buff = I_RSL_MULT;         // latching X1
                                        nx_o_a = I_RSL_MULT;
                                        nx_o_b = 3038;
                                        nx_o_sg = 1'b1;
                                      end
                            3       : begin                              // (19a) / 2^16; X1 = (X1 * 3038) / 2^16; (19) - long
                                        nx_o_a = I_RSL_MULT;
                                        nx_o_sh = 16;
                                        nx_o_op = `ALU_SRA;
                                      end
                            4       : begin                              // -7357 * p; (20a);
                                        nx_x1_buff = I_RSL_ALU;          // latching X1
                                        nx_o_a = -32'd7357;              // -7357
                                        nx_o_b = p_buff;
                                        nx_o_sg = 1'b1;
                                      end
                            5       : begin                              // (20a) / 2^16; X2 = (-7357 * p) / 2^16; (20) - long
                                        nx_o_a = I_RSL_MULT;
                                        nx_o_sh = 16;
                                        nx_o_op = `ALU_SRA;
                                      end                                               
                            6       : begin                              // X1 + X2; (21a)
                                        nx_x2_buff = I_RSL_ALU;          // latching X2 
                                        nx_o_a = x1_buff;
                                        nx_o_b = I_RSL_ALU;
                                        nx_o_op = `ALU_ADD;
                                      end
                            7       : begin                              // (21a) + 3791; (21b)
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = 3791;
                                        nx_o_op = `ALU_ADD;
                                      end
                            8       : begin                              // (21b) / 2^4; (21c)
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_sh = 4;
                                        nx_o_op = `ALU_SRA;
                                      end
                            9       : begin                              // (21c) + p; p = p + (X2 + X2 + 3791) / 2^4; (21) - long
                                        nx_o_a = I_RSL_ALU;
                                        nx_o_b = p_buff;
                                        nx_o_op = `ALU_ADD;
                                      end
                            10      : begin
                                        nx_p_buff = I_RSL_ALU;           // latching p
                                        nx_o_addr_opm = P_MSB;
                                        nx_o_we = 1'b1;
                                        nx_o_data_wr_opm = I_RSL_ALU[31:16];                                                 
                                      end
                            11      : begin
                                        nx_o_p_value = p_buff[18:0];     // latching p
                                        nx_o_addr_opm = P_LSB;
                                        nx_o_we = 1'b1;
                                        nx_o_data_wr_opm = p_buff[15:0];                                                   
                                      end
                            12      : begin
                                        nx_cnt_calc = 5'b0;
                                        nx_o_we = 1'b0;
                                        nx_st = IDLE_UT;
                                        nx_o_fl[1] = 1'b0;                                        
                                      end
                            default : begin
                                        nx_cnt_calc = 5'b0;
                                      end
                        endcase         
                      end
          default   : begin
                        nx_st = IDLE_UT;
                        nx_rxd_buff = {RXD_SZ{1'b0}};
                        nx_o_fl = 2'b0;
                        nx_o_we = 1'b0;
                        nx_o_addr_opm = {ADDR_OPM_SZ{1'b0}};
                        nx_o_data_wr_opm = {DATA_OPM_SZ{1'b0}}; 
                        nx_cnt_calc = 5'b0;
                        nx_o_a = {DATA_ALU{1'b0}};
                        nx_o_b = {DATA_ALU{1'b0}};
                        nx_o_op = {OP_SZ{1'b0}};
                        nx_o_sh = {SH_SZ{1'b0}};
                        nx_o_sg = 1'b0;
                        nx_rsl_sltu = 1'b0;
                        nx_o_en_div = 1'b0;
                        nx_o_num = {DATA_DIV{1'b0}};
                        nx_o_den = {DATA_DIV{1'b0}};
                        nx_ut_buff = 16'b0;
                        nx_up_buff = {DATA_ALU{1'b0}};
                        nx_x1_buff = {DATA_ALU{1'b0}};
                        nx_x1_1_buff = {DATA_ALU{1'b0}};
                        nx_x2_buff = {DATA_ALU{1'b0}};
                        nx_b5_buff = {DATA_ALU{1'b0}};
                        nx_b6_buff = {DATA_ALU{1'b0}};
                        nx_x3_buff = {DATA_ALU{1'b0}};
                        nx_b3_buff = {DATA_ALU{1'b0}};
                        nx_b4_buff = {DATA_ALU{1'b0}};
                        nx_b7_buff = {DATA_ALU{1'b0}};
                        nx_p_buff = {DATA_ALU{1'b0}};
                        nx_o_t_value = 16'b0;
                        nx_o_p_value = 19'b0;
                      end
      endcase
    end 
    
//  latching the next state of FSM and signals, every clock     
    always @(posedge CLK or negedge RST_n) begin
      if (!RST_n)
        begin
          st            <= IDLE_UT;     
          rxd_buff      <= {RXD_SZ{1'b0}};          
          O_FL          <= 2'b0;
          O_WE          <= 1'b0;          
          O_ADDR_OPM    <= {ADDR_OPM_SZ{1'b0}};
          O_DATA_WR_OPM <= {DATA_OPM_SZ{1'b0}};
          cnt_calc      <= 5'b0;
          O_A           <= {DATA_ALU{1'b0}};
          O_B           <= {DATA_ALU{1'b0}};
          O_OP          <= {OP_SZ{1'b0}};
          O_SH          <= {SH_SZ{1'b0}};
          O_SG          <= 1'b0;
          rsl_sltu      <= 1'b0;
          O_EN_DIV      <= 1'b0;
          O_NUM         <= {DATA_DIV{1'b0}};
          O_DEN         <= {DATA_DIV{1'b0}};
          cr_i_fn_div   <= 1'b0;
          pr_i_fn_div   <= 1'b0;
          ut_buff       <= 16'b0;
          up_buff       <= {DATA_ALU{1'b0}};
          x1_buff       <= {DATA_ALU{1'b0}};
          x1_1_buff     <= {DATA_ALU{1'b0}};
          x2_buff       <= {DATA_ALU{1'b0}};
          b5_buff       <= {DATA_ALU{1'b0}};
          b6_buff       <= {DATA_ALU{1'b0}};
          x3_buff       <= {DATA_ALU{1'b0}};
          b3_buff       <= {DATA_ALU{1'b0}};
          b4_buff       <= {DATA_ALU{1'b0}};
          b7_buff       <= {DATA_ALU{1'b0}};
          p_buff        <= {DATA_ALU{1'b0}};
          O_T_VALUE     <= 16'b0;
          O_P_VALUE     <= 19'b0;
        end
      else
        begin
          st            <= nx_st;        
          rxd_buff      <= nx_rxd_buff;            
          O_FL          <= nx_o_fl;
          O_WE          <= nx_o_we;          
          O_ADDR_OPM    <= nx_o_addr_opm; 
          O_DATA_WR_OPM <= nx_o_data_wr_opm;
          cnt_calc      <= nx_cnt_calc;
          O_A           <= nx_o_a;
          O_B           <= nx_o_b;
          O_OP          <= nx_o_op;
          O_SH          <= nx_o_sh;
          O_SG          <= nx_o_sg;
          rsl_sltu      <= nx_rsl_sltu;
          O_EN_DIV      <= nx_o_en_div;
          O_NUM         <= nx_o_num;
          O_DEN         <= nx_o_den;
          cr_i_fn_div   <= I_FN_DIV;
          pr_i_fn_div   <= cr_i_fn_div;
          ut_buff       <= nx_ut_buff;
          up_buff       <= nx_up_buff;
          x1_buff       <= nx_x1_buff;
          x1_1_buff     <= nx_x1_1_buff;
          x2_buff       <= nx_x2_buff;
          b5_buff       <= nx_b5_buff;
          b6_buff       <= nx_b6_buff;
          x3_buff       <= nx_x3_buff;
          b3_buff       <= nx_b3_buff;
          b4_buff       <= nx_b4_buff;
          b7_buff       <= nx_b7_buff;
          p_buff        <= nx_p_buff;
          O_T_VALUE     <= nx_o_t_value;
          O_P_VALUE     <= nx_o_p_value;
        end
    end


endmodule