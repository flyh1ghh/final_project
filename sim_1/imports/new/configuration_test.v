`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2024 09:45:59 PM
// Design Name: 
// Module Name: configuration_test
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


module configuration_registers_tb();

    // Clock and reset
    reg sys_clk;
    reg sys_rst;

    // AHB1 Slave Interface
    reg [31:0] haddr;
    reg [2:0] hsize;
    reg hsel;
    reg hwrite;
    reg [31:0] hwdata;
    wire hready;
    wire [31:0] hrdata;

    // Signal basic mode
    wire qspi_basic_mode_req;
    reg qspi_done;
    reg qspi_busy;

    // QSPI config
    wire qspi_mode;
    wire [1:0] qspi_prescaler;
    wire qspi_sioo;
    wire [2:0] qspi_cs_ht;
    wire [8:0] qspi_data_length;
    wire [4:0] qspi_dummy_length;
    wire [3:0] qspi_cfg_length;
    wire [2:0] qspi_addr_length;
    wire qspi_cmd_length;
    wire qspi_wr;
    wire qspi_en;

    // QSPI config1
    wire qspi_sclk_mode;
    wire qspi_data_ddr;
    wire qspi_addr_ddr;
    wire qspi_dummy_hiz;
    wire qspi_out2;
    wire qspi_out3;

    // QSPI mode
    wire [4:0] qspi_tx_fwl;
    wire [4:0] qspi_rx_fwl;
    wire [1:0] qspi_data_mode;
    wire [1:0] qspi_addr_mode;
    wire [1:0] qspi_cmd_mode;

    // QSPI intstr0
    wire [31:0] qspi_addr;

    // QSPI intstr1
    wire [7:0] qspi_cmd;
    wire [7:0] qspi_cfg;

    // QSPI write data
    wire [31:0] tx_fifo_write_data;

    // Status FIFO
    reg tx_fifo_reached;
    reg tx_fifo_full;
    reg tx_fifo_empty;
    reg rx_fifo_reached;
    reg rx_fifo_full;
    reg rx_fifo_empty;

    // Control FIFO
    wire cfg_reg_rx_fifo_read;
    reg [31:0] rx_fifo_read_data;
    wire tx_fifo_write;
    wire [2:0]current_state;
    wire [2:0]next_state;
    
    // Instantiate the Unit Under Test (UUT)
    configuration_registers uut (
        .sys_clk(sys_clk),
        .sys_rst(sys_rst),

        .haddr(haddr),
        .hsize(hsize),
        .hsel(hsel),
        .hwrite(hwrite),
        .hwdata(hwdata),
        .hready(hready),
        .hrdata(hrdata),

        .qspi_basic_mode_req(qspi_basic_mode_req),
        .qspi_done(qspi_done),
        .qspi_busy(qspi_busy),

        .qspi_mode(qspi_mode),
        .qspi_prescaler(qspi_prescaler),
        .qspi_sioo(qspi_sioo),
        .qspi_cs_ht(qspi_cs_ht),
        .qspi_data_length(qspi_data_length),
        .qspi_dummy_length(qspi_dummy_length),
        .qspi_cfg_length(qspi_cfg_length),
        .qspi_addr_length(qspi_addr_length),
        .qspi_cmd_length(qspi_cmd_length),
        .qspi_wr(qspi_wr),
        .qspi_en(qspi_en),

        .qspi_sclk_mode(qspi_sclk_mode),
        .qspi_data_ddr(qspi_data_ddr),
        .qspi_addr_ddr(qspi_addr_ddr),
        .qspi_dummy_hiz(qspi_dummy_hiz),
        .qspi_out2(qspi_out2),
        .qspi_out3(qspi_out3),

        .qspi_tx_fwl(qspi_tx_fwl),
        .qspi_rx_fwl(qspi_rx_fwl),
        .qspi_data_mode(qspi_data_mode),
        .qspi_addr_mode(qspi_addr_mode),
        .qspi_cmd_mode(qspi_cmd_mode),

        .qspi_addr(qspi_addr),
        .qspi_cmd(qspi_cmd),
        .qspi_cfg(qspi_cfg),

        .tx_fifo_write_data(tx_fifo_write_data),

        .tx_fifo_reached(tx_fifo_reached),
        .tx_fifo_full(tx_fifo_full),
        .tx_fifo_empty(tx_fifo_empty),
        .rx_fifo_reached(rx_fifo_reached),
        .rx_fifo_full(rx_fifo_full),
        .rx_fifo_empty(rx_fifo_empty),

        .cfg_reg_rx_fifo_read(cfg_reg_rx_fifo_read),
        .rx_fifo_read_data(rx_fifo_read_data),
        .tx_fifo_write(tx_fifo_write),
        .current_state(current_state),
        .next_state(next_state)
    );

    // Clock generation
    initial begin
        sys_clk = 1;
        forever #5 sys_clk = ~sys_clk; // 100 MHz clock
    end

   initial begin
        sys_rst = 0;
        #10;
        sys_rst = 1;
        #20;
        sys_rst = 0;
        hsel = 1;
        hsize = 3'b010;
        hwrite = 1;
        qspi_busy = 0;
        haddr = 32'h0000_0010;
        tx_fifo_full = 0;
        #10;
        hwrite = 0;
        hwdata = 32'hABCD_BCAB;
        #10;//1
        haddr = 32'h0000000C;
        #10;
        hwdata = 32'hABCD_BCAB;
        #10;//2
        haddr = 32'h0000_0010;
        #10;
        hwdata = 32'h0000_00BA;
        #10;//3
        haddr = 32'h0000_0004;
        #10;
        hwdata = 32'h0000_00BA;
        #10;//4
        haddr = 32'h0000_0000;
        #10;
        hsel = 0;
        hwdata = 32'hF000_00BF;
        #20;//5
        hsel = 1;
        hwrite = 1;
        qspi_busy = 0;
        haddr = 32'h0000_0000;
        #10;
        hsel = 0;
        hwrite = 0;
        hwdata = 32'hF000_002F;
        #20;
        hsel = 1;
        hwrite = 1;
        haddr = 32'h00000014;
        #10;
        hsel = 0;
        hwdata = 32'h43213332;
        #20;
        hsel = 1;
        hwrite = 1;
        haddr = 32'h00000014;
        #10;
        hsel = 0;
        #20;
        hwdata = 32'h54231112; 
        #50;   
        $stop;
        
        
   end
    

endmodule
