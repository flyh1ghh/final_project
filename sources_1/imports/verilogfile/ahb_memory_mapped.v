`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2024 09:08:18 PM
// Design Name: 
// Module Name: ahb_memory_mapped
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


module ahb_memory_mapped(
    input sys_clk,
    input sys_rst,
    
    //ahb signal
    input hsel,
    input hwrite,
    input [2:0]hsize,
    input [31:0]hwdata,
    input [31:0]haddr,
    output [31:0] hrdata,
    output hready,
    
    //fifo signal
    input [31:0] rx_fifo_read_data,
    input rx_fifo_empty,
    
    output rx_fifo_read,
    
    //signal from config_reg
    input qspi_mode,
    input cfg_reg_rx_fifo_read,
    
    //signal from protocol controller
    input qspi_busy,
    input qspi_done,
    //memory_mapped signal
    
    output reg memory_mapped_mode_req,
    output reg [31:0] memory_mapped_mode_addr
   
    );
    reg memory_mapped_mode_read;
    
    always@(posedge sys_clk or posedge sys_rst) begin
        if(sys_rst || qspi_done) memory_mapped_mode_req = 0;
        else if(hsel && ~hwrite && qspi_mode) begin
            if(qspi_busy == 0 && qspi_done == 0 && rx_fifo_empty == 1) memory_mapped_mode_req <= 1;
            else if (qspi_busy == 0 && qspi_done == 1) memory_mapped_mode_req <= 0;  
        end
    end
    
    always@(*) begin
        if(sys_rst)  memory_mapped_mode_addr = haddr;
        else if(hsel && memory_mapped_mode_req) 
            memory_mapped_mode_addr = haddr;
    end    
            
    
    always@(posedge sys_clk or posedge sys_rst) begin
        if(sys_rst) memory_mapped_mode_read = 0 ;
        else if(hsel && ~hwrite && rx_fifo_empty == 0 ) memory_mapped_mode_read = 1;
    end   
    
    assign hrdata = (hsize == 3'b000)? {24'b0,rx_fifo_read_data[7:0]}: 
                    (hsize == 3'b001)? {16'b0,rx_fifo_read_data[15:0]}:
                    (hsize == 3'b010)? rx_fifo_read_data: 32'b0;
    assign rx_fifo_read = (qspi_mode)? memory_mapped_mode_read: cfg_reg_rx_fifo_read;
    assign hready = ~memory_mapped_mode_req || ~rx_fifo_empty;  
    
endmodule
