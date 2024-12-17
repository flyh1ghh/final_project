`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2024 03:43:10 PM
// Design Name: 
// Module Name: configuration_registers 
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


module configuration_registers(
    //clock and reset
    input sys_clk,
    input sys_rst,
      
    // ahb1 slave interface
    input [31:0] haddr,
    input [2:0] hsize,
    input hsel,
    input hwrite,
    input [31:0] hwdata,
    output reg hready,
    output reg [31:0]hrdata,
     
    //signal basic mode
    output qspi_basic_mode_req,
    input qspi_done,
    input qspi_busy,
    
    //qspi config
    
    output qspi_mode,
    output [1:0] qspi_prescaler,
    output qspi_sioo,
    output [2:0] qspi_cs_ht,
    output [8:0] qspi_data_length,
    output [4:0] qspi_dummy_length,
    output [3:0] qspi_cfg_length,
    output [2:0] qspi_addr_length,
    output qspi_cmd_length,
    output qspi_wr,
    output qspi_en,
    
    //qspi config1
    output qspi_sclk_mode,
    output qspi_data_ddr,
    output qspi_addr_ddr,
    output qspi_dummy_hiz,
    output qspi_out2,
    output qspi_out3,
    
    //qspi mode
    output [4:0] qspi_tx_fwl,
    output [4:0] qspi_rx_fwl,
    output [1:0] qspi_data_mode,
    output [1:0] qspi_addr_mode,
    output [1:0] qspi_cmd_mode,
    
    //qspi intstr0
    output [31:0] qspi_addr,
    
    //qspi intstr1
    output [7:0] qspi_cmd,
    output [7:0] qspi_cfg,
    
    //qspi wdata
    output [31:0] tx_fifo_write_data,
    
    //status fifo
    input tx_fifo_reached,
    input tx_fifo_full,
    input tx_fifo_empty,
    input rx_fifo_reached,
    input rx_fifo_full,
    input rx_fifo_empty,
    
    
    //control fifo
    output  reg cfg_reg_rx_fifo_read,
    input [31:0] rx_fifo_read_data,
    output  reg tx_fifo_write,
    
    output reg [2:0] current_state,
    output reg [2:0] next_state
         
    );

    reg [31:0] QSPICONFIG0;
    reg [31:0] QSPICONFIG1;
    reg [31:0] QSPIMODE;
    reg [31:0] QSPIINTSTR0;
    reg [31:0] QSPIINTSTR1;
    reg [31:0] QSPIWDATA;
    reg [31:0] QSPIRDATA;
    reg [31:0] QSPISTATUS;
    reg [31:0] QSPIINTENA;
    reg [31:0] QSPIINTSTS;
    
    reg [31:0] t_haddr;
    reg t_hwrite;
    reg [2:0] t_hsize;
    
    //address register
    
    parameter QSPICONFIG0_ADDR = 32'h00000000,
              QSPICONFIG1_ADDR = 32'h00000004,
              QSPIMODE_ADDR    = 32'h00000008,
              QSPIINTSTR0_ADDR = 32'h0000000C,
              QSPIINTSTR1_ADDR = 32'h00000010,
              QSPIWDATA_ADDR   = 32'h00000014,
              QSPIRDATA_ADDR   = 32'h00000018,
              QSPISTATUS_ADDR  = 32'h0000001C;
              //QSPIINTENA_ADDR  = 32'h00000020,
              //QSPIINTSTS_ADDR  = 32'h00000024;
    
    //state and next_state;
    
    parameter RESET = 3'h0,
              IDLE = 3'h1,
              ADDR = 3'h2,  
              WDATA = 3'h3,
              TX_FIFO_WRITE = 3'h4, 
              RDATA = 3'h5, 
              RX_FIFO_READ = 3'h6;
    
    always@(posedge sys_clk or posedge sys_rst) begin
        if(sys_rst) begin
            current_state <= RESET;
        end else current_state <= next_state;    
    end
    
    //up_date_status
    
    always@(*)begin
        if(sys_rst) begin
            QSPISTATUS = 32'b0;    
        end else begin
            QSPISTATUS = {25'b0, tx_fifo_reached,tx_fifo_full,tx_fifo_empty,rx_fifo_reached,rx_fifo_full,rx_fifo_empty,qspi_busy};
        end
    
    end
    
    always@(posedge qspi_done or posedge sys_rst or posedge qspi_en) begin
        if(sys_rst || qspi_done )
            QSPICONFIG0[31] <= 0;
        else if(qspi_en && ~qspi_mode )
            QSPICONFIG0[31] <= 1;
        end    
               
    
    
    always@(*) begin
        case(current_state)
            RESET: begin
                QSPICONFIG0[30:0] = 31'b0;
                QSPICONFIG1 = 32'b0;
                QSPIMODE = 32'b0;
                QSPIINTSTR0 = 32'b0;
                QSPIINTSTR1 = 32'b0;
                QSPIWDATA = 32'b0;
                QSPIRDATA = 32'b0;
                if(hsel) begin
                    next_state = ADDR;
                    t_hwrite = hwrite;
                    t_hsize = hsize;
                end
                else next_state = IDLE; 
                cfg_reg_rx_fifo_read = 0;
                tx_fifo_write = 0;   
            end
            IDLE: begin
                cfg_reg_rx_fifo_read = 0;
                tx_fifo_write = 0;
                hready = 1;
                if(hsel) begin
                    next_state = ADDR;
                    t_hwrite = hwrite;
                    t_hsize = hsize;
                end
                else next_state = IDLE;
            end
            ADDR: begin
                cfg_reg_rx_fifo_read = 0;
                tx_fifo_write = 0;
                hready = 1;
                t_haddr = haddr;
                if(t_hwrite) begin
                   next_state = WDATA;    
                end else begin
                   next_state = RDATA;
                end
            end     
            WDATA: begin
                case(t_haddr)
                    QSPICONFIG0_ADDR: begin
                        if (qspi_busy != 1) begin
                            case (t_hsize)
                                3'b000: QSPICONFIG0[7:0] = hwdata[7:0];
                                3'b001: QSPICONFIG0[15:0] = hwdata[15:0];
                                3'b010: QSPICONFIG0[30:0] = hwdata[30:0];
                                default: QSPICONFIG0 = QSPICONFIG0;
                            endcase
                        end
                        next_state = hsel ? ADDR : IDLE;
                        t_hwrite = hwrite;
                        t_hsize = hsize;
                        hready = 1;
                        cfg_reg_rx_fifo_read = 0;
                        tx_fifo_write = 0;
                    end
                    QSPICONFIG1_ADDR: begin
                        if (qspi_busy != 1) begin
                            case (t_hsize)
                                3'b000: QSPICONFIG1[7:0] = hwdata[7:0];
                                3'b001: QSPICONFIG1[15:0] = hwdata[15:0];
                                3'b010: QSPICONFIG1 = hwdata;
                                default: QSPICONFIG1 = QSPICONFIG1;
                            endcase
                        end
                        next_state = hsel ? ADDR : IDLE;
                        t_hwrite = hwrite;
                        t_hsize = hsize;
                        hready = 1;
                        cfg_reg_rx_fifo_read = 0;
                        tx_fifo_write = 0;
                    end
            
                    QSPIMODE_ADDR: begin
                        if (qspi_busy != 1) begin
                            case (t_hsize)
                                3'b000: QSPIMODE[7:0] = hwdata[7:0];
                                3'b001: QSPIMODE[15:0] = hwdata[15:0];
                                3'b010: QSPIMODE = hwdata;
                                default: QSPIMODE = QSPIMODE;
                            endcase
                        end
                        next_state = hsel ? ADDR : IDLE;
                        t_hwrite = hwrite;
                        t_hsize = hsize;
                        hready = 1;
                        cfg_reg_rx_fifo_read = 0;
                        tx_fifo_write = 0;
                    end
            
                    QSPIINTSTR0_ADDR: begin
                        if (qspi_busy != 1) begin
                            case (t_hsize)
                                3'b000: QSPIINTSTR0[7:0] = hwdata[7:0];
                                3'b001: QSPIINTSTR0[15:0] = hwdata[15:0];
                                3'b010: QSPIINTSTR0 = hwdata;
                                default: QSPIINTSTR0 = QSPIINTSTR0;
                            endcase
                        end
                        next_state = hsel ? ADDR : IDLE;
                        t_hwrite = hwrite;
                        t_hsize = hsize;
                        hready = 1;
                        cfg_reg_rx_fifo_read = 0;
                        tx_fifo_write = 0;
                    end
            
                    QSPIINTSTR1_ADDR: begin
                        if (qspi_busy != 1) begin
                            case (t_hsize)
                                3'b000: QSPIINTSTR1[7:0] = hwdata[7:0];
                                3'b001: QSPIINTSTR1[15:0] = hwdata[15:0];
                                3'b010: QSPIINTSTR1 = hwdata;
                                default: QSPIINTSTR1 = QSPIINTSTR1;
                            endcase
                        end
                        next_state = hsel ? ADDR : IDLE;
                        t_hwrite = hwrite;
                        t_hsize = hsize;
                        hready = 1;
                        cfg_reg_rx_fifo_read = 0;
                        tx_fifo_write = 0;
                    end
            
                    QSPIWDATA_ADDR: begin
                        case (t_hsize)
                                3'b000: QSPIWDATA[7:0] = hwdata[7:0];
                                3'b001: QSPIWDATA[15:0] = hwdata[15:0];
                                3'b010: QSPIWDATA = hwdata;
                                default: QSPIWDATA = QSPIWDATA;
                        endcase
                        next_state = TX_FIFO_WRITE;
                        hready = 0;
                        cfg_reg_rx_fifo_read = 0;
                        tx_fifo_write = 0;
                    end
            
                    default: begin
                        next_state = IDLE;
                        hready = 1;
                        cfg_reg_rx_fifo_read = 0;
                        tx_fifo_write = 0;
                    end
                endcase
            end
            
            TX_FIFO_WRITE: begin
                if(~tx_fifo_full) begin
                    tx_fifo_write = 1;
                    cfg_reg_rx_fifo_read = 0;
                    next_state = hsel ? ADDR : IDLE;
                    t_hwrite = hwrite;
                    t_hsize = hsize;
                    hready = 1;
                end else begin
                    tx_fifo_write = 0;
                    cfg_reg_rx_fifo_read = 0;  
                    next_state = TX_FIFO_WRITE;
                    hready = 0;
                end
            end
            
            RDATA: begin
                case(t_haddr)
                    QSPICONFIG0_ADDR: begin
                        case (t_hsize)
                            3'b000: hrdata[7:0] = QSPICONFIG0[7:0];
                            3'b001: hrdata[15:0] = QSPICONFIG0[15:0];
                            3'b010: hrdata[31:0] = QSPICONFIG0;
                            default: hrdata = 32'b0;
                        endcase
                        if (hsel) begin
                            next_state = ADDR;
                            t_hwrite = hwrite;
                            t_hsize = hsize; // C?p nh?t t_hsize n?u hsel
                        end else next_state = IDLE;
                        hready = 1;
                        cfg_reg_rx_fifo_read = 0;
                        tx_fifo_write = 0;
                    end
                    
                    QSPICONFIG1_ADDR: begin
                        case (t_hsize)
                            3'b000: hrdata[7:0] = QSPICONFIG1[7:0];
                            3'b001: hrdata[15:0] = QSPICONFIG1[15:0];
                            3'b010: hrdata[31:0] = QSPICONFIG1;
                            default: hrdata = 32'b0;
                        endcase
                        if (hsel) begin
                            next_state = ADDR;
                            t_hwrite = hwrite;
                            t_hsize = hsize; // C?p nh?t t_hsize n?u hsel
                        end else next_state = IDLE;
                        hready = 1;
                        cfg_reg_rx_fifo_read = 0;
                        tx_fifo_write = 0;
                    end
                    
                    QSPIMODE_ADDR: begin
                        case (t_hsize)
                            3'b000: hrdata[7:0] = QSPIMODE[7:0];
                            3'b001: hrdata[15:0] = QSPIMODE[15:0];
                            3'b010: hrdata[31:0] = QSPIMODE;
                            default: hrdata = 32'b0;
                        endcase
                        if (hsel) begin
                            next_state = ADDR;
                            t_hwrite = hwrite;
                            t_hsize = hsize; // C?p nh?t t_hsize n?u hsel
                        end else next_state = IDLE;
                        hready = 1;
                        cfg_reg_rx_fifo_read = 0;
                        tx_fifo_write = 0;
                    end
                    
                    QSPIINTSTR0_ADDR: begin
                        case (t_hsize)
                            3'b000: hrdata[7:0] = QSPIINTSTR0[7:0];
                            3'b001: hrdata[15:0] = QSPIINTSTR0[15:0];
                            3'b010: hrdata[31:0] = QSPIINTSTR0;
                            default: hrdata = 32'b0;
                        endcase
                        if (hsel) begin
                            next_state = ADDR;
                            t_hwrite = hwrite;
                            t_hsize = hsize; // C?p nh?t t_hsize n?u hsel
                        end else next_state = IDLE;
                        hready = 1;
                        cfg_reg_rx_fifo_read = 0;
                        tx_fifo_write = 0;
                    end
                    
                    QSPIINTSTR1_ADDR: begin
                        case (t_hsize)
                            3'b000: hrdata[7:0] = QSPIINTSTR1[7:0];
                            3'b001: hrdata[15:0] = QSPIINTSTR1[15:0];
                            3'b010: hrdata[31:0] = QSPIINTSTR1;
                            default: hrdata = 32'b0;
                        endcase
                        if (hsel) begin
                            next_state = ADDR;
                            t_hwrite = hwrite;
                            t_hsize = hsize; // C?p nh?t t_hsize n?u hsel
                        end else next_state = IDLE;
                        hready = 1;
                        cfg_reg_rx_fifo_read = 0;
                        tx_fifo_write = 0;
                    end
                    
                    QSPISTATUS_ADDR: begin
                        case (t_hsize)
                            3'b000: hrdata[7:0] = QSPISTATUS[7:0];
                            3'b001: hrdata[15:0] = QSPISTATUS[15:0];
                            3'b010: hrdata[31:0] = QSPISTATUS;
                            default: hrdata = 32'b0;
                        endcase
                        if (hsel) begin
                            next_state = ADDR;
                            t_hwrite = hwrite;
                            t_hsize = hsize; // C?p nh?t t_hsize n?u hsel
                        end else next_state = IDLE;
                        hready = 1;
                        cfg_reg_rx_fifo_read = 0;
                        tx_fifo_write = 0;
                    end
                    
                    QSPIRDATA_ADDR: begin
                        if (~rx_fifo_empty) begin
                            cfg_reg_rx_fifo_read = 1;
                            tx_fifo_write = 0;
                            next_state = RX_FIFO_READ;
                            hready = 0;
                        end else begin
                            cfg_reg_rx_fifo_read = 0;
                            tx_fifo_write = 0;
                            next_state = RDATA;
                            hready = 0;
                        end
                    end
                endcase    
            end
            RX_FIFO_READ: begin
               cfg_reg_rx_fifo_read = 0;
               tx_fifo_write = 0;
               hready = 1;
               QSPIRDATA = rx_fifo_read_data;
               case (t_hsize)
                    3'b000: hrdata[7:0] = QSPIRDATA[7:0];
                    3'b001: hrdata[15:0] = QSPIRDATA[15:0];
                    3'b010: hrdata[31:0] = QSPIRDATA;
                    default: hrdata = 32'b0;
               endcase
               if(hsel) begin
                 next_state = ADDR;
                 t_hwrite = hwrite;
                 t_hsize = hsize;
               end else next_state = IDLE;
            end
        endcase
    end

    //config0
    assign qspi_mode = QSPICONFIG0[30];
    assign qspi_prescaler = QSPICONFIG0[29:28];
    assign qspi_sioo = QSPICONFIG0[27];
    assign qspi_cs_ht = QSPICONFIG0[26:24];
    assign qspi_data_length = QSPICONFIG0[23:15];
    assign qspi_dummy_length = QSPICONFIG0[14:10];
    assign qspi_cfg_length = QSPICONFIG0[9:6];
    assign qspi_addr_length = QSPICONFIG0[5:3];
    assign qspi_cmd_length = QSPICONFIG0[2];
    assign qspi_wr = QSPICONFIG0[1];
    assign qspi_en = QSPICONFIG0[0];
    
    //config1
    assign qspi_sclk_mode = QSPICONFIG1[5];
    assign qspi_data_ddr = QSPICONFIG1[4];
    assign qspi_addr_ddr = QSPICONFIG1[3];
    assign qspi_dummy_hiz = QSPICONFIG1[2];
    assign qspi_out2 = QSPICONFIG1[1];
    assign qspi_out3 = QSPICONFIG1[0];
    
    //mode
    assign qspi_tx_fwl = QSPIMODE[15:11];
    assign qspi_rx_fwl = QSPIMODE[10:6];
    assign qspi_data_mode = QSPIMODE[5:4];
    assign qspi_addr_mode = QSPIMODE[3:2];
    assign qspi_cmd_mode = QSPIMODE[1:0];
    
    //intstr0
    assign qspi_addr = QSPIINTSTR0;
    
    //intstr1
    assign qspi_cmd = QSPIINTSTR1[15:8];
    assign qspi_cfg = QSPIINTSTR1[7:0];
    
    //wdata
    assign  tx_fifo_write_data = QSPIWDATA;  
    assign  qspi_basic_mode_req =  QSPICONFIG0[31];  
endmodule
