`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/17/2024 10:40:13 PM
// Design Name: 
// Module Name: receiver
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


module receiver(
    input qspi_clk,
    input qspi_rst,
    
    input ddr_en,
    input t_ddr_en,
    input receive_en,
    
    input t_receive_en,
    input [1:0]t_phase_mode,
    input [1:0]phase_mode,
    
    input buffer_update,
    input [3:0] qio_in,

    output [31:0] rx_fifo_data

    );
    
    parameter SSPI = 2'b00,
              DSPI = 2'b01,
              QSPI = 2'b10;
              
    
    reg [7:0] FE;
    reg [3:0] RE;
    reg [31:0] rx_buffer;
    
    
    
    assign rx_fifo_data = rx_buffer;
    
    always@(negedge qspi_clk or posedge qspi_rst) begin
        if(qspi_rst) begin
            FE <= 8'b0;
        end else if(t_receive_en)  begin
            case(t_phase_mode)
                SSPI: FE <= {FE[6:0],qio_in[1]};
                DSPI: FE <= {FE[5:0],qio_in[1:0]};
                QSPI: FE <= {FE[3:0],qio_in};
            endcase
        end
    end
    
    always@(posedge qspi_clk or posedge qspi_rst) begin
        if(qspi_rst) begin
            RE <= 4'b0;
        end else if(receive_en) begin
            if(ddr_en) begin
                case(phase_mode)
                SSPI: RE <= {RE[2:0],qio_in[1]};
                DSPI: RE <= {FE[1:0],qio_in[1:0]};
                QSPI: RE <= qio_in ;
                endcase    
            end
        end
    end
    
    always@(negedge qspi_clk or posedge qspi_rst) begin
        if(qspi_rst) begin
            rx_buffer <= 32'b0;
        end else if (receive_en) begin
            if(buffer_update) begin
                if(~ddr_en) begin
                    rx_buffer <= {rx_buffer[23:0],FE};
                end else begin
                    rx_buffer <= {rx_buffer[23:0] , FE[3:0] , RE };
                end
            end
        end
    end  
endmodule
