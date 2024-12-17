`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/05/2024 09:13:41 PM
// Design Name: 
// Module Name: fsm
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


module fsm(

    input qspi_clk,
    input qspi_rst,
    
    //fifo_control
    input tx_fifo_empty,
    output reg tx_fifo_read,
    
    input rx_fifo_full,
    output reg rx_fifo_write,
    
    //config0
    input qspi_mode,
    input qspi_sioo,
    input [2:0] qspi_cs_ht,
    input [8:0] qspi_data_length,
    input [4:0] qspi_dummy_length,
    input [3:0] qspi_cfg_length,
    input [2:0] qspi_addr_length,
    input qspi_cmd_length,
    input qspi_wr,
    input qspi_en,
    
    //config1
    
    //input qspi_sclk_mode,
    input qspi_data_ddr,
    input qspi_addr_ddr,

   
    //mode
    input [1:0] qspi_data_mode,
    input [1:0] qspi_addr_mode,
    input [1:0] qspi_cmd_mode,
    
    //request
    
    input memory_mapped_mode_req,
    input qspi_basic_mode_req,
    output reg protocol_clk_req,
    //counter,
    
    input bit_counter_done,
    input byte_counter_done,
    input data_byte_counter_done,
    
    //qspi_interface
    output reg [3:0] qspi_oe,
    output reg cs_n,
    
    //fsm_signal
    output reg transmit_en,
    output reg t_transmit_en,
    
    output reg receive_en,
    output reg t_receive_en,
    
    output reg ddr_en,
    output reg t_ddr_en,
    
    output reg data_update,
    output reg buffer_update,
    output reg next_phase_active,
    output reg counter_en,
    output reg t_counter_en,
    
    output reg [1:0] phase_mode,
    output reg [1:0] t_phase_mode,
    
    //busy_done
    
    output reg qspi_busy,
    output reg qspi_done,
    
    output reg serial_clk_en,
    
    
    output reg [3:0]current_state,
    output reg [3:0]next_state
    
    );
    
    parameter 
    IDLE = 4'h0,
    TX_COMMAND = 4'h1,
    TX_ADDRESS = 4'h2,
    TX_ALTERNATE = 4'h3,
    DUMMY = 4'h4,
    TURN_AROUND = 4'h5,
    TX_DATA = 4'h6,
    RX_DATA = 4'h7,
    CHIP_SELECT_HIGH_TIME = 4'h8;
    
    
    reg t_done;
    reg sioo_sent;
    reg [2:0]counter_cs_ht;
    reg t_rx_fifo_write;
    
    always@(*) begin
        if (qspi_en) begin
            if ((qspi_basic_mode_req && qspi_mode == 0) || (memory_mapped_mode_req && qspi_mode == 1) || current_state == CHIP_SELECT_HIGH_TIME ) begin
                protocol_clk_req = 1;
            end else protocol_clk_req = 0;
        end else protocol_clk_req = 0;
    end
    
    always@(negedge qspi_clk or posedge qspi_rst or negedge qspi_en)begin
        if(qspi_rst || qspi_en == 0) current_state <= IDLE; 
        else current_state <= next_state;
    end
    
    //xu li sioo
    always@(negedge qspi_clk or posedge qspi_rst) begin
        if(qspi_rst) begin
            sioo_sent = 0;
        end else begin
            if(qspi_en && qspi_mode && qspi_sioo) begin
                if(current_state == TX_COMMAND) sioo_sent = 1;      
            end
        end
    end
    //xu li tin hieu update cho transmit, counter va receive
    always@(negedge qspi_clk or posedge qspi_rst) begin
        if(qspi_rst) begin
            phase_mode <= 2'b0;
            transmit_en <= 0;
            receive_en <= 0;
            ddr_en <= 0;
            counter_en <= 0;
            qspi_done <= 0;
            rx_fifo_write <= 0;
        end else begin
            phase_mode <= t_phase_mode;
            transmit_en <= t_transmit_en;
            receive_en <= t_receive_en;
            ddr_en <= t_ddr_en;
            counter_en <= t_counter_en;
            qspi_done = t_done;
            rx_fifo_write <= t_rx_fifo_write;
        end
    end
    
    //counter chip_select_hightime
    always@(negedge qspi_clk) begin
        if(current_state == CHIP_SELECT_HIGH_TIME) begin
            counter_cs_ht = counter_cs_ht - 1'b1;  
        end else begin
            counter_cs_ht = (qspi_cs_ht - 1'b1);
        end
    end    
    
    
    //xu li output_enable
    
    always@(*) begin
        case(current_state)
            IDLE,TURN_AROUND,DUMMY,CHIP_SELECT_HIGH_TIME: qspi_oe = 4'b0000;
            TX_COMMAND: qspi_oe = (qspi_cmd_mode == 2'b00)?4'b0001:
                                  (qspi_cmd_mode == 2'b01)?4'b0011:
                                  (qspi_cmd_mode == 2'b10)?4'b1111:
                                  4'b0000;
            TX_ADDRESS: qspi_oe = (qspi_addr_mode == 2'b00)?4'b0001:
                                  (qspi_addr_mode == 2'b01)?4'b0011:
                                  (qspi_addr_mode == 2'b10)?4'b1111:
                                  4'b0000;
            TX_ALTERNATE: qspi_oe = (qspi_addr_mode == 2'b00)?4'b0001:
                                    (qspi_addr_mode == 2'b01)?4'b0011:
                                    (qspi_addr_mode == 2'b10)?4'b1111:
                                    4'b0000;
            TX_DATA, RX_DATA: qspi_oe = (qspi_data_mode == 2'b00)?4'b0011:
                                        (qspi_data_mode == 2'b01)?4'b0011:
                                        (qspi_data_mode == 2'b10)?4'b1111:
                                        4'b0000;
            default:  qspi_oe = 4'b0000;                         
        endcase
    end
   
    
    //xu li next_state va tin hieu dau ra
    always@(*) begin               
            case(current_state)
                IDLE: begin
                    data_update = 0;
                    buffer_update = 0;
                    t_rx_fifo_write = 0;
                    if (qspi_basic_mode_req || memory_mapped_mode_req) begin
                        if (qspi_cmd_length && (qspi_basic_mode_req || (memory_mapped_mode_req && sioo_sent != 1))) begin
                            next_state = TX_COMMAND;
                            t_transmit_en = 1;
                            t_receive_en = 0;
                            t_ddr_en = 0;
                            t_phase_mode = qspi_cmd_mode;
                            t_done = 0;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end else if (qspi_addr_length != 0) begin
                            next_state = TX_ADDRESS;
                            t_transmit_en = 1;
                            t_receive_en = 0;
                            t_ddr_en = qspi_addr_ddr;
                            t_phase_mode = qspi_addr_mode;
                            t_done = 0;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end else if (qspi_cfg_length != 0) begin
                            next_state = TX_ALTERNATE;
                            t_transmit_en = 1;
                            t_receive_en = 0;
                            t_ddr_en = qspi_addr_ddr;
                            t_phase_mode = qspi_addr_mode;
                            t_done = 0;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end else if (qspi_dummy_length != 0) begin
                            next_state = DUMMY;
                            t_transmit_en = 0;
                            t_receive_en = 0;
                            t_ddr_en = 0;
                            t_phase_mode = 2'b00;
                            t_done = 0;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end else if (qspi_data_length != 0) begin
                            if (qspi_wr) begin
                                next_state = TX_DATA;
                                t_transmit_en = 1;
                                t_receive_en = 0;
                                t_ddr_en = qspi_data_ddr;
                                t_phase_mode = qspi_data_mode;
                                t_done = 0;
                                next_phase_active = 1;
                                t_counter_en = 1;
                                serial_clk_en = 1;
                                qspi_busy = 1;
                                tx_fifo_read = 1;
                                cs_n = 0;
                            end else begin
                                next_state = TURN_AROUND;
                                t_transmit_en = 0;
                                t_receive_en = 0;
                                t_ddr_en = 0;
                                t_phase_mode = 2'b00;
                                t_done = 0;
                                next_phase_active = 0;
                                t_counter_en = 0;
                                serial_clk_en = 1;
                                qspi_busy = 1;
                                tx_fifo_read = 0;
                                cs_n = 0;
                            end
                        end else begin
                            next_state = CHIP_SELECT_HIGH_TIME;
                            t_transmit_en = 0;
                            t_receive_en = 0;
                            t_ddr_en = 0;
                            t_phase_mode = 2'b00;
                            t_done = 1;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end
                    end else begin
                        next_state = IDLE;
                        t_transmit_en = 0;
                        t_receive_en = 0;
                        t_ddr_en = 0;
                        t_phase_mode = 2'b00;
                        t_done = 0;
                        next_phase_active = 0;
                        t_counter_en = 0;
                        serial_clk_en = 0;
                        qspi_busy = 0;
                        tx_fifo_read = 0;
                        cs_n = 1; 
                    end 
                end
                TX_COMMAND: begin
                    data_update = 0;
                    buffer_update = 0;
                    t_rx_fifo_write = 0;  
                    if (byte_counter_done) begin
                        if (qspi_addr_length != 0) begin
                            next_state = TX_ADDRESS;
                            t_transmit_en = 1;
                            t_receive_en = 0;
                            t_ddr_en = qspi_addr_ddr;
                            t_phase_mode = qspi_addr_mode;
                            t_done = 0;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end else if (qspi_cfg_length != 0) begin
                            next_state = TX_ALTERNATE;
                            t_transmit_en = 1;
                            t_receive_en = 0;
                            t_ddr_en = qspi_addr_ddr;
                            t_phase_mode = qspi_addr_mode;
                            t_done = 0;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end else if (qspi_dummy_length != 0) begin
                            next_state = DUMMY;
                            t_transmit_en = 0;
                            t_receive_en = 0;
                            t_ddr_en = 0;
                            t_phase_mode = 2'b00;
                            t_done = 0;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end else if (qspi_data_length != 0) begin
                            if (qspi_wr) begin
                                next_state = TX_DATA;
                                t_transmit_en = 1;
                                t_receive_en = 0;
                                t_ddr_en = qspi_data_ddr;
                                t_phase_mode = qspi_data_mode;
                                t_done = 0;
                                next_phase_active = 1;
                                t_counter_en = 1;
                                serial_clk_en = 1;
                                qspi_busy = 1;
                                tx_fifo_read = 1;
                                cs_n = 0;
                            end else begin
                                next_state = TURN_AROUND;
                                t_transmit_en = 0;
                                t_receive_en = 0;
                                t_ddr_en = 0;
                                t_phase_mode = 2'b00;
                                t_done = 0;
                                next_phase_active = 0;
                                t_counter_en = 0;
                                serial_clk_en = 1;
                                qspi_busy = 1;
                                tx_fifo_read = 0;
                                cs_n = 0;
                            end
                        end else begin
                            next_state = CHIP_SELECT_HIGH_TIME;
                            t_transmit_en = 0;
                            t_receive_en = 0;
                            t_ddr_en = 0;
                            t_phase_mode = 2'b00;
                            t_done = 1;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end
                    end else begin
                        next_state = TX_COMMAND;
                        t_transmit_en = 1;
                        t_receive_en = 0;
                        t_ddr_en = 0;
                        t_phase_mode = qspi_cmd_mode;
                        t_done = 0;
                        next_phase_active = 0;
                        t_counter_en = 1;
                        serial_clk_en = 1;
                        qspi_busy = 1;
                        t_done = 0;
                        tx_fifo_read = 0;
                        cs_n = 0;
                    end
                end
                TX_ADDRESS: begin
                    data_update = 0;
                    buffer_update = 0;
                    t_rx_fifo_write = 0;  
                    if (byte_counter_done) begin
                        if (qspi_cfg_length != 0) begin
                            next_state = TX_ALTERNATE;
                            t_transmit_en = 1;
                            t_receive_en = 0;
                            t_ddr_en = qspi_addr_ddr;
                            t_phase_mode = qspi_addr_mode;
                            t_done = 0;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end else if (qspi_dummy_length != 0) begin
                            next_state = DUMMY;
                            t_transmit_en = 0;
                            t_receive_en = 0;
                            t_ddr_en = 0;
                            t_phase_mode = 2'b00;
                            t_done = 0;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end else if (qspi_data_length != 0) begin
                            if (qspi_wr) begin
                                next_state = TX_DATA;
                                t_transmit_en = 1;
                                t_receive_en = 0;
                                t_ddr_en = qspi_data_ddr;
                                t_phase_mode = qspi_data_mode;
                                t_done = 0;
                                next_phase_active = 1;
                                t_counter_en = 1;
                                serial_clk_en = 1;
                                qspi_busy = 1;
                                tx_fifo_read = 1;
                                cs_n = 0;
                            end else begin
                                next_state = TURN_AROUND;
                                t_transmit_en = 0;
                                t_receive_en = 0;
                                t_ddr_en = 0;
                                t_phase_mode = 2'b00;
                                t_done = 0;
                                next_phase_active = 0;
                                t_counter_en = 0;
                                serial_clk_en = 1;
                                qspi_busy = 1;
                                tx_fifo_read = 0;
                                cs_n = 0;
                            end
                        end else begin
                            next_state = CHIP_SELECT_HIGH_TIME;
                            t_transmit_en = 0;
                            t_receive_en = 0;
                            t_ddr_en = 0;
                            t_phase_mode = 2'b00;
                            t_done = 1;
                            next_phase_active = 1;
                            t_counter_en = 0;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end
                    end else begin
                        next_state = TX_ADDRESS;
                        t_transmit_en = 1;
                        t_receive_en = 0;
                        t_ddr_en = qspi_addr_ddr;
                        t_phase_mode = qspi_addr_mode;
                        t_done = 0;
                        next_phase_active = 0;
                        t_counter_en = 1;
                        serial_clk_en = 1;
                        qspi_busy = 1;
                        t_done = 0;
                        tx_fifo_read = 0;
                        cs_n = 0;
                    end
                end
                    
                TX_ALTERNATE: begin
                    data_update = 0;
                    buffer_update = 0;
                    t_rx_fifo_write = 0;  
                    if (byte_counter_done) begin
                        if (qspi_dummy_length != 0) begin
                            next_state = DUMMY;
                            t_transmit_en = 0;
                            t_receive_en = 0;
                            t_ddr_en = 0;
                            t_phase_mode = 2'b00;
                            t_done = 0;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end else if (qspi_data_length != 0) begin
                            if (qspi_wr) begin
                                next_state = TX_DATA;
                                t_transmit_en = 1;
                                t_receive_en = 0;
                                t_ddr_en = qspi_data_ddr;
                                t_phase_mode = qspi_data_mode;
                                t_done = 0;
                                next_phase_active = 1;
                                t_counter_en = 1;
                                serial_clk_en = 1;
                                qspi_busy = 1;
                                tx_fifo_read = 1;
                                cs_n = 0;
                            end else begin
                                next_state = TURN_AROUND;
                                t_transmit_en = 0;
                                t_receive_en = 0;
                                t_ddr_en = 0;
                                t_phase_mode = 2'b00;
                                t_done = 0;
                                next_phase_active = 0;
                                t_counter_en = 0;
                                serial_clk_en = 1;
                                qspi_busy = 1;
                                tx_fifo_read = 0;
                                cs_n = 0;
                            end
                        end else begin
                            next_state = CHIP_SELECT_HIGH_TIME;
                            t_transmit_en = 0;
                            t_receive_en = 0;
                            t_ddr_en = 0;
                            t_phase_mode = 2'b00;
                            t_done = 1;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end
                    end else begin
                        next_state = TX_ALTERNATE;
                        t_transmit_en = 1;
                        t_receive_en = 0;
                        t_ddr_en = qspi_addr_ddr;
                        t_phase_mode = qspi_addr_mode;
                        t_done = 0;
                        next_phase_active = 0;
                        t_counter_en = 1;
                        serial_clk_en = 1;
                        qspi_busy = 1;
                        t_done = 0;
                        tx_fifo_read = 0;
                        cs_n = 0;
                    end      
                end    
                DUMMY: begin
                    data_update = 0;
                    buffer_update = 0;
                    t_rx_fifo_write = 0;  
                    if (byte_counter_done) begin
                        if (qspi_data_length != 0) begin
                            if (qspi_wr) begin
                                next_state = TX_DATA;
                                t_transmit_en = 1;
                                t_receive_en = 0;
                                t_ddr_en = qspi_data_ddr;
                                t_phase_mode = qspi_data_mode;
                                t_done = 0;
                                next_phase_active = 1;
                                t_counter_en = 1;
                                serial_clk_en = 1;
                                qspi_busy = 1;
                                tx_fifo_read = 1;
                                cs_n = 0;
                            end else begin
                                next_state = TURN_AROUND;
                                t_transmit_en = 0;
                                t_receive_en = 0;
                                t_ddr_en = 0;
                                t_phase_mode = 2'b00;
                                t_done = 0;
                                next_phase_active = 0;
                                t_counter_en = 0;
                                serial_clk_en = 1;
                                qspi_busy = 1;
                                tx_fifo_read = 0;
                                cs_n = 0;
                            end
                        end else begin
                            next_state = CHIP_SELECT_HIGH_TIME;
                            t_transmit_en = 0;
                            t_receive_en = 0;
                            t_ddr_en = 0;
                            t_phase_mode = 2'b00;
                            t_done = 1;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end
                    end else begin
                        next_state = DUMMY;
                        t_transmit_en = 0;
                        t_receive_en = 0;
                        t_ddr_en = 0;
                        t_phase_mode = 2'b00;
                        t_done = 0;
                        next_phase_active = 0;
                        t_counter_en = 1;
                        serial_clk_en = 1;
                        qspi_busy = 1;
                        t_done = 0;
                        tx_fifo_read = 0;
                        cs_n = 0;
                    end               
                end
                TURN_AROUND: begin
                            next_state = RX_DATA;
                            t_rx_fifo_write = 0;
                            data_update = 0;
                            buffer_update = 0;
                            t_transmit_en = 0;
                            t_receive_en = 1;
                            t_ddr_en = qspi_data_ddr;
                            t_phase_mode = qspi_data_mode;
                            t_done = 0;
                            next_phase_active = 1;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;    
                end
                
                TX_DATA: begin
                    if(data_byte_counter_done) begin
                        next_state = CHIP_SELECT_HIGH_TIME;
                        data_update = 0;
                        buffer_update = 0;
                        t_rx_fifo_write = 0;
                        t_transmit_en = 0;
                        t_receive_en = 0;
                        t_ddr_en = 0;
                        t_phase_mode = 2'b00;
                        t_done = 1;
                        next_phase_active = 1;
                        t_counter_en = 0;
                        serial_clk_en = 1;
                        qspi_busy = 1;
                        tx_fifo_read = 0;
                        cs_n = 0;  
                    end else begin
                        if(byte_counter_done) begin
                            if(tx_fifo_empty) begin
                                next_state = TX_DATA;
                                data_update = 0;
                                buffer_update = 0;
                                t_rx_fifo_write = 0;
                                t_transmit_en = 0;
                                t_receive_en = 0;
                                t_ddr_en = 0;
                                t_phase_mode = 2'b00;
                                t_done = 0;
                                next_phase_active = 0;
                                t_counter_en = 0;
                                serial_clk_en = 1;
                                qspi_busy = 1;
                                tx_fifo_read = 0;
                                cs_n = 0;
                            end else begin
                                next_state = TX_DATA;
                                data_update = 1;
                                buffer_update = 0;
                                t_rx_fifo_write = 0;
                                t_transmit_en = 1;
                                t_receive_en = 0;
                                t_ddr_en = qspi_data_ddr;
                                t_phase_mode = qspi_data_mode;
                                t_done = 0;
                                next_phase_active = 0;
                                t_counter_en = 1;
                                serial_clk_en = 1;
                                qspi_busy = 1;
                                tx_fifo_read = 1;
                                cs_n = 0;
                            end
                        end else begin
                            next_state = TX_DATA;
                            data_update = 0;
                            buffer_update = 0;
                            t_rx_fifo_write = 0;
                            t_transmit_en = 1;
                            t_receive_en = 0;
                            t_ddr_en = qspi_data_ddr;
                            t_phase_mode = qspi_data_mode;
                            t_done = 0;
                            next_phase_active = 0;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end
                   end         
                end
                RX_DATA: begin
                   if(data_byte_counter_done) begin
                        if(rx_fifo_full) begin
                            next_state = RX_DATA;
                            data_update = 0;
                            buffer_update = 0;
                            t_rx_fifo_write = 0;
                            t_transmit_en = 0;
                            t_receive_en = 1;
                            t_ddr_en = qspi_data_ddr;
                            t_phase_mode = qspi_data_mode;
                            t_done = 0;
                            next_phase_active = 0;
                            t_counter_en = 0;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end else begin
                            next_state = CHIP_SELECT_HIGH_TIME;
                            data_update = 0;
                            buffer_update = 1;
                            t_rx_fifo_write = 1;
                            t_transmit_en = 0;
                            t_receive_en = 0;
                            t_ddr_en = 0;
                            t_phase_mode = 2'b00;
                            t_done = 1;
                            next_phase_active = 1;
                            t_counter_en = 0;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0; 
                        end   
                   end else if(byte_counter_done) begin
                        if(rx_fifo_full) begin
                            next_state = RX_DATA;
                            data_update = 0;
                            buffer_update = 0;
                            t_rx_fifo_write = 0;
                            t_transmit_en = 0;
                            t_receive_en = 0;
                            t_ddr_en = qspi_data_ddr;
                            t_phase_mode = qspi_data_mode;
                            t_done = 0;
                            next_phase_active = 0;
                            t_counter_en = 0;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0; 
                        end else begin
                            next_state = RX_DATA;
                            data_update = 0;
                            buffer_update = 1;
                            t_rx_fifo_write = 1;
                            t_transmit_en = 0;
                            t_receive_en = 1;
                            t_ddr_en = qspi_data_ddr;
                            t_phase_mode = qspi_data_mode;
                            t_done = 0;
                            next_phase_active = 0;
                            t_counter_en = 1;
                            serial_clk_en = 1;
                            qspi_busy = 1;
                            tx_fifo_read = 0;
                            cs_n = 0;
                        end
                   end else if(bit_counter_done) begin
                        next_state = RX_DATA;
                        data_update = 0;
                        buffer_update = 1;
                        t_rx_fifo_write = 0;
                        t_transmit_en = 0;
                        t_receive_en = 1;
                        t_ddr_en = qspi_data_ddr;
                        t_phase_mode = qspi_data_mode;
                        t_done = 0;
                        next_phase_active = 0;
                        t_counter_en = 1;
                        serial_clk_en = 1;
                        qspi_busy = 1;
                        tx_fifo_read = 0;
                        cs_n = 0; 
                   end else begin
                        next_state = RX_DATA;
                        data_update = 0;
                        buffer_update = 0;
                        t_rx_fifo_write = 0;
                        t_transmit_en = 0;
                        t_receive_en = 1;
                        t_ddr_en = qspi_data_ddr;
                        t_phase_mode = qspi_data_mode;
                        t_done = 0;
                        next_phase_active = 0;
                        t_counter_en = 1;
                        serial_clk_en = 1;
                        qspi_busy = 1;
                        tx_fifo_read = 0;
                        cs_n = 0;
                   end
                end
                CHIP_SELECT_HIGH_TIME: begin
                    next_state = (counter_cs_ht == 0)? IDLE : CHIP_SELECT_HIGH_TIME;
                    data_update = 0;
                    buffer_update = 0;
                    t_rx_fifo_write = 0;
                    t_transmit_en = 0;
                    t_receive_en = 0;
                    t_ddr_en = 0;
                    t_phase_mode = 2'b00;
                    t_done = 0;
                    next_phase_active = 0;
                    t_counter_en = 0;
                    serial_clk_en = 1;
                    qspi_busy = 0;
                    tx_fifo_read = 0;
                    cs_n = 0;
                end
                default: begin
                    next_state = IDLE;
                    data_update = 0;
                    buffer_update = 0;
                    t_rx_fifo_write = 0;
                    t_transmit_en = 0;
                    t_receive_en = 0;
                    t_ddr_en = 0;
                    t_phase_mode = 2'b00;
                    t_done = 0;
                    next_phase_active = 0;
                    t_counter_en = 0;
                    serial_clk_en = 0;
                    qspi_busy = 0;
                    tx_fifo_read = 0;
                    cs_n = 0;
                end  
            endcase
       end
    
endmodule
