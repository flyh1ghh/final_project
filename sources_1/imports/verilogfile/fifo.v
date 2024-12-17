`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2024 08:38:13 PM
// Design Name: 
// Module Name: fifo
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


module fifo(
    
    input sys_clk,
    input sys_rst,
    
    input write,
    input read,
    input [4:0] level,
    input [31:0] write_data,
    output [31:0] read_data,
    
    output full,
    output empty,
    output reached
    
    
    );
    
    parameter N = 9;
    parameter M = (1<<N) - 1;
    
    reg [31:0] mem [M:0];
    reg [N:0] read_pointer;
    reg [N:0] write_pointer;
    reg [31:0] data_out;
    reg empty_reg;
    reg full_reg;
    reg watermark_level;
    integer i;
    
    wire write_en;
    wire read_en;
    wire [(N-1):0]write_addr;
    wire [(N-1):0]read_addr;
    
    assign write_en = write & !full;
    assign read_en = read & !empty;
    assign write_addr = write_pointer;
    assign read_addr = read_pointer;
    assign read_data = data_out;
    assign full = full_reg;
    assign empty = empty_reg;
    assign reached = watermark_level;
    
    
    always@(posedge sys_clk or posedge sys_rst) begin
        if(sys_rst) begin
            read_pointer <= 0;
            write_pointer <= 0;
            data_out <= 32'bx;
            for (i = 0; i <= M; i = i + 1) begin
                mem[i] <= 32'bx;
            end
        end else begin
            if(write) begin
               if(write_en) begin
                    mem[write_addr] <= write_data;
                    write_pointer <= write_pointer + 1;
               end
            end 
            
            if (read) begin
               if(read_en) begin
                   data_out <= mem[read_addr];
                   read_pointer <= read_pointer + 1;
               end
            end
            
        end
    end


    always@(negedge sys_clk or posedge sys_rst) begin
        if(sys_rst) begin
            empty_reg = 1;
            full_reg = 0;
            watermark_level = 0;
        end else begin
            if(write_pointer[N-1:0] == read_pointer[N-1:0]) begin
                if(write_pointer[N] == read_pointer[N]) begin
                    empty_reg = 1;
                    full_reg = 0;
                end else begin
                    empty_reg = 0;
                    full_reg = 1;
                end
            end else begin
                    empty_reg = 0;
                    full_reg = 0;
            end
            
            if(write_pointer - read_pointer >= level) begin
               watermark_level = 1;
            end else begin
               watermark_level = 0;
            end 
            
        end
        
    end
    

endmodule
