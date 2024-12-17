`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2024 09:37:03 PM
// Design Name: 
// Module Name: qspi_master_tb
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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2024 09:37:03 PM
// Design Name: 
// Module Name: qspi_master_tb
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


module qspi_master_tb();
    
    // Clock and reset
    reg sys_clk;
    reg a_res_n;

    // PPI AHB slave
    reg [31:0] ppi_haddr;
    reg [2:0] ppi_hsize;
    reg ppi_hsel;
    reg ppi_hwrite;
    reg [31:0] ppi_hwdata;
    wire ppi_hready;
    wire [31:0] ppi_hrdata;

    // PCI AHB slave
    reg [31:0] pci_haddr;
    reg [2:0] pci_hsize;
    reg pci_hsel;
    reg pci_hwrite;
    reg [31:0] pci_hwdata;
    wire pci_hready;
    wire [31:0] pci_hrdata;

    // QSPI master interface
    wire qspi_sclk;
    wire cs_n;
    wire [3:0] qio_out;
    reg [3:0] qio_in;
    wire [3:0] qspi_oe;

    // Protocol signals
    wire qspi_clk;
    wire [3:0] current_state;
    wire [2:0] bit_counter;
    wire [1:0] byte_counter;
    wire [8:0] data_byte_counter;
    wire bit_counter_done;
    wire byte_counter_done;
    wire data_byte_counter_done;
    wire [1:0] phase_mode;
    wire qspi_busy;
    wire qspi_done;
    wire ddr_en;
    wire memory_mapped_mode_req;
    wire qspi_basic_mode_req;
    wire rx_fifo_empty;
        // Instantiate the UUT
    qspi_master uut (
        .sys_clk(sys_clk),
        .a_res_n(a_res_n),
        .ppi_haddr(ppi_haddr),
        .ppi_hsize(ppi_hsize),
        .ppi_hsel(ppi_hsel),
        .ppi_hwrite(ppi_hwrite),
        .ppi_hwdata(ppi_hwdata),
        .ppi_hready(ppi_hready),
        .ppi_hrdata(ppi_hrdata),
        .pci_haddr(pci_haddr),
        .pci_hsize(pci_hsize),
        .pci_hsel(pci_hsel),
        .pci_hwrite(pci_hwrite),
        .pci_hwdata(pci_hwdata),
        .pci_hready(pci_hready),
        .pci_hrdata(pci_hrdata),
        .qspi_sclk(qspi_sclk),
        .cs_n(cs_n),
        .qio_out(qio_out),
        .qio_in(qio_in),
        .qspi_oe(qspi_oe),
        .qspi_clk(qspi_clk),
        .current_state(current_state),
        .bit_counter(bit_counter),
        .byte_counter(byte_counter),
        .data_byte_counter(data_byte_counter),
        .bit_counter_done(bit_counter_done),
        .byte_counter_done(byte_counter_done),
        .data_byte_counter_done(data_byte_counter_done),
        .phase_mode(phase_mode),
        .qspi_busy(qspi_busy),
        .qspi_done(qspi_done),
        .ddr_en(ddr_en),
        .memory_mapped_mode_req(memory_mapped_mode_req),
        .qspi_basic_mode_req(qspi_basic_mode_req),
        .rx_fifo_empty(rx_fifo_empty)
    );
    
    
    task qio_in_sspi();
        reg  random_data;
        begin
            while (1) begin 
                @(negedge sys_clk); 
                if (current_state == 4'h7) begin
                    random_data = $urandom_range(0, 1); 
                    qio_in = {2'b0,random_data,1'b0}; 
                end
            end
        end
    endtask
    
    task qio_in_dspi();
        reg  [1:0]random_data;
        begin
            while (1) begin // L?p vô h?n
                @(negedge sys_clk); // Ch? c?nh lên c?a sys_clk
                if (current_state == 4'h7) begin
                    random_data = $urandom_range(0, 3); // Sinh d? li?u ng?u nhiên 4-bit
                    qio_in = {2'b0,random_data}; // Gán d? li?u vào qio_in
                end
                
                    
            end
        end
    endtask
    
    task qio_in_qspi();
        reg  [3:0]random_data;
        begin
            while (1) begin
                random_data = $urandom_range(0, 15);
                @(negedge sys_clk); 
                if (current_state == 4'h7) begin 
                    qio_in = random_data; 
                end
                
            end
        end
    endtask
    
    task qio_in_ddr_sspi();
        reg  [3:0]random_data;
        begin
            while (1) begin
                @(negedge sys_clk); 
                if (current_state == 4'h7) begin
                    random_data = $urandom_range(0, 1); 
                    qio_in = {2'b0,random_data,1'b0};
                end
                @(posedge sys_clk); 
                if (current_state == 4'h7) begin
                    random_data = $urandom_range(0, 1); 
                    qio_in = {2'b0,random_data,1'b0}; 
                end
            end
        end
    endtask
    
    task qio_in_ddr_dspi();
        reg  [3:0]random_data;
        begin
            while (1) begin
                @(negedge sys_clk); 
                if (current_state == 4'h7) begin
                    random_data = $urandom_range(0, 3); // Sinh d? li?u ng?u nhiên 4-bit
                    qio_in = {2'b0,random_data};
                end
                @(posedge sys_clk); 
                if (current_state == 4'h7) begin
                    random_data = $urandom_range(0, 3); // Sinh d? li?u ng?u nhiên 4-bit
                    qio_in = {2'b0,random_data};
                end
            end
        end
    endtask
    
    
    task qio_in_ddr_qspi();
        reg  [3:0]random_data;
        begin
            while (1) begin
                @(negedge sys_clk); 
                if (current_state == 4'h7) begin
                    random_data = $urandom_range(0, 15); 
                    qio_in = random_data; 
                end
                @(posedge sys_clk);
    
                if (current_state == 4'h7) begin
                    random_data = $urandom_range(0, 15); 
                    qio_in = random_data; 
                end
            end
        end
    endtask
    
    // Clock generation
    always #5 sys_clk = ~sys_clk; // 100MHz clock

    // Testbench logic
    initial begin
        // Initialize inputs
        sys_clk = 1;
        a_res_n = 1;
        //ppi_input
        ppi_haddr = 0;
        ppi_hsize = 0;
        ppi_hsel = 0;
        ppi_hwrite = 0;
        ppi_hwdata = 0;
          
        pci_haddr = 0;
        pci_hsize = 0;
        pci_hsel = 0;
        pci_hwrite = 0;
        pci_hwdata = 0;
        qio_in = 0;
        // Reset the system
        #20 a_res_n = 0;
        #20 a_res_n = 1;
        #10;   
        // Config
        ppi_hsize = 3'b010;
        ppi_hsel = 1;
        ppi_hwrite = 1;
        ppi_haddr = 32'h00000010;
        #10;
        ppi_hwdata = 32'h00002F93;//CMD_CFG
        #10;
        ppi_haddr = 32'h0000000C;
        #10;
        ppi_hwdata = 32'h10F32579;//ADDR
        #10;
        ppi_haddr = 32'h00000008;
        #10;
        ppi_hwdata = 32'h0000222A;//MODE
        #10;
        ppi_haddr = 32'h00000004;
        #10;
        ppi_hwdata = 32'h0000_0000;//CF1
        #10;
        ppi_haddr = 32'h00000000;
        #10;
        ppi_hwdata = 32'h04042225;//CF0
        #10;
        ppi_hsel = 0;
        ppi_hwrite = 0;
        qio_in_qspi();

        // End simulation
        #2000 $finish;
    end
    
    initial begin
        #560;
        ppi_hsel = 1;
        ppi_haddr = 32'h0000_0018;
        ppi_hwrite = 0;
        #10;
        ppi_hsel = 0;
        ppi_hwrite = 0;
        #20;
        ppi_hsel = 1;
        ppi_hwrite = 0;
        #10;
        ppi_hsel = 0;
        ppi_hwrite = 0;
    end
    
endmodule

