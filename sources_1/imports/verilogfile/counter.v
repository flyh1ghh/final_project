`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2024 10:08:40 AM
// Design Name: 
// Module Name: counter
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


module counter(
    input qspi_clk,
    input qspi_rst,
    
    input next_phase_active,
    input t_ddr_en,
    input counter_en,
    input t_counter_en,
    input [8:0] qspi_data_length,
    input [4:0] qspi_dummy_length,
    input [2:0] qspi_addr_length,
    
    input [1:0]t_phase_mode,
    input [3:0]next_state,
    input [3:0]current_state,
    
    output  reg bit_counter_done,
    output  reg byte_counter_done,
    output  reg data_byte_counter_done,
    
    output reg [2:0] bit_counter,
    output reg [1:0] byte_counter,
    output reg [8:0] data_byte_counter
    
    
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
    
    parameter
    SSPI = 2'h0,
    DSPI = 2'h1,
    QSPI = 2'h2;
    
    
    
    always@(negedge qspi_clk or posedge qspi_rst) begin
        if(qspi_rst)  begin
            bit_counter <= 3'b111;
            byte_counter <= 2'b11;
            data_byte_counter <= 9'b111111111;
        end else begin
            if(t_counter_en) begin
                if(next_phase_active) begin
                    case(next_state)
                        IDLE,TURN_AROUND,CHIP_SELECT_HIGH_TIME: begin
                            bit_counter <= 3'b111; 
                            byte_counter <= 2'b11;
                            data_byte_counter <= 9'h1FF;   
                        end
                        TX_COMMAND: begin
                               byte_counter <= 0;
                               data_byte_counter <= 9'h1FF;
                               case(t_phase_mode)
                                    SSPI: bit_counter <= 7;
                                    DSPI: bit_counter <= 6;
                                    QSPI: bit_counter <= 4;
                               endcase
                        end
                        TX_ADDRESS: begin
                                byte_counter <= qspi_addr_length - 1;
                                data_byte_counter <= 9'h1FF;
                                case(t_phase_mode)
                                   SSPI: bit_counter <= (t_ddr_en)? 6: 7;
                                   DSPI: bit_counter <= (t_ddr_en)? 4: 6;
                                   QSPI: bit_counter <= (t_ddr_en)? 0: 4;
                                endcase
                        end
                        TX_ALTERNATE: begin
                                byte_counter <= 0;
                                data_byte_counter <= 9'h1FF;
                                case(t_phase_mode)
                                   SSPI: bit_counter <= (t_ddr_en)? 6: 7;
                                   DSPI: bit_counter <= (t_ddr_en)? 4: 6;
                                   QSPI: bit_counter <= (t_ddr_en)? 0: 4;
                                endcase
                        end
                        DUMMY: begin
                                if((qspi_dummy_length >= 25) && (qspi_dummy_length <= 31))begin
                                    bit_counter <= qspi_dummy_length - 25;
                                    byte_counter <= 3;
                                    data_byte_counter <= 9'h1FF;
                                end else  if((qspi_dummy_length >= 17) && (qspi_dummy_length <= 24))begin
                                    bit_counter <= qspi_dummy_length - 17;
                                    byte_counter <= 2;
                                    data_byte_counter = 9'h1FF;
                                end else  if((qspi_dummy_length >= 9) && (qspi_dummy_length <= 16))begin
                                    bit_counter <= qspi_dummy_length - 9;
                                    byte_counter <= 1;
                                    data_byte_counter <= 9'h1FF;
                                end else  if((qspi_dummy_length >= 1) && (qspi_dummy_length <= 8))begin
                                    bit_counter <= qspi_dummy_length - 1 ;
                                    byte_counter <= 0;
                                    data_byte_counter <= 9'h1FF;
                                end  
                        end
                        TX_DATA,RX_DATA: begin
                                if(qspi_data_length >= 4)  byte_counter <= 3;
                                else byte_counter <= qspi_data_length - 1;
                                data_byte_counter <= qspi_data_length - 1;
                                case(t_phase_mode)
                                   SSPI: bit_counter <= (t_ddr_en)? 6: 7;
                                   DSPI: bit_counter <= (t_ddr_en)? 4: 6;
                                   QSPI: bit_counter <= (t_ddr_en)? 0: 4;
                                endcase
                        end   
                    endcase
                end else begin
                    byte_counter <= (bit_counter == 0)? byte_counter - 1: byte_counter;
                    data_byte_counter <= (bit_counter == 0 && (next_state == TX_DATA ||next_state == RX_DATA) )? data_byte_counter - 1: data_byte_counter;
                    if(~t_ddr_en) begin
                        case(t_phase_mode)
                            SSPI: bit_counter <= bit_counter - 1;
                            DSPI: bit_counter <= bit_counter - 2;
                            QSPI: bit_counter <= bit_counter - 4;
                        endcase           
                    end else begin
                        case(t_phase_mode)
                            SSPI: bit_counter <= bit_counter - 2;
                            DSPI: bit_counter <= bit_counter - 4;
                            QSPI: bit_counter <= bit_counter;
                        endcase     
                    end
                end
            end
        end    
    end
    
    always@(*) begin
        if(qspi_rst || current_state == CHIP_SELECT_HIGH_TIME  ) begin
            bit_counter_done = 0;
            byte_counter_done = 0;    
            data_byte_counter_done = 0;
        end else if(counter_en) begin
            if(bit_counter == 3'b00) begin
                bit_counter_done = 1;
                if(byte_counter == 2'b00) byte_counter_done = 1;
                else byte_counter_done = 0;
                if(data_byte_counter == 2'b00) data_byte_counter_done = 1;
                else data_byte_counter_done = 0; 
            end else begin
                bit_counter_done = 0;
                byte_counter_done = 0;
                data_byte_counter_done = 0;
            end
        end
    end
    
endmodule
