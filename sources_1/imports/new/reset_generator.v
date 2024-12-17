`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2024 09:30:22 AM
// Design Name: 
// Module Name: reset_generator
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


module reset_generator(
    input sys_clk,
    input a_res_n,
    output sys_rst
    );
    
    wire gate_clk;
    
    reg ff1;
    reg ff2;
    
    always@(posedge gate_clk or negedge a_res_n) begin
        if(~a_res_n) ff1 <= 0;
        else ff1 <= a_res_n;
    end
    
    always@(posedge gate_clk or negedge a_res_n) begin
        if(~a_res_n) ff2 <= 0;
        else ff2 <= a_res_n;
    end
    
    assign sys_rst = ~ff1 && ~ ff2;
    assign gate_clk = sys_clk || ~sys_rst;
    
    
endmodule
