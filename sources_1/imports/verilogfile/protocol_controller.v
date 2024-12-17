`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2024 02:09:22 PM
// Design Name: 
// Module Name: protocol_controller
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


module protocol_controller(
    //connect to reset and clock gen
    input qspi_clk,
    input qspi_rst,
    output protocol_clk_req,
    
    //connect to tx_fifo
    input tx_fifo_empty,
    input [31:0]tx_fifo_read_data,
    output tx_fifo_read,
    
    //connect to rx_fifo
    input rx_fifo_full,
    output [31:0]rx_fifo_write_data,
    output rx_fifo_write,
    
    //connect to ahb_memory_mapped,
    input memory_mapped_mode_req,
    input [31:0]memory_mapped_mode_addr,
    
    //conenct to register_configuration
        //config0
    input qspi_mode,
    //input [1:0] qspi_prescaler,
    input qspi_sioo,
    input [2:0] qspi_cs_ht,
    input [8:0] qspi_data_length,
    input [4:0] qspi_dummy_length,
    input [3:0] qspi_cfg_length,
    input [2:0] qspi_addr_length,
    input qspi_cmd_length,
    input qspi_wr,
    input qspi_en,
    
    input qspi_sclk_mode,
    input qspi_data_ddr,
    input qspi_addr_ddr,
    input qspi_dummy_hiz,
    input qspi_out2,
    input qspi_out3, 
    
    input [1:0] qspi_data_mode,
    input [1:0] qspi_addr_mode,
    input [1:0] qspi_cmd_mode,
    
    //qspi intstr0,intstr1
    input [31:0] qspi_addr,
    input [7:0] qspi_cmd,
    input [7:0] qspi_cfg,
    
    //transaction_req and busy,done
    input qspi_basic_mode_req,
    output qspi_done,
    output qspi_busy,
    
    //qspi_interface
    output qspi_sclk,
    output cs_n,
    output [3:0] qspi_oe,
    output [3:0] qio_out,
    input  [3:0] qio_in,
    
    //signal to observe activation of interface
        //state
    output [3:0] current_state,
    //output [3:0] next_state,
        //enable_signal
    output ddr_en,
    //output transmit_en,
    //output receive_en,
    output [1:0]phase_mode,
    //output next_phase_active,
    //output counter_en,
        //counter_signal
    output [2:0]bit_counter,
    output [1:0]byte_counter,
    output [8:0]data_byte_counter,
    output bit_counter_done,
    output byte_counter_done,
    output data_byte_counter_done
    
    );
    wire [3:0] next_state;  
    wire transmit_en;
    wire receive_en;
    wire next_phase_active;
    wire counter_en;
    
    
    //wire transmit_en;
    wire t_transmit_en;
    //wire receive_en;
    wire t_receive_en;
    //wire ddr_en;
    wire t_ddr_en;
    wire data_update;
    wire buffer_update;
    //wire next_phase_active;
    wire t_counter_en;
    //wire [1:0] phase_mode;
    wire [1:0]t_phase_mode;
    wire serial_clk_en;
    
    output_clock_gating SCLK (
        .qspi_clk(qspi_clk),
        .serial_clk_en(serial_clk_en),
        .qspi_sclk_mode(qspi_sclk_mode),
        .qspi_sclk(qspi_sclk)
    );
    
    fsm FSM (
        .qspi_clk(qspi_clk),
        .qspi_rst(qspi_rst),

        // FIFO control
        .tx_fifo_empty(tx_fifo_empty),
        .tx_fifo_read(tx_fifo_read),
        .rx_fifo_full(rx_fifo_full),
        .rx_fifo_write(rx_fifo_write),

        // Config 0
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

        // Config 1
        .qspi_data_ddr(qspi_data_ddr),
        .qspi_addr_ddr(qspi_addr_ddr),

        // Mode
        .qspi_data_mode(qspi_data_mode),
        .qspi_addr_mode(qspi_addr_mode),
        .qspi_cmd_mode(qspi_cmd_mode),

        // Request
        .memory_mapped_mode_req(memory_mapped_mode_req),
        .qspi_basic_mode_req(qspi_basic_mode_req),
        .protocol_clk_req(protocol_clk_req),

        // Counter
        .bit_counter_done(bit_counter_done),
        .byte_counter_done(byte_counter_done),
        .data_byte_counter_done(data_byte_counter_done),

        // QSPI Interface
        .qspi_oe(qspi_oe),
        .cs_n(cs_n),

        // FSM Signals
        .transmit_en(transmit_en),
        .t_transmit_en(t_transmit_en),
        .receive_en(receive_en),
        .t_receive_en(t_receive_en),
        .ddr_en(ddr_en),
        .t_ddr_en(t_ddr_en),
        .data_update(data_update),
        .buffer_update(buffer_update),
        .next_phase_active(next_phase_active),
        .counter_en(counter_en),
        .t_counter_en(t_counter_en),
        .phase_mode(phase_mode),
        .t_phase_mode(t_phase_mode),

        // Busy Done
        .qspi_busy(qspi_busy),
        .qspi_done(qspi_done),

        .serial_clk_en(serial_clk_en),
        .current_state(current_state),
        .next_state(next_state)
    );
    
    counter COUNTER (
        .qspi_clk(qspi_clk),
        .qspi_rst(qspi_rst),
        .next_phase_active(next_phase_active),
        .t_ddr_en(t_ddr_en),
        .counter_en(counter_en),
        .t_counter_en(t_counter_en),
        .qspi_data_length(qspi_data_length),
        .qspi_dummy_length(qspi_dummy_length),
        .qspi_addr_length(qspi_addr_length),
        .t_phase_mode(t_phase_mode),
        .next_state(next_state),
        .current_state(current_state),
        .bit_counter_done(bit_counter_done),
        .byte_counter_done(byte_counter_done),
        .data_byte_counter_done(data_byte_counter_done),
        .bit_counter(bit_counter),
        .byte_counter(byte_counter),
        .data_byte_counter(data_byte_counter)
    );
    
    receiver RECEIVER (
        .qspi_clk(qspi_clk),
        .qspi_rst(qspi_rst),
        .ddr_en(ddr_en),
        .t_ddr_en(t_ddr_en),
        .receive_en(receive_en),
        .t_receive_en(t_receive_en),
        .t_phase_mode(t_phase_mode),
        .phase_mode(phase_mode),
        .buffer_update(buffer_update),
        .qio_in(qio_in),
        .rx_fifo_data(rx_fifo_write_data)
    );
    
    transmitter TRANSMITTER (
        .qspi_clk(qspi_clk),
        .qspi_rst(qspi_rst),
        .qspi_basic_mode_req(qspi_basic_mode_req),
        .memory_mapped_mode_req(memory_mapped_mode_req),
        .qspi_cmd(qspi_cmd),
        .qspi_cfg(qspi_cfg),
        .qspi_addr(qspi_addr),
        .memory_mapped_mode_addr(memory_mapped_mode_addr),
        .tx_fifo_data(tx_fifo_read_data),
        .next_state(next_state),
        .ddr_en(ddr_en),
        .t_ddr_en(t_ddr_en),
        .t_phase_mode(t_phase_mode),
        .phase_mode(phase_mode),
        .next_phase_active(next_phase_active),
        .t_transmit_en(t_transmit_en),
        .data_update(data_update),
        .qspi_out2(qspi_out2),
        .qspi_out3(qspi_out3),
        .qspi_data_length(qspi_data_length),
        .qspi_addr_length(qspi_addr_length),
        .data_byte_counter(data_byte_counter),
        .qio_out(qio_out)
    );
    
    
    
endmodule
