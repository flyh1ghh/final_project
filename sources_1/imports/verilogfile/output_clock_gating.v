`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/05/2024 11:53:46 AM
// Design Name: 
// Module Name: output_clock_gating
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


module output_clock_gating(
    input qspi_clk,
    input serial_clk_en,
    input qspi_sclk_mode,
    
    output qspi_sclk
    );
    
    reg serial_clk_en_reg;
    reg sclk_reg;
    
    assign qspi_sclk = sclk_reg;
    
    always@(negedge qspi_clk) begin
        serial_clk_en_reg <= serial_clk_en;
    end
    
    always@(*)begin
        if(serial_clk_en_reg == 0) begin
            if(qspi_sclk_mode == 0)
                sclk_reg = 0;
            else
                sclk_reg = 1;             
        end else begin
            sclk_reg = qspi_clk;
        end
    
    end
    
    
    
    
endmodule
