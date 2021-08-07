module db_bmp180
    #(parameter FPGA_CLK = 50_000_000,   // FPGA frequency 50 MHz
      parameter I2C_CLK  = 100_000)      // I2C bus frequency 100 KHz  
    (CLK, I_KEY, I_SW, 
     O_LEDR, 
     IO_SCL, IO_SDA);


//  input signals
    input wire       CLK;    // clock 50 MHz
    input wire [1:0] I_KEY;
    input wire [6:0] I_SW;
//  output signals
    output reg [9:0] O_LEDR;
//  inout signals
    inout wire       IO_SCL; // serial clock I2C bus 
    inout wire       IO_SDA; // serial data I2C bus   
//  internal signals  
    wire               RST_n;
    wire [3:0]         comm;
    wire signed [15:0] t_value; // current temperature
    wire signed [18:0] p_value; // current pressure   
    wire               ack;
    wire               err;
    
//--------------------------------------------------------------------------
    top_bmp180 
        #(
         .FPGA_CLK(FPGA_CLK),
         .I2C_CLK(I2C_CLK)
        )
    top_bmp180 
        (
         .CLK(CLK), 
         .RST_n(RST_n), 
         .I_COMM(comm), 
         .O_FL(),
         .O_T_VALUE(t_value),
         .O_P_VALUE(p_value),
         .O_ACK_FL(ack),
         .O_CNT_RS_ACK_FL(),
         .O_ERR(err),
         .O_CNT_RS_ERR(),
         .IO_SCL(IO_SCL), 
         .IO_SDA(IO_SDA)
        );

//--------------------------------------------------------------------------
    assign RST_n = I_KEY[1];
    assign comm = ~I_KEY[0] ? I_SW[3:0] : 4'b0;
    always @(posedge CLK or negedge RST_n) begin
      if (!RST_n) 
        begin
          O_LEDR[9:0] <= 10'b0;
        end
      else
        begin
          case (I_SW[6:4])
              0 : O_LEDR[9:0] <= {err, ack, t_value[15:8]};
              1 : O_LEDR[9:0] <= {err, ack, t_value[7:0]};
              2 : O_LEDR[9:0] <= {err, ack, 3'b0, p_value[18:16]};
              3 : O_LEDR[9:0] <= {err, ack, p_value[15:8]};
              4 : O_LEDR[9:0] <= {err, ack, p_value[7:0]};
              default : O_LEDR[9:0] <= 10'b0;
          endcase
        end
    end

    
endmodule