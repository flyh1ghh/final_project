`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2024 03:17:35 PM
// Design Name: 
// Module Name: clock_generator
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


module clock_generator(
    input sys_clk,
    input sys_rst,
    input [1:0]qspi_prescaler,
    input protocol_clk_req,
    output qspi_clk
    );
    reg [2:0] counter;
    wire gate_sys_clk;
    wire prescaler_out;
    
    assign gate_sys_clk = ~protocol_clk_req||sys_clk;
  
    always@(posedge sys_clk or posedge sys_rst)
    begin
        if(sys_rst)
            counter <= 3'b000;
        else
            counter <= counter + 1;    
    end
    
    assign prescaler_out = (qspi_prescaler == 2'b00) ? 0 :
                           (qspi_prescaler == 2'b01) ? counter[0] :
                           (qspi_prescaler == 2'b10) ? counter[1] :
                           counter[2]; 
    assign qspi_clk =  (qspi_prescaler == 2'b00) ? gate_sys_clk : prescaler_out; 
    
endmodule
