`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2024 03:23:25 PM
// Design Name: 
// Module Name: transmitter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module transmitter(
    input qspi_clk,
    input qspi_rst,
    
    input qspi_basic_mode_req,
    input memory_mapped_mode_req,
    
    input [7:0] qspi_cmd,
    input [7:0] qspi_cfg,
    input [31:0] qspi_addr,
    input [31:0] memory_mapped_mode_addr,
    input [31:0] tx_fifo_data,
    
    input [3:0] next_state,
    
    input ddr_en,
    input t_ddr_en,
    input [1:0] t_phase_mode,
    input [1:0] phase_mode,
    
    input next_phase_active,
    input t_transmit_en,
    input data_update,
    
    input qspi_out2,
    input qspi_out3,
    
    input [8:0] qspi_data_length,
    input [2:0] qspi_addr_length,
    
    input [8:0] data_byte_counter,
    
    output reg [3:0]qio_out

    );
    
    parameter 
    IDLE = 4'h0,
    TX_COMMAND = 4'h1,
    TX_ADDRESS = 4'h2,
    TX_ALTERNATE = 4'h3,
    DUMMY = 4'h4,
    TURN_AROUND = 4'h5,
    TX_DATA = 4'h6,
    RX_DATA = 4'h7,
    CHIP_SELECT_HIGH_TIME = 4'h8;
    
    
    parameter SSPI = 2'h0,
              DSPI = 2'h1,
              QSPI = 2'h2;
    
    //reg [31:0] DATA_IN;
    
    reg [31:0] FE;
    reg [15:0] RE;
    
    
    wire [31:0] address_data;
    
    assign address_data = (qspi_basic_mode_req)? qspi_addr: (memory_mapped_mode_req) ? memory_mapped_mode_addr: 32'b0 ;
    
    always@(negedge qspi_clk) begin
       if(qspi_rst) begin
            FE = 32'b0;
            RE = 32'b0;
       end else if(t_transmit_en) begin
           if(next_phase_active) begin
               case(next_state)
                   TX_COMMAND: begin
                      case (t_phase_mode)
                        SSPI: FE[7:0] <= {qspi_cmd[0],qspi_cmd[1],qspi_cmd[2],qspi_cmd[3],
                                          qspi_cmd[4],qspi_cmd[5],qspi_cmd[6],qspi_cmd[7]};
                        DSPI: FE[7:0] <= {qspi_cmd[0],qspi_cmd[1],qspi_cmd[3],qspi_cmd[2],
                                          qspi_cmd[5],qspi_cmd[4],qspi_cmd[7],qspi_cmd[6]};
                        QSPI: FE[7:0] <=  {qspi_cmd[3],qspi_cmd[2],qspi_cmd[1],qspi_cmd[0],
                                          qspi_cmd[7],qspi_cmd[6],qspi_cmd[5],qspi_cmd[4]};
                      endcase
                   end
                   TX_ALTERNATE: begin
                      if (~t_ddr_en) begin
                            case (t_phase_mode)
                                SSPI: FE[7:0] <= {qspi_cfg[0], qspi_cfg[1], qspi_cfg[2], qspi_cfg[3],
                                                  qspi_cfg[4], qspi_cfg[5], qspi_cfg[6], qspi_cfg[7]};
                                DSPI: FE[7:0] <= {qspi_cfg[1], qspi_cfg[0], qspi_cfg[3], qspi_cfg[2],
                                                  qspi_cfg[5], qspi_cfg[4], qspi_cfg[7], qspi_cfg[6]};
                                QSPI: FE[7:0] <= {qspi_cfg[3], qspi_cfg[2], qspi_cfg[1], qspi_cfg[0],
                                                  qspi_cfg[7], qspi_cfg[6], qspi_cfg[5], qspi_cfg[4]};
                            endcase
                        end else begin
                            case (t_phase_mode)
                                SSPI: begin
                                    FE[3:0] <= {qspi_cfg[1], qspi_cfg[3], qspi_cfg[5], qspi_cfg[7]};
                                    RE[3:0] <= {qspi_cfg[0], qspi_cfg[2], qspi_cfg[4], qspi_cfg[6]};
                                end
                                DSPI: begin
                                    FE[3:0] <= {qspi_cfg[3], qspi_cfg[2], qspi_cfg[7], qspi_cfg[6]};
                                    RE[3:0] <= {qspi_cfg[1], qspi_cfg[0], qspi_cfg[5], qspi_cfg[4]};
                                end
                                QSPI: begin
                                    FE[3:0] <= {qspi_cfg[7], qspi_cfg[6], qspi_cfg[5], qspi_cfg[4]};
                                    RE[3:0] <= {qspi_cfg[3], qspi_cfg[2], qspi_cfg[1], qspi_cfg[0]};
                                end
                            endcase
                        end
                   end
                   TX_ADDRESS: begin
                       if(~t_ddr_en) begin
                          if (qspi_addr_length == 4) begin
                                case (t_phase_mode)
                                    SSPI: FE <= {address_data[0], address_data[1], address_data[2], address_data[3],
                                                 address_data[4], address_data[5], address_data[6], address_data[7],
                                                 address_data[8], address_data[9], address_data[10], address_data[11],
                                                 address_data[12], address_data[13], address_data[14], address_data[15],
                                                 address_data[16], address_data[17], address_data[18], address_data[19],
                                                 address_data[20], address_data[21], address_data[22], address_data[23],
                                                 address_data[24], address_data[25], address_data[26], address_data[27],
                                                 address_data[28], address_data[29], address_data[30], address_data[31]};
                                    DSPI: FE <= {address_data[1], address_data[0], address_data[3], address_data[2],
                                                 address_data[5], address_data[4], address_data[7], address_data[6],
                                                 address_data[9], address_data[8], address_data[11], address_data[10],
                                                 address_data[13], address_data[12], address_data[15], address_data[14],
                                                 address_data[17], address_data[16], address_data[19], address_data[18],
                                                 address_data[21], address_data[20], address_data[23], address_data[22],
                                                 address_data[25], address_data[24], address_data[27], address_data[26],
                                                 address_data[29], address_data[28], address_data[31], address_data[30]};
                                    QSPI: FE <= {address_data[3], address_data[2], address_data[1], address_data[0],
                                                 address_data[7], address_data[6], address_data[5], address_data[4],
                                                 address_data[11], address_data[10], address_data[9], address_data[8],
                                                 address_data[15], address_data[14], address_data[13], address_data[12],
                                                 address_data[19], address_data[18], address_data[17], address_data[16],
                                                 address_data[23], address_data[22], address_data[21], address_data[20],
                                                 address_data[27], address_data[26], address_data[25], address_data[24],
                                                 address_data[31], address_data[30], address_data[29], address_data[28]};
                                endcase
                            end else if (qspi_addr_length == 3) begin
                                case (t_phase_mode)
                                    SSPI: FE[23:0] <= {address_data[0], address_data[1], address_data[2], address_data[3],
                                                       address_data[4], address_data[5], address_data[6], address_data[7],
                                                       address_data[8], address_data[9], address_data[10], address_data[11],
                                                       address_data[12], address_data[13], address_data[14], address_data[15],
                                                       address_data[16], address_data[17], address_data[18], address_data[19],
                                                       address_data[20], address_data[21], address_data[22], address_data[23]};
                                    DSPI: FE[23:0] <= {address_data[1], address_data[0], address_data[3], address_data[2],
                                                       address_data[5], address_data[4], address_data[7], address_data[6],
                                                       address_data[9], address_data[8], address_data[11], address_data[10],
                                                       address_data[13], address_data[12], address_data[15], address_data[14],
                                                       address_data[17], address_data[16], address_data[19], address_data[18],
                                                       address_data[21], address_data[20], address_data[23], address_data[22]};
                                    QSPI: FE[23:0] <= {address_data[3], address_data[2], address_data[1], address_data[0],
                                                       address_data[7], address_data[6], address_data[5], address_data[4],
                                                       address_data[11], address_data[10], address_data[9], address_data[8],
                                                       address_data[15], address_data[14], address_data[13], address_data[12],
                                                       address_data[19], address_data[18], address_data[17], address_data[16],
                                                       address_data[23], address_data[22], address_data[21], address_data[20]};
                                endcase
                            end else if (qspi_addr_length == 2) begin
                                case (t_phase_mode)
                                    SSPI: FE[15:0] <= {address_data[0], address_data[1], address_data[2], address_data[3],
                                                       address_data[4], address_data[5], address_data[6], address_data[7],
                                                       address_data[8], address_data[9], address_data[10], address_data[11],
                                                       address_data[12], address_data[13], address_data[14], address_data[15]};
                                    DSPI: FE[15:0] <= {address_data[1], address_data[0], address_data[3], address_data[2],
                                                       address_data[5], address_data[4], address_data[7], address_data[6],
                                                       address_data[9], address_data[8], address_data[11], address_data[10],
                                                       address_data[13], address_data[12], address_data[15], address_data[14]};
                                    QSPI: FE[15:0] <= {address_data[3], address_data[2], address_data[1], address_data[0],
                                                       address_data[7], address_data[6], address_data[5], address_data[4],
                                                       address_data[11], address_data[10], address_data[9], address_data[8],
                                                       address_data[15], address_data[14], address_data[13], address_data[12]};
                                endcase
                            end else if (qspi_addr_length == 1) begin
                                case (t_phase_mode)
                                    SSPI: FE[7:0] <= {address_data[0], address_data[1], address_data[2], address_data[3],
                                                      address_data[4], address_data[5], address_data[6], address_data[7]};
                                    DSPI: FE[7:0] <= {address_data[1], address_data[0], address_data[3], address_data[2],
                                                      address_data[5], address_data[4], address_data[7], address_data[6]};
                                    QSPI: FE[7:0] <= {address_data[3], address_data[2], address_data[1], address_data[0],
                                                      address_data[7], address_data[6], address_data[5], address_data[4]};
                                endcase
                            end
                       end else begin
                          case(t_phase_mode)
                            SSPI: begin
                                if(qspi_addr_length == 4) begin
                                   FE[15:0] <= {address_data[1], address_data[3], address_data[5], address_data[7],
                                               address_data[9], address_data[11], address_data[13], address_data[15],
                                               address_data[17], address_data[19], address_data[21], address_data[23],
                                               address_data[25], address_data[27], address_data[29], address_data[31]}; 
                                   RE <= {address_data[0], address_data[2], address_data[4], address_data[6],
                                                address_data[8], address_data[10], address_data[12], address_data[14],
                                                address_data[16], address_data[18], address_data[20], address_data[22],
                                                address_data[24], address_data[26], address_data[28], address_data[30]};  
                                end else if (qspi_addr_length == 3) begin
                                   FE[11:0] <= {address_data[1], address_data[3], address_data[5], address_data[7],
                                               address_data[9], address_data[11], address_data[13], address_data[15],
                                               address_data[17], address_data[19], address_data[21], address_data[23]};
                                   RE[11:0] <= {address_data[0], address_data[2], address_data[4], address_data[6],
                                                address_data[8], address_data[10], address_data[12], address_data[14],
                                                address_data[16], address_data[18], address_data[20], address_data[22]};
                                end else if (qspi_addr_length == 2) begin
                                   FE[7:0] <= {address_data[1], address_data[3], address_data[5], address_data[7],
                                               address_data[9], address_data[11], address_data[13], address_data[15]};
                                   RE[7:0] <= {address_data[0], address_data[2], address_data[4], address_data[6],
                                                address_data[8], address_data[10], address_data[12], address_data[14]};
                                end else if (qspi_addr_length == 1) begin
                                   FE[7:0] <= {address_data[1], address_data[3], address_data[5], address_data[7]};
                                   RE[7:0] <= {address_data[0], address_data[2], address_data[4], address_data[6]};
                                end
                            end
                            DSPI: begin
                                if (qspi_addr_length == 4) begin
                                    FE[15:0] <= {address_data[3], address_data[2], address_data[7], address_data[6],
                                                 address_data[11], address_data[10], address_data[15], address_data[14],
                                                 address_data[19], address_data[18], address_data[23], address_data[22],
                                                 address_data[27], address_data[26], address_data[31], address_data[30]};
                                    RE <= {address_data[1], address_data[0], address_data[5], address_data[4],
                                                 address_data[9], address_data[8], address_data[13], address_data[12],
                                                 address_data[17], address_data[16], address_data[21], address_data[20],
                                                 address_data[25], address_data[24], address_data[29], address_data[28]};
                                end else if (qspi_addr_length == 3) begin
                                    FE[11:0] <= {address_data[3], address_data[2], address_data[7], address_data[6],
                                                 address_data[11], address_data[10], address_data[15], address_data[14],
                                                 address_data[19], address_data[18], address_data[23], address_data[22]};
                                    RE[11:0] <= {address_data[1], address_data[0], address_data[5], address_data[4],
                                                 address_data[9], address_data[8], address_data[13], address_data[12],
                                                 address_data[17], address_data[16], address_data[21], address_data[20]};
                                end else if (qspi_addr_length == 2) begin
                                    FE[7:0] <= {address_data[3], address_data[2], address_data[7], address_data[6],
                                                 address_data[11], address_data[10], address_data[15], address_data[14]};
                                    RE[7:0] <= {address_data[1], address_data[0], address_data[5], address_data[4],
                                                 address_data[9], address_data[8], address_data[13], address_data[12]};
                                end else if (qspi_addr_length == 1) begin
                                    FE[3:0] <= {address_data[3], address_data[2], address_data[7], address_data[6]};
                                    RE[3:0] <= {address_data[1], address_data[0], address_data[5], address_data[4]};
                                end
                            end
                            QSPI: begin
                                if (qspi_addr_length == 4) begin
                                    FE[15:0] <= {address_data[7], address_data[6], address_data[5], address_data[4],
                                                 address_data[15], address_data[14], address_data[13], address_data[12],
                                                 address_data[23], address_data[22], address_data[21], address_data[20],
                                                 address_data[31], address_data[30], address_data[29], address_data[28]};
                                    RE <= {address_data[3], address_data[2], address_data[1], address_data[0],
                                                 address_data[11], address_data[10], address_data[9], address_data[8],
                                                 address_data[19], address_data[18], address_data[17], address_data[16],
                                                 address_data[27], address_data[26], address_data[25], address_data[24]};
                                end else if (qspi_addr_length == 3) begin
                                    FE[11:0] <= {address_data[7], address_data[6], address_data[5], address_data[4],
                                                 address_data[15], address_data[14], address_data[13], address_data[12],
                                                 address_data[23], address_data[22], address_data[21], address_data[20]};
                                    RE[11:0] <= {address_data[3], address_data[2], address_data[1], address_data[0],
                                                 address_data[11], address_data[10], address_data[9], address_data[8],
                                                 address_data[19], address_data[18], address_data[17], address_data[16]};
                                end else if (qspi_addr_length == 2) begin
                                    FE[7:0] <= {address_data[7], address_data[6], address_data[5], address_data[4],
                                                 address_data[15], address_data[14], address_data[13], address_data[12]};
                                    RE[7:0] <= {address_data[3], address_data[2], address_data[1], address_data[0],
                                                 address_data[11], address_data[10], address_data[9], address_data[8]};
                                end else if (qspi_addr_length == 1) begin
                                    FE[3:0] <= {address_data[7], address_data[6], address_data[5], address_data[4]};
                                    RE[3:0] <= {address_data[3], address_data[2], address_data[1], address_data[0]};
                                end
                            end
                          endcase
                       end
                   end
                   
                   TX_DATA: begin
                        if (~t_ddr_en) begin
                            if (qspi_data_length >= 4) begin
                                case (t_phase_mode)
                                    SSPI: FE <= {tx_fifo_data[0], tx_fifo_data[1], tx_fifo_data[2], tx_fifo_data[3],
                                                 tx_fifo_data[4], tx_fifo_data[5], tx_fifo_data[6], tx_fifo_data[7],
                                                 tx_fifo_data[8], tx_fifo_data[9], tx_fifo_data[10], tx_fifo_data[11],
                                                 tx_fifo_data[12], tx_fifo_data[13], tx_fifo_data[14], tx_fifo_data[15],
                                                 tx_fifo_data[16], tx_fifo_data[17], tx_fifo_data[18], tx_fifo_data[19],
                                                 tx_fifo_data[20], tx_fifo_data[21], tx_fifo_data[22], tx_fifo_data[23],
                                                 tx_fifo_data[24], tx_fifo_data[25], tx_fifo_data[26], tx_fifo_data[27],
                                                 tx_fifo_data[28], tx_fifo_data[29], tx_fifo_data[30], tx_fifo_data[31]};
                                    DSPI: FE <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[3], tx_fifo_data[2],
                                                 tx_fifo_data[5], tx_fifo_data[4], tx_fifo_data[7], tx_fifo_data[6],
                                                 tx_fifo_data[9], tx_fifo_data[8], tx_fifo_data[11], tx_fifo_data[10],
                                                 tx_fifo_data[13], tx_fifo_data[12], tx_fifo_data[15], tx_fifo_data[14],
                                                 tx_fifo_data[17], tx_fifo_data[16], tx_fifo_data[19], tx_fifo_data[18],
                                                 tx_fifo_data[21], tx_fifo_data[20], tx_fifo_data[23], tx_fifo_data[22],
                                                 tx_fifo_data[25], tx_fifo_data[24], tx_fifo_data[27], tx_fifo_data[26],
                                                 tx_fifo_data[29], tx_fifo_data[28], tx_fifo_data[31], tx_fifo_data[30]};
                                    QSPI: FE <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                 tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4],
                                                 tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[9], tx_fifo_data[8],
                                                 tx_fifo_data[15], tx_fifo_data[14], tx_fifo_data[13], tx_fifo_data[12],
                                                 tx_fifo_data[19], tx_fifo_data[18], tx_fifo_data[17], tx_fifo_data[16],
                                                 tx_fifo_data[23], tx_fifo_data[22], tx_fifo_data[21], tx_fifo_data[20],
                                                 tx_fifo_data[27], tx_fifo_data[26], tx_fifo_data[25], tx_fifo_data[24],
                                                 tx_fifo_data[31], tx_fifo_data[30], tx_fifo_data[29], tx_fifo_data[28]};
                                endcase
                            end else if (qspi_data_length == 3) begin
                                case (t_phase_mode)
                                    SSPI: FE[23:0] <= {tx_fifo_data[0], tx_fifo_data[1], tx_fifo_data[2], tx_fifo_data[3],
                                                       tx_fifo_data[4], tx_fifo_data[5], tx_fifo_data[6], tx_fifo_data[7],
                                                       tx_fifo_data[8], tx_fifo_data[9], tx_fifo_data[10], tx_fifo_data[11],
                                                       tx_fifo_data[12], tx_fifo_data[13], tx_fifo_data[14], tx_fifo_data[15],
                                                       tx_fifo_data[16], tx_fifo_data[17], tx_fifo_data[18], tx_fifo_data[19],
                                                       tx_fifo_data[20], tx_fifo_data[21], tx_fifo_data[22], tx_fifo_data[23]};
                                    DSPI: FE[23:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[3], tx_fifo_data[2],
                                                       tx_fifo_data[5], tx_fifo_data[4], tx_fifo_data[7], tx_fifo_data[6],
                                                       tx_fifo_data[9], tx_fifo_data[8], tx_fifo_data[11], tx_fifo_data[10],
                                                       tx_fifo_data[13], tx_fifo_data[12], tx_fifo_data[15], tx_fifo_data[14],
                                                       tx_fifo_data[17], tx_fifo_data[16], tx_fifo_data[19], tx_fifo_data[18],
                                                       tx_fifo_data[21], tx_fifo_data[20], tx_fifo_data[23], tx_fifo_data[22]};
                                    QSPI: FE[23:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                       tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4],
                                                       tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[9], tx_fifo_data[8],
                                                       tx_fifo_data[15], tx_fifo_data[14], tx_fifo_data[13], tx_fifo_data[12],
                                                       tx_fifo_data[19], tx_fifo_data[18], tx_fifo_data[17], tx_fifo_data[16],
                                                       tx_fifo_data[23], tx_fifo_data[22], tx_fifo_data[21], tx_fifo_data[20]};
                                endcase
                            end else if (qspi_data_length == 2) begin
                                case (t_phase_mode)
                                    SSPI: FE[15:0] <= {tx_fifo_data[0], tx_fifo_data[1], tx_fifo_data[2], tx_fifo_data[3],
                                                       tx_fifo_data[4], tx_fifo_data[5], tx_fifo_data[6], tx_fifo_data[7],
                                                       tx_fifo_data[8], tx_fifo_data[9], tx_fifo_data[10], tx_fifo_data[11],
                                                       tx_fifo_data[12], tx_fifo_data[13], tx_fifo_data[14], tx_fifo_data[15]};
                                    DSPI: FE[15:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[3], tx_fifo_data[2],
                                                       tx_fifo_data[5], tx_fifo_data[4], tx_fifo_data[7], tx_fifo_data[6],
                                                       tx_fifo_data[9], tx_fifo_data[8], tx_fifo_data[11], tx_fifo_data[10],
                                                       tx_fifo_data[13], tx_fifo_data[12], tx_fifo_data[15], tx_fifo_data[14]};
                                    QSPI: FE[15:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                       tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4],
                                                       tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[9], tx_fifo_data[8],
                                                       tx_fifo_data[15], tx_fifo_data[14], tx_fifo_data[13], tx_fifo_data[12]};
                                endcase
                            end else if (qspi_data_length == 1) begin
                                case (t_phase_mode)
                                    SSPI: FE[7:0] <= {tx_fifo_data[0], tx_fifo_data[1], tx_fifo_data[2], tx_fifo_data[3],
                                                      tx_fifo_data[4], tx_fifo_data[5], tx_fifo_data[6], tx_fifo_data[7]};
                                    DSPI: FE[7:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[3], tx_fifo_data[2],
                                                      tx_fifo_data[5], tx_fifo_data[4], tx_fifo_data[7], tx_fifo_data[6]};
                                    QSPI: FE[7:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                      tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4]};
                                endcase
                            end
                        end else begin
                            case (t_phase_mode)
                                SSPI: begin
                                    if (qspi_data_length >= 4) begin
                                        FE[15:0] <= {tx_fifo_data[1], tx_fifo_data[3], tx_fifo_data[5], tx_fifo_data[7],
                                                     tx_fifo_data[9], tx_fifo_data[11], tx_fifo_data[13], tx_fifo_data[15],
                                                     tx_fifo_data[17], tx_fifo_data[19], tx_fifo_data[21], tx_fifo_data[23],
                                                     tx_fifo_data[25], tx_fifo_data[27], tx_fifo_data[29], tx_fifo_data[31]};
                                        RE <= {tx_fifo_data[0], tx_fifo_data[2], tx_fifo_data[4], tx_fifo_data[6],
                                               tx_fifo_data[8], tx_fifo_data[10], tx_fifo_data[12], tx_fifo_data[14],
                                               tx_fifo_data[16], tx_fifo_data[18], tx_fifo_data[20], tx_fifo_data[22],
                                               tx_fifo_data[24], tx_fifo_data[26], tx_fifo_data[28], tx_fifo_data[30]};
                                    end else if (qspi_data_length == 3) begin
                                        FE[11:0] <= {tx_fifo_data[1], tx_fifo_data[3], tx_fifo_data[5], tx_fifo_data[7],
                                                     tx_fifo_data[9], tx_fifo_data[11], tx_fifo_data[13], tx_fifo_data[15],
                                                     tx_fifo_data[17], tx_fifo_data[19], tx_fifo_data[21], tx_fifo_data[23]};
                                        RE[11:0] <= {tx_fifo_data[0], tx_fifo_data[2], tx_fifo_data[4], tx_fifo_data[6],
                                                     tx_fifo_data[8], tx_fifo_data[10], tx_fifo_data[12], tx_fifo_data[14],
                                                     tx_fifo_data[16], tx_fifo_data[18], tx_fifo_data[20], tx_fifo_data[22]};
                                    end else if (qspi_data_length == 2) begin
                                        FE[7:0] <= {tx_fifo_data[1], tx_fifo_data[3], tx_fifo_data[5], tx_fifo_data[7],
                                                    tx_fifo_data[9], tx_fifo_data[11], tx_fifo_data[13], tx_fifo_data[15]};
                                        RE[7:0] <= {tx_fifo_data[0], tx_fifo_data[2], tx_fifo_data[4], tx_fifo_data[6],
                                                    tx_fifo_data[8], tx_fifo_data[10], tx_fifo_data[12], tx_fifo_data[14]};
                                    end else if (qspi_data_length == 1) begin
                                        FE[3:0] <= {tx_fifo_data[1], tx_fifo_data[3], tx_fifo_data[5], tx_fifo_data[7]};
                                        RE[3:0] <= {tx_fifo_data[0], tx_fifo_data[2], tx_fifo_data[4], tx_fifo_data[6]};
                                    end
                                end
                               DSPI: begin
                                    if (qspi_data_length >= 4) begin
                                        FE[15:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[7], tx_fifo_data[6],
                                                     tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[15], tx_fifo_data[14],
                                                     tx_fifo_data[19], tx_fifo_data[18], tx_fifo_data[23], tx_fifo_data[22],
                                                     tx_fifo_data[27], tx_fifo_data[26], tx_fifo_data[31], tx_fifo_data[30]};
                                        RE[15:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[5], tx_fifo_data[4],
                                                     tx_fifo_data[9], tx_fifo_data[8], tx_fifo_data[13], tx_fifo_data[12],
                                                     tx_fifo_data[17], tx_fifo_data[16], tx_fifo_data[21], tx_fifo_data[20],
                                                     tx_fifo_data[25], tx_fifo_data[24], tx_fifo_data[29], tx_fifo_data[28]};
                                    end else if (qspi_data_length == 3) begin
                                        FE[11:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[7], tx_fifo_data[6],
                                                     tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[15], tx_fifo_data[14],
                                                     tx_fifo_data[19], tx_fifo_data[18], tx_fifo_data[23], tx_fifo_data[22],
                                                     4'b0}; // Padding 4 bits v?i giá tr? 0
                                        RE[11:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[5], tx_fifo_data[4],
                                                     tx_fifo_data[9], tx_fifo_data[8], tx_fifo_data[13], tx_fifo_data[12],
                                                     tx_fifo_data[17], tx_fifo_data[16], tx_fifo_data[21], tx_fifo_data[20],
                                                     4'b0}; // Padding 4 bits v?i giá tr? 0
                                    end else if (qspi_data_length == 2) begin
                                        FE[7:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[7], tx_fifo_data[6],
                                                     tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[15], tx_fifo_data[14],
                                                     8'b0}; // Padding 8 bits v?i giá tr? 0
                                        RE[7:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[5], tx_fifo_data[4],
                                                     tx_fifo_data[9], tx_fifo_data[8], tx_fifo_data[13], tx_fifo_data[12],
                                                     8'b0}; // Padding 8 bits v?i giá tr? 0
                                    end else if (qspi_data_length == 1) begin
                                        FE[3:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[7], tx_fifo_data[6],
                                                     12'b0}; // Padding 12 bits v?i giá tr? 0
                                        RE[3:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[5], tx_fifo_data[4],
                                                     12'b0}; // Padding 12 bits v?i giá tr? 0
                                    end
                                end
                                
                                QSPI: begin
                                    if (qspi_data_length >= 4) begin
                                        FE[15:0] <= {tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4],
                                                     tx_fifo_data[15], tx_fifo_data[14], tx_fifo_data[13], tx_fifo_data[12],
                                                     tx_fifo_data[23], tx_fifo_data[22], tx_fifo_data[21], tx_fifo_data[20],
                                                     tx_fifo_data[31], tx_fifo_data[30], tx_fifo_data[29], tx_fifo_data[28]};
                                        RE[15:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                     tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[9], tx_fifo_data[8],
                                                     tx_fifo_data[19], tx_fifo_data[18], tx_fifo_data[17], tx_fifo_data[16],
                                                     tx_fifo_data[27], tx_fifo_data[26], tx_fifo_data[25], tx_fifo_data[24]};
                                    end else if (qspi_data_length == 3) begin
                                        FE[11:0] <= {tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4],
                                                     tx_fifo_data[15], tx_fifo_data[14], tx_fifo_data[13], tx_fifo_data[12],
                                                     tx_fifo_data[23], tx_fifo_data[22], tx_fifo_data[21], tx_fifo_data[20]};
                                        RE[11:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                     tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[9], tx_fifo_data[8],
                                                     tx_fifo_data[19], tx_fifo_data[18], tx_fifo_data[17], tx_fifo_data[16]};
                                    end else if (qspi_data_length == 2) begin
                                        FE[7:0] <= {tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4],
                                                    tx_fifo_data[15], tx_fifo_data[14], tx_fifo_data[13], tx_fifo_data[12]};
                                        RE[7:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                    tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[9], tx_fifo_data[8]};
                                    end else if (qspi_data_length == 1) begin
                                        FE[3:0] <= {tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4]};
                                        RE[3:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0]};
                                    end
                                end
                            endcase
                        end
                   end      
               endcase   
           end else if(data_update) begin
                if (~t_ddr_en) begin
                            if (data_byte_counter >= 4) begin
                                case (t_phase_mode)
                                    SSPI: FE <= {tx_fifo_data[0], tx_fifo_data[1], tx_fifo_data[2], tx_fifo_data[3],
                                                 tx_fifo_data[4], tx_fifo_data[5], tx_fifo_data[6], tx_fifo_data[7],
                                                 tx_fifo_data[8], tx_fifo_data[9], tx_fifo_data[10], tx_fifo_data[11],
                                                 tx_fifo_data[12], tx_fifo_data[13], tx_fifo_data[14], tx_fifo_data[15],
                                                 tx_fifo_data[16], tx_fifo_data[17], tx_fifo_data[18], tx_fifo_data[19],
                                                 tx_fifo_data[20], tx_fifo_data[21], tx_fifo_data[22], tx_fifo_data[23],
                                                 tx_fifo_data[24], tx_fifo_data[25], tx_fifo_data[26], tx_fifo_data[27],
                                                 tx_fifo_data[28], tx_fifo_data[29], tx_fifo_data[30], tx_fifo_data[31]};
                                    DSPI: FE <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[3], tx_fifo_data[2],
                                                 tx_fifo_data[5], tx_fifo_data[4], tx_fifo_data[7], tx_fifo_data[6],
                                                 tx_fifo_data[9], tx_fifo_data[8], tx_fifo_data[11], tx_fifo_data[10],
                                                 tx_fifo_data[13], tx_fifo_data[12], tx_fifo_data[15], tx_fifo_data[14],
                                                 tx_fifo_data[17], tx_fifo_data[16], tx_fifo_data[19], tx_fifo_data[18],
                                                 tx_fifo_data[21], tx_fifo_data[20], tx_fifo_data[23], tx_fifo_data[22],
                                                 tx_fifo_data[25], tx_fifo_data[24], tx_fifo_data[27], tx_fifo_data[26],
                                                 tx_fifo_data[29], tx_fifo_data[28], tx_fifo_data[31], tx_fifo_data[30]};
                                    QSPI: FE <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                 tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4],
                                                 tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[9], tx_fifo_data[8],
                                                 tx_fifo_data[15], tx_fifo_data[14], tx_fifo_data[13], tx_fifo_data[12],
                                                 tx_fifo_data[19], tx_fifo_data[18], tx_fifo_data[17], tx_fifo_data[16],
                                                 tx_fifo_data[23], tx_fifo_data[22], tx_fifo_data[21], tx_fifo_data[20],
                                                 tx_fifo_data[27], tx_fifo_data[26], tx_fifo_data[25], tx_fifo_data[24],
                                                 tx_fifo_data[31], tx_fifo_data[30], tx_fifo_data[29], tx_fifo_data[28]};
                                endcase
                            end else if (data_byte_counter == 3) begin
                                case (t_phase_mode)
                                    SSPI: FE[23:0] <= {tx_fifo_data[0], tx_fifo_data[1], tx_fifo_data[2], tx_fifo_data[3],
                                                       tx_fifo_data[4], tx_fifo_data[5], tx_fifo_data[6], tx_fifo_data[7],
                                                       tx_fifo_data[8], tx_fifo_data[9], tx_fifo_data[10], tx_fifo_data[11],
                                                       tx_fifo_data[12], tx_fifo_data[13], tx_fifo_data[14], tx_fifo_data[15],
                                                       tx_fifo_data[16], tx_fifo_data[17], tx_fifo_data[18], tx_fifo_data[19],
                                                       tx_fifo_data[20], tx_fifo_data[21], tx_fifo_data[22], tx_fifo_data[23]};
                                    DSPI: FE[23:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[3], tx_fifo_data[2],
                                                       tx_fifo_data[5], tx_fifo_data[4], tx_fifo_data[7], tx_fifo_data[6],
                                                       tx_fifo_data[9], tx_fifo_data[8], tx_fifo_data[11], tx_fifo_data[10],
                                                       tx_fifo_data[13], tx_fifo_data[12], tx_fifo_data[15], tx_fifo_data[14],
                                                       tx_fifo_data[17], tx_fifo_data[16], tx_fifo_data[19], tx_fifo_data[18],
                                                       tx_fifo_data[21], tx_fifo_data[20], tx_fifo_data[23], tx_fifo_data[22]};
                                    QSPI: FE[23:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                       tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4],
                                                       tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[9], tx_fifo_data[8],
                                                       tx_fifo_data[15], tx_fifo_data[14], tx_fifo_data[13], tx_fifo_data[12],
                                                       tx_fifo_data[19], tx_fifo_data[18], tx_fifo_data[17], tx_fifo_data[16],
                                                       tx_fifo_data[23], tx_fifo_data[22], tx_fifo_data[21], tx_fifo_data[20]};
                                endcase
                            end else if (data_byte_counter == 2) begin
                                case (t_phase_mode)
                                    SSPI: FE[15:0] <= {tx_fifo_data[0], tx_fifo_data[1], tx_fifo_data[2], tx_fifo_data[3],
                                                       tx_fifo_data[4], tx_fifo_data[5], tx_fifo_data[6], tx_fifo_data[7],
                                                       tx_fifo_data[8], tx_fifo_data[9], tx_fifo_data[10], tx_fifo_data[11],
                                                       tx_fifo_data[12], tx_fifo_data[13], tx_fifo_data[14], tx_fifo_data[15]};
                                    DSPI: FE[15:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[3], tx_fifo_data[2],
                                                       tx_fifo_data[5], tx_fifo_data[4], tx_fifo_data[7], tx_fifo_data[6],
                                                       tx_fifo_data[9], tx_fifo_data[8], tx_fifo_data[11], tx_fifo_data[10],
                                                       tx_fifo_data[13], tx_fifo_data[12], tx_fifo_data[15], tx_fifo_data[14]};
                                    QSPI: FE[15:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                       tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4],
                                                       tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[9], tx_fifo_data[8],
                                                       tx_fifo_data[15], tx_fifo_data[14], tx_fifo_data[13], tx_fifo_data[12]};
                                endcase
                            end else if (data_byte_counter == 1) begin
                                case (t_phase_mode)
                                    SSPI: FE[7:0] <= {tx_fifo_data[0], tx_fifo_data[1], tx_fifo_data[2], tx_fifo_data[3],
                                                      tx_fifo_data[4], tx_fifo_data[5], tx_fifo_data[6], tx_fifo_data[7]};
                                    DSPI: FE[7:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[3], tx_fifo_data[2],
                                                      tx_fifo_data[5], tx_fifo_data[4], tx_fifo_data[7], tx_fifo_data[6]};
                                    QSPI: FE[7:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                      tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4]};
                                endcase
                            end
                        end else begin
                            case (t_phase_mode)
                                SSPI: begin
                                    if (data_byte_counter >= 4) begin
                                        FE[15:0] <= {tx_fifo_data[1], tx_fifo_data[3], tx_fifo_data[5], tx_fifo_data[7],
                                                     tx_fifo_data[9], tx_fifo_data[11], tx_fifo_data[13], tx_fifo_data[15],
                                                     tx_fifo_data[17], tx_fifo_data[19], tx_fifo_data[21], tx_fifo_data[23],
                                                     tx_fifo_data[25], tx_fifo_data[27], tx_fifo_data[29], tx_fifo_data[31]};
                                        RE <= {tx_fifo_data[0], tx_fifo_data[2], tx_fifo_data[4], tx_fifo_data[6],
                                               tx_fifo_data[8], tx_fifo_data[10], tx_fifo_data[12], tx_fifo_data[14],
                                               tx_fifo_data[16], tx_fifo_data[18], tx_fifo_data[20], tx_fifo_data[22],
                                               tx_fifo_data[24], tx_fifo_data[26], tx_fifo_data[28], tx_fifo_data[30]};
                                    end else if (data_byte_counter == 3) begin
                                        FE[11:0] <= {tx_fifo_data[1], tx_fifo_data[3], tx_fifo_data[5], tx_fifo_data[7],
                                                     tx_fifo_data[9], tx_fifo_data[11], tx_fifo_data[13], tx_fifo_data[15],
                                                     tx_fifo_data[17], tx_fifo_data[19], tx_fifo_data[21], tx_fifo_data[23]};
                                        RE[11:0] <= {tx_fifo_data[0], tx_fifo_data[2], tx_fifo_data[4], tx_fifo_data[6],
                                                     tx_fifo_data[8], tx_fifo_data[10], tx_fifo_data[12], tx_fifo_data[14],
                                                     tx_fifo_data[16], tx_fifo_data[18], tx_fifo_data[20], tx_fifo_data[22]};
                                    end else if (data_byte_counter == 2) begin
                                        FE[7:0] <= {tx_fifo_data[1], tx_fifo_data[3], tx_fifo_data[5], tx_fifo_data[7],
                                                    tx_fifo_data[9], tx_fifo_data[11], tx_fifo_data[13], tx_fifo_data[15]};
                                        RE[7:0] <= {tx_fifo_data[0], tx_fifo_data[2], tx_fifo_data[4], tx_fifo_data[6],
                                                    tx_fifo_data[8], tx_fifo_data[10], tx_fifo_data[12], tx_fifo_data[14]};
                                    end else if (data_byte_counter == 1) begin
                                        FE[3:0] <= {tx_fifo_data[1], tx_fifo_data[3], tx_fifo_data[5], tx_fifo_data[7]};
                                        RE[3:0] <= {tx_fifo_data[0], tx_fifo_data[2], tx_fifo_data[4], tx_fifo_data[6]};
                                    end
                                end
                               DSPI: begin
                                    if (data_byte_counter >= 4) begin
                                        FE[15:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[7], tx_fifo_data[6],
                                                     tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[15], tx_fifo_data[14],
                                                     tx_fifo_data[19], tx_fifo_data[18], tx_fifo_data[23], tx_fifo_data[22],
                                                     tx_fifo_data[27], tx_fifo_data[26], tx_fifo_data[31], tx_fifo_data[30]};
                                        RE[15:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[5], tx_fifo_data[4],
                                                     tx_fifo_data[9], tx_fifo_data[8], tx_fifo_data[13], tx_fifo_data[12],
                                                     tx_fifo_data[17], tx_fifo_data[16], tx_fifo_data[21], tx_fifo_data[20],
                                                     tx_fifo_data[25], tx_fifo_data[24], tx_fifo_data[29], tx_fifo_data[28]};
                                    end else if (data_byte_counter == 3) begin
                                        FE[11:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[7], tx_fifo_data[6],
                                                     tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[15], tx_fifo_data[14],
                                                     tx_fifo_data[19], tx_fifo_data[18], tx_fifo_data[23], tx_fifo_data[22]
                                                     }; 
                                        RE[11:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[5], tx_fifo_data[4],
                                                     tx_fifo_data[9], tx_fifo_data[8], tx_fifo_data[13], tx_fifo_data[12],
                                                     tx_fifo_data[17], tx_fifo_data[16], tx_fifo_data[21], tx_fifo_data[20]}; // Padding 4 bits v?i giá tr? 0
                                    end else if (data_byte_counter == 2) begin
                                        FE[7:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[7], tx_fifo_data[6],
                                                     tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[15], tx_fifo_data[14]}; 
                                        RE[7:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[5], tx_fifo_data[4],
                                                     tx_fifo_data[9], tx_fifo_data[8], tx_fifo_data[13], tx_fifo_data[12]};
                                    end else if (data_byte_counter == 1) begin
                                        FE[3:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[7], tx_fifo_data[6]};
                                        RE[3:0] <= {tx_fifo_data[1], tx_fifo_data[0], tx_fifo_data[5], tx_fifo_data[4]};
                                    end
                                end
                                
                                QSPI: begin
                                    if (data_byte_counter >= 4) begin
                                        FE[15:0] <= {tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4],
                                                     tx_fifo_data[15], tx_fifo_data[14], tx_fifo_data[13], tx_fifo_data[12],
                                                     tx_fifo_data[23], tx_fifo_data[22], tx_fifo_data[21], tx_fifo_data[20],
                                                     tx_fifo_data[31], tx_fifo_data[30], tx_fifo_data[29], tx_fifo_data[28]};
                                        RE[15:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                     tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[9], tx_fifo_data[8],
                                                     tx_fifo_data[19], tx_fifo_data[18], tx_fifo_data[17], tx_fifo_data[16],
                                                     tx_fifo_data[27], tx_fifo_data[26], tx_fifo_data[25], tx_fifo_data[24]};
                                    end else if (data_byte_counter == 3) begin
                                        FE[11:0] <= {tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4],
                                                     tx_fifo_data[15], tx_fifo_data[14], tx_fifo_data[13], tx_fifo_data[12],
                                                     tx_fifo_data[23], tx_fifo_data[22], tx_fifo_data[21], tx_fifo_data[20]};
                                        RE[11:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                     tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[9], tx_fifo_data[8],
                                                     tx_fifo_data[19], tx_fifo_data[18], tx_fifo_data[17], tx_fifo_data[16]};
                                    end else if (data_byte_counter == 2) begin
                                        FE[7:0] <= {tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4],
                                                    tx_fifo_data[15], tx_fifo_data[14], tx_fifo_data[13], tx_fifo_data[12]};
                                        RE[7:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0],
                                                    tx_fifo_data[11], tx_fifo_data[10], tx_fifo_data[9], tx_fifo_data[8]};
                                    end else if (data_byte_counter == 1) begin
                                        FE[3:0] <= {tx_fifo_data[7], tx_fifo_data[6], tx_fifo_data[5], tx_fifo_data[4]};
                                        RE[3:0] <= {tx_fifo_data[3], tx_fifo_data[2], tx_fifo_data[1], tx_fifo_data[0]};
                                    end
                                end
                            endcase
                        end   
           end else begin 
              if(~t_ddr_en) begin
                 case(t_phase_mode)
                    SSPI: FE <= FE >> 1;
                    DSPI: FE <= FE >> 2;
                    QSPI: FE <= FE >> 4; 
                 endcase  
              end else begin
                 case(t_phase_mode)
                    SSPI:begin 
                        FE <= FE >> 1;
                        RE <= RE >> 1;
                    end
                    DSPI:begin 
                        FE <= FE >> 2;
                        RE <= RE >> 2;
                    end
                    QSPI:begin 
                        FE <= FE >> 4;
                        RE <= RE >> 4;
                    end 
                 endcase      
              end
          end                   
       end else begin
           FE <= 32'b0;
           RE <= 32'b0;
       end
    end       
    
   always@(*) begin
        case(phase_mode)
            SSPI: begin
                qio_out[0] = (~ddr_en || (ddr_en && ~qspi_clk))? FE[0]: RE[0];
                qio_out[1] = 0;
                qio_out[2] = qspi_out2;
                qio_out[3] = qspi_out3; 
            end
            DSPI: begin
                qio_out[0] = (~ddr_en || (ddr_en && ~qspi_clk))? FE[0]: RE[0];
                qio_out[1] = (~ddr_en || (ddr_en && ~qspi_clk))? FE[1]: RE[1];
                qio_out[2] = qspi_out2;
                qio_out[3] = qspi_out3;    
            end
            QSPI: begin
                qio_out[0] = (~ddr_en || (ddr_en && ~qspi_clk))? FE[0]: RE[0];
                qio_out[1] = (~ddr_en || (ddr_en && ~qspi_clk))? FE[1]: RE[1];
                qio_out[2] = (~ddr_en || (ddr_en && ~qspi_clk))? FE[2]: RE[2];
                qio_out[3] = (~ddr_en || (ddr_en && ~qspi_clk))? FE[3]: RE[3]; 
            end
            default: qio_out = 4'h0;
        endcase
    end
    
endmodule
