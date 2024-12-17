`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2024 10:41:35 AM
// Design Name: 
// Module Name: qspi_master
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


module qspi_master(
    input sys_clk,
    input a_res_n,
    
    //PPI AHB slave
    input [31:0] ppi_haddr,
    input [2:0] ppi_hsize,
    input ppi_hsel,
    input ppi_hwrite,
    input [31:0] ppi_hwdata,
    output ppi_hready,
    output [31:0]ppi_hrdata,
    
    //PCI AHB slave
    input [31:0] pci_haddr,
    input [2:0] pci_hsize,
    input pci_hsel,
    input pci_hwrite,
    input [31:0] pci_hwdata,
    output pci_hready,
    output [31:0]pci_hrdata,
    
    //QSPI master interface
    output qspi_sclk,
    output cs_n,
    output [3:0] qio_out,
    input  [3:0] qio_in,
    output [3:0] qspi_oe,
    
    //protocol signal
    output qspi_clk,
    output [3:0]current_state,
    output [2:0]bit_counter,
    output [1:0]byte_counter,
    output [8:0]data_byte_counter,
    output bit_counter_done,
    output byte_counter_done,
    output data_byte_counter_done,
    output [1:0]phase_mode,
    output qspi_busy,
    output qspi_done,
    output ddr_en,
    output memory_mapped_mode_req,
    output qspi_basic_mode_req,
    output rx_fifo_empty,
    output rx_fifo_write
    );

    wire sys_rst;
    wire protocol_clk_req;
   
    
    // Memory-mapped mode signals
    //wire memory_mapped_mode_req;
    wire [31:0] memory_mapped_mode_addr;
    
    // Configuration signals
    wire [1:0] qspi_prescaler;
    wire qspi_mode;
    wire qspi_sioo;
    wire [2:0] qspi_cs_ht;
    wire [8:0] qspi_data_length;
    wire [4:0] qspi_dummy_length;
    wire [3:0] qspi_cfg_length;
    wire [2:0] qspi_addr_length;
    wire qspi_cmd_length;
    wire qspi_wr;
    wire qspi_en;
    
    // QSPI-specific signals
    wire qspi_sclk_mode;
    wire qspi_data_ddr;
    wire qspi_addr_ddr;
    wire qspi_dummy_hiz;
    wire qspi_out2;
    wire qspi_out3;
    
    wire [1:0] qspi_data_mode;
    wire [1:0] qspi_addr_mode;
    wire [1:0] qspi_cmd_mode;
    
    wire [31:0] qspi_addr;
    wire [7:0] qspi_cmd;
    wire [7:0] qspi_cfg;
    
    // Mode request and status signals
    //wire qspi_basic_mode_req;
    
    //tx_fifo_signal
    wire [31:0] tx_fifo_write_data;
    wire [31:0] tx_fifo_read_data;
    wire tx_fifo_reached;
    wire tx_fifo_full;
    wire tx_fifo_empty;
    wire [4:0] qspi_tx_fwl;
    
    //wire rx_fifo_write;
    wire rx_fifo_read;
    
    //rx_fifo_signal
    wire [31:0] rx_fifo_write_data;
    wire [31:0] rx_fifo_read_data;
    wire rx_fifo_reached;
    wire rx_fifo_full;
    //wire rx_fifo_empty;
    wire [4:0] qspi_rx_fwl;

    wire cfg_reg_rx_fifo_read;
    
    reset_generator RESET (
        .sys_clk(sys_clk),
        .a_res_n(a_res_n),
        .sys_rst(sys_rst)
    );
    
    protocol_controller PC (
        .qspi_clk(qspi_clk),
        .qspi_rst(sys_rst),
        .protocol_clk_req(protocol_clk_req),
        .tx_fifo_empty(tx_fifo_empty),
        .tx_fifo_read_data(tx_fifo_read_data),
        .tx_fifo_read(tx_fifo_read),
        .rx_fifo_full(rx_fifo_full),
        .rx_fifo_write_data(rx_fifo_write_data),
        .rx_fifo_write(rx_fifo_write),
        .memory_mapped_mode_req(memory_mapped_mode_req),
        .memory_mapped_mode_addr(memory_mapped_mode_addr),
        .qspi_mode(qspi_mode),
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
        .qspi_data_mode(qspi_data_mode),
        .qspi_addr_mode(qspi_addr_mode),
        .qspi_cmd_mode(qspi_cmd_mode),
        .qspi_addr(qspi_addr),
        .qspi_cmd(qspi_cmd),
        .qspi_cfg(qspi_cfg),
        .qspi_basic_mode_req(qspi_basic_mode_req),
        .qspi_done(qspi_done),
        .qspi_busy(qspi_busy),
        .qspi_sclk(qspi_sclk),
        .cs_n(cs_n),
        .qspi_oe(qspi_oe),
        .qio_out(qio_out),
        .qio_in(qio_in),
        .current_state(current_state),
        .ddr_en(ddr_en),
        .phase_mode(phase_mode),
        .bit_counter(bit_counter),
        .byte_counter(byte_counter),
        .data_byte_counter(data_byte_counter),
        .bit_counter_done(bit_counter_done),
        .byte_counter_done(byte_counter_done),
        .data_byte_counter_done(data_byte_counter_done)
    );
    
    configuration_registers CR (
        .sys_clk(sys_clk),
        .sys_rst(sys_rst),
        .haddr(ppi_haddr),
        .hsize(ppi_hsize),
        .hsel(ppi_hsel),
        .hwrite(ppi_hwrite),
        .hwdata(ppi_hwdata),
        .hready(ppi_hready),
        .hrdata(ppi_hrdata),
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
        .tx_fifo_write(tx_fifo_write)
    );
    
    
    fifo TX_FIFO (
        .sys_clk(sys_clk),
        .sys_rst(sys_rst),
        .write(tx_fifo_write),
        .read(tx_fifo_read),
        .level(qspi_tx_fwl),
        .write_data(tx_fifo_write_data),
        .read_data(tx_fifo_read_data),
        .full(tx_fifo_full),
        .empty(tx_fifo_empty),
        .reached(tx_fifo_reached)
    );
    
    fifo RX_FIFO (
        .sys_clk(sys_clk),
        .sys_rst(sys_rst),
        .write(rx_fifo_write),
        .read(rx_fifo_read),
        .level(qspi_rx_fwl),
        .write_data(rx_fifo_write_data),
        .read_data(rx_fifo_read_data),
        .full(rx_fifo_full),
        .empty(rx_fifo_empty),
        .reached(rx_fifo_reached)
    );
    
    ahb_memory_mapped AHB_MMM (
        .sys_clk(sys_clk),
        .sys_rst(sys_rst),
        .hsel(pci_hsel),
        .hwrite(pci_hwrite),
        .hsize(pci_hsize),
        .hwdata(pci_hwdata),
        .haddr(pci_haddr),
        .hrdata(pci_hrdata),
        .hready(pci_hready),
        .rx_fifo_read_data(rx_fifo_read_data),
        .rx_fifo_empty(rx_fifo_empty),
        .rx_fifo_read(rx_fifo_read),
        .qspi_mode(qspi_mode),
        .cfg_reg_rx_fifo_read(cfg_reg_rx_fifo_read),
        .qspi_busy(qspi_busy),
        .qspi_done(qspi_done),
        .memory_mapped_mode_req(memory_mapped_mode_req),
        .memory_mapped_mode_addr(memory_mapped_mode_addr)
    );
    
    clock_generator CLK_GEN (
        .sys_clk(sys_clk),
        .sys_rst(sys_rst),
        .qspi_prescaler(qspi_prescaler),
        .protocol_clk_req(protocol_clk_req),
        .qspi_clk(qspi_clk)
    );
    
endmodule
