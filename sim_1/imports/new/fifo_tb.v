`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/01/2024 07:50:41 PM
// Design Name: 
// Module Name: fifo_tb
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


module fifo_tb(

    );
    
     // Inputs
    reg sys_clk;
    reg sys_rst;
    reg write;
    reg read;
    reg [4:0] level;
    reg [31:0] write_data;

    // Outputs
    wire [31:0] read_data;
    wire full;
    wire empty;
    wire reached;

    // Instantiate the FIFO module
    fifo uut (
        .sys_clk(sys_clk), 
        .sys_rst(sys_rst), 
        .write(write), 
        .read(read), 
        .level(level), 
        .write_data(write_data), 
        .read_data(read_data), 
        .full(full), 
        .empty(empty), 
        .reached(reached)
    );

    // Generate clock
    initial begin
        sys_clk = 0;
        forever #5 sys_clk = ~sys_clk;
    end

    // Testbench process
    initial begin
        // Initialize inputs
        sys_rst = 1;
        write = 0;
        read = 0;
        level = 5; // Watermark level
        write_data = 32'd0;

        // Reset the FIFO
        #10 sys_rst = 0;
        #10 sys_rst = 1;
        #10 sys_rst = 0;
        
        // Write data into FIFO
        write_data = 32'd1;
        write = 1;
        #10;
        
        write_data = 32'd2;
        #10;
        
        write_data = 32'd3;
        #10;
        
        write_data = 32'd4;
        #10;
        
        write = 0;
        
        // Read data from FIFO
        #10 read = 1;
        #10 read = 0;
        #10 read = 1;
        #10 read = 0;
        
        // Fill FIFO to trigger `full`
        write = 1;
        write_data = 32'd5;
        #10;
        
        write_data = 32'd6;
        #10;
        
        write_data = 32'd7;
        #10;
        
        write_data = 32'd8;
        #10;
        
        write_data = 32'd8;
        #10;
        write_data = 32'd8;
        #10;
        write_data = 32'd8;
        #10;
        write_data = 32'd8;
        #10;
        write_data = 32'd8;
        #10;
        write_data = 32'd8;
        #10;
        
        write = 0;
        
        // Test watermark level
        level = 3;
        
        // Reset FIFO again
        #10 sys_rst = 1;
        #10 sys_rst = 0;

        // Finish simulation
        #100 $finish;
    end
    
endmodule
