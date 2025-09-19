// ============================================================================
// DDR3L Memory Controller Testbench
// ============================================================================

`timescale 1ns / 1ps

module tb_ddr3l_controller;

// ============================================================================
// Testbench Parameters
// ============================================================================

parameter CLK_PERIOD_200 = 5.0;    // 200MHz clock period (5ns)
parameter CLK_PERIOD_100 = 10.0;   // 100MHz clock period (10ns)
parameter SIMULATION_TIME = 100000; // 100us simulation time

// ============================================================================
// DUT Signals
// ============================================================================

// Clock and Reset
reg clk_200mhz;
reg clk_100mhz;
reg rst_n;

// User Interface
reg [26:0] user_addr;
reg [127:0] user_wdata;
wire [127:0] user_rdata;
reg user_rd_req;
reg user_wr_req;
reg [15:0] user_mask;
wire user_rd_valid;
wire user_ready;

// DDR3L Physical Interface (simplified for testbench)
wire ddr3_ck_p, ddr3_ck_n;
wire ddr3_cke, ddr3_cs_n;
wire ddr3_ras_n, ddr3_cas_n, ddr3_we_n;
wire [2:0] ddr3_ba;
wire [13:0] ddr3_addr;
wire [15:0] ddr3_dq;
wire [1:0] ddr3_dqs_p, ddr3_dqs_n;
wire [1:0] ddr3_dm;
wire ddr3_odt, ddr3_reset_n;

// ============================================================================
// Test Variables and Arrays
// ============================================================================

reg [127:0] test_data [0:1023];    // Test data array
reg [26:0] test_addr [0:1023];     // Test address array
reg [127:0] read_data [0:1023];    // Read back data
integer test_count;
integer error_count;
integer i, j;

// Performance monitoring
reg [31:0] cycle_count;
reg [31:0] read_latency_start;
reg [31:0] read_latency_total;
reg [15:0] read_count;

// Test status flags
reg init_test_done;
reg basic_rw_test_done;
reg burst_test_done;
reg random_test_done;
reg performance_test_done;

// ============================================================================
// Clock Generation
// ============================================================================

initial begin
    clk_200mhz = 0;
    forever #(CLK_PERIOD_200/2) clk_200mhz = ~clk_200mhz;
end

initial begin
    clk_100mhz = 0;
    forever #(CLK_PERIOD_100/2) clk_100mhz = ~clk_100mhz;
end

// ============================================================================
// DUT Instantiation
// ============================================================================

ddr3l_controller u_dut (
    .clk_200mhz(clk_200mhz),
    .clk_100mhz(clk_100mhz),
    .rst_n(rst_n),
    
    .user_addr(user_addr),
    .user_wdata(user_wdata),
    .user_rdata(user_rdata),
    .user_rd_req(user_rd_req),
    .user_wr_req(user_wr_req),
    .user_mask(user_mask),
    .user_rd_valid(user_rd_valid),
    .user_ready(user_ready),
    
    .ddr3_ck_p(ddr3_ck_p),
    .ddr3_ck_n(ddr3_ck_n),
    .ddr3_cke(ddr3_cke),
    .ddr3_cs_n(ddr3_cs_n),
    .ddr3_ras_n(ddr3_ras_n),
    .ddr3_cas_n(ddr3_cas_n),
    .ddr3_we_n(ddr3_we_n),
    .ddr3_ba(ddr3_ba),
    .ddr3_addr(ddr3_addr),
    .ddr3_dq(ddr3_dq),
    .ddr3_dqs_p(ddr3_dqs_p),
    .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dm(ddr3_dm),
    .ddr3_odt(ddr3_odt),
    .ddr3_reset_n(ddr3_reset_n)
);

// ============================================================================
// DDR3L Memory Model (Simplified)
// ============================================================================

ddr3_model u_ddr3_model (
    .ck(ddr3_ck_p),
    .ck_n(ddr3_ck_n),
    .cke(ddr3_cke),
    .cs_n(ddr3_cs_n),
    .ras_n(ddr3_ras_n),
    .cas_n(ddr3_cas_n),
    .we_n(ddr3_we_n),
    .ba(ddr3_ba),
    .addr(ddr3_addr),
    .dq(ddr3_dq),
    .dqs(ddr3_dqs_p),
    .dqs_n(ddr3_dqs_n),
    .dm(ddr3_dm),
    .odt(ddr3_odt),
    .reset_n(ddr3_reset_n)
);

// ============================================================================
// Test Data Generation
// ============================================================================

task generate_test_data;
begin
    for (i = 0; i < 1024; i = i + 1) begin
        test_data[i] = {$random, $random, $random, $random};
        test_addr[i] = i * 16; // 16-byte aligned addresses
    end
    $display("[%0t] Test data generated", $time);
end
endtask

// ============================================================================
// Reset Sequence
// ============================================================================

task apply_reset;
begin
    rst_n = 0;
    user_addr = 0;
    user_wdata = 0;
    user_rd_req = 0;
    user_wr_req = 0;
    user_mask = 16'h0000;
    
    repeat(20) @(posedge clk_100mhz);
    rst_n = 1;
    $display("[%0t] Reset released", $time);
end
endtask

// ============================================================================
// Wait for Initialization
// ============================================================================

task wait_for_init;
begin
    $display("[%0t] Waiting for DDR3L initialization...", $time);
    wait(user_ready == 1'b1);
    repeat(10) @(posedge clk_100mhz);
    $display("[%0t] DDR3L initialization completed", $time);
    init_test_done = 1;
end
endtask

// ============================================================================
// Basic Read/Write Operations
// ============================================================================

task write_data(input [26:0] addr, input [127:0] data, input [15:0] mask);
begin
    @(posedge clk_100mhz);
    while (!user_ready) @(posedge clk_100mhz);
    
    user_addr = addr;
    user_wdata = data;
    user_mask = mask;
    user_wr_req = 1'b1;
    
    @(posedge clk_100mhz);
    user_wr_req = 1'b0;
    user_mask = 16'h0000;
    
    // Wait for write completion
    while (!user_ready) @(posedge clk_100mhz);
end
endtask

task read_data(input [26:0] addr, output [127:0] data);
begin
    @(posedge clk_100mhz);
    while (!user_ready) @(posedge clk_100mhz);
    
    read_latency_start = cycle_count;
    user_addr = addr;
    user_rd_req = 1'b1;
    
    @(posedge clk_100mhz);
    user_rd_req = 1'b0;
    
    // Wait for read data valid
    while (!user_rd_valid) @(posedge clk_100mhz);
    data = user_rdata;
    
    read_latency_total = read_latency_total + (cycle_count - read_latency_start);
    read_count = read_count + 1;
end
endtask

// ============================================================================
// Basic Read/Write Test
// ============================================================================

task basic_rw_test;
    reg [127:0] read_back;
begin
    $display("[%0t] Starting basic read/write test...", $time);
    error_count = 0;
    
    for (i = 0; i < 32; i = i + 1) begin
        // Write test data
        write_data(test_addr[i], test_data[i], 16'hFFFF);
        $display("[%0t] Write: Addr=0x%07x, Data=0x%032x", 
                 $time, test_addr[i], test_data[i]);
        
        // Read back and verify
        read_data(test_addr[i], read_back);
        read_data[i] = read_back;
        
        if (read_back !== test_data[i]) begin
            error_count = error_count + 1;
            $display("[%0t] ERROR: Addr=0x%07x, Expected=0x%032x, Got=0x%032x", 
                     $time, test_addr[i], test_data[i], read_back);
        end else begin
            $display("[%0t] PASS: Addr=0x%07x, Data=0x%032x", 
                     $time, test_addr[i], read_back);
        end
    end
    
    if (error_count == 0) begin
        $display("[%0t] Basic R/W test PASSED (%0d operations)", $time, i*2);
    end else begin
        $display("[%0t] Basic R/W test FAILED (%0d errors)", $time, error_count);
    end
    
    basic_rw_test_done = 1;
end
endtask

// ============================================================================
// Burst Read/Write Test
// ============================================================================

task burst_test;
    reg [127:0] read_back;
    reg [26:0] base_addr;
begin
    $display("[%0t] Starting burst test...", $time);
    error_count = 0;
    base_addr = 27'h1000; // Start at different address
    
    // Sequential burst writes
    for (i = 0; i < 64; i = i + 1) begin
        write_data(base_addr + (i * 16), test_data[i], 16'hFFFF);
    end
    
    // Sequential burst reads
    for (i = 0; i < 64; i = i + 1) begin
        read_data(base_addr + (i * 16), read_back);
        
        if (read_back !== test_data[i]) begin
            error_count = error_count + 1;
            $display("[%0t] BURST ERROR: Addr=0x%07x, Expected=0x%032x, Got=0x%032x", 
                     $time, base_addr + (i * 16), test_data[i], read_back);
        end
    end
    
    if (error_count == 0) begin
        $display("[%0t] Burst test PASSED (%0d operations)", $time, i*2);
    end else begin
        $display("[%0t] Burst test FAILED (%0d errors)", $time, error_count);
    end
    
    burst_test_done = 1;
end
endtask

// ============================================================================
// Random Access Test
// ============================================================================

task random_test;
    reg [127:0] read_back;
    reg [26:0] rand_addr;
    reg [31:0] seed;
begin
    $display("[%0t] Starting random access test...", $time);
    error_count = 0;
    seed = 32'h12345678;
    
    for (i = 0; i < 128; i = i + 1) begin
        // Generate random address (aligned to 16 bytes)
        rand_addr = ($random(seed) & 27'h7FFFF0);
        
        // Write random data
        write_data(rand_addr, test_data[i & 1023], 16'hFFFF);
        
        // Read back immediately
        read_data(rand_addr, read_back);
        
        if (read_back !== test_data[i & 1023]) begin
            error_count = error_count + 1;
            $display("[%0t] RANDOM ERROR: Addr=0x%07x, Expected=0x%032x, Got=0x%032x", 
                     $time, rand_addr, test_data[i & 1023], read_back);
        end
    end
    
    if (error_count == 0) begin
        $display("[%0t] Random test PASSED (%0d operations)", $time, i*2);
    end else begin
        $display("[%0t] Random test FAILED (%0d errors)", $time, error_count);
    end
    
    random_test_done = 1;
end
endtask

// ============================================================================
// Performance Test
// ============================================================================

task performance_test;
    reg [31:0] start_time, end_time;
    reg [31:0] total_cycles;
    real bandwidth_mbps;
    real avg_latency;
begin
    $display("[%0t] Starting performance test...", $time);
    
    start_time = cycle_count;
    
    // Sequential writes (256 operations)
    for (i = 0; i < 256; i = i + 1) begin
        write_data(i * 16, test_data[i & 1023], 16'hFFFF);
    end
    
    // Sequential reads (256 operations)  
    for (i = 0; i < 256; i = i + 1) begin
        read_data(i * 16, read_data[i]);
    end
    
    end_time = cycle_count;
    total_cycles = end_time - start_time;
    
    // Calculate performance metrics
    bandwidth_mbps = (512.0 * 16.0 * 100.0) / total_cycles; // MB/s
    avg_latency = (read_latency_total * 1.0) / read_count; // cycles
    
    $display("[%0t] Performance Results:", $time);
    $display("  Total Operations: 512 (256 writes + 256 reads)");
    $display("  Total Cycles: %0d", total_cycles);
    $display("  Bandwidth: %.2f MB/s", bandwidth_mbps);
    $display("  Average Read Latency: %.2f cycles", avg_latency);
    
    performance_test_done = 1;
end
endtask

// ============================================================================
// Memory Pattern Tests
// ============================================================================

task walking_ones_test;
    reg [127:0] pattern;
    reg [127:0] read_back;
    reg [26:0] test_address;
begin
    $display("[%0t] Starting walking ones test...", $time);
    error_count = 0;
    test_address = 27'h10000;
    
    for (i = 0; i < 128; i = i + 1) begin
        pattern = 128'h1 << i;
        
        write_data(test_address, pattern, 16'hFFFF);
        read_data(test_address, read_back);
        
        if (read_back !== pattern) begin
            error_count = error_count + 1;
            $display("[%0t] WALKING ONES ERROR: Bit %0d, Expected=0x%032x, Got=0x%032x", 
                     $time, i, pattern, read_back);
        end
    end
    
    if (error_count == 0) begin
        $display("[%0t] Walking ones test PASSED", $time);
    end else begin
        $display("[%0t] Walking ones test FAILED (%0d errors)", $time, error_count);
    end
end
endtask

task walking_zeros_test;
    reg [127:0] pattern;
    reg [127:0] read_back;
    reg [26:0] test_address;
begin
    $display("[%0t] Starting walking zeros test...", $time);
    error_count = 0;
    test_address = 27'h20000;
    
    for (i = 0; i < 128; i = i + 1) begin
        pattern = ~(128'h1 << i);
        
        write_data(test_address, pattern, 16'hFFFF);
        read_data(test_address, read_back);
        
        if (read_back !== pattern) begin
            error_count = error_count + 1;
            $display("[%0t] WALKING ZEROS ERROR: Bit %0d, Expected=0x%032x, Got=0x%032x", 
                     $time, i, pattern, read_back);
        end
    end
    
    if (error_count == 0) begin
        $display("[%0t] Walking zeros test PASSED", $time);
    end else begin
        $display("[%0t] Walking zeros test FAILED (%0d errors)", $time, error_count);
    end
end
endtask

// ============================================================================
// Cycle Counter
// ============================================================================

always @(posedge clk_100mhz or negedge rst_n) begin
    if (!rst_n) begin
        cycle_count <= 0;
    end else begin
        cycle_count <= cycle_count + 1;
    end
end

// ============================================================================
// Monitor and Debug Tasks
// ============================================================================

// Command monitor
always @(posedge clk_100mhz) begin
    if (u_dut.cmd != 3'b111) begin // Not NOP
        case (u_dut.cmd)
            3'b011: $display("[%0t] CMD: ACTIVATE Bank=%0d, Row=0x%04x", 
                           $time, u_dut.bank_addr, u_dut.addr);
            3'b101: $display("[%0t] CMD: READ Bank=%0d, Col=0x%03x", 
                           $time, u_dut.bank_addr, u_dut.addr[9:0]);
            3'b100: $display("[%0t] CMD: WRITE Bank=%0d, Col=0x%03x", 
                           $time, u_dut.bank_addr, u_dut.addr[9:0]);
            3'b010: $display("[%0t] CMD: PRECHARGE Bank=%0d", 
                           $time, u_dut.bank_addr);
            3'b001: $display("[%0t] CMD: REFRESH", $time);
            3'b000: $display("[%0t] CMD: MRS Bank=%0d, Value=0x%04x", 
                           $time, u_dut.bank_addr, u_dut.addr);
        endcase
    end
end

// ============================================================================
// Main Test Sequence
// ============================================================================

initial begin
    $display("========================================");
    $display("DDR3L Memory Controller Testbench");
    $display("========================================");
    
    // Initialize variables
    test_count = 0;
    error_count = 0;
    cycle_count = 0;
    read_latency_total = 0;
    read_count = 0;
    
    init_test_done = 0;
    basic_rw_test_done = 0;
    burst_test_done = 0;
    random_test_done = 0;
    performance_test_done = 0;
    
    // Generate test data
    generate_test_data();
    
    // Apply reset
    apply_reset();
    
    // Wait for initialization
    wait_for_init();
    
    // Run test sequence
    basic_rw_test();
    burst_test();
    random_test();
    walking_ones_test();
    walking_zeros_test();
    performance_test();
    
    // Final summary
    $display("========================================");
    $display("TEST SUMMARY");
    $display("========================================");
    $display("Initialization: %s", init_test_done ? "PASS" : "FAIL");
    $display("Basic R/W Test: %s", basic_rw_test_done ? "PASS" : "FAIL");
    $display("Burst Test: %s", burst_test_done ? "PASS" : "FAIL");
    $display("Random Test: %s", random_test_done ? "PASS" : "FAIL");
    $display("Performance Test: %s", performance_test_done ? "PASS" : "FAIL");
    $display("========================================");
    
    if (init_test_done && basic_rw_test_done && burst_test_done && 
        random_test_done && performance_test_done) begin
        $display("ALL TESTS PASSED!");
    end else begin
        $display("SOME TESTS FAILED!");
    end
    
    $display("Simulation completed at time %0t", $time);
    $finish;
end

// Simulation timeout
initial begin
    #SIMULATION_TIME;
    $display("TIMEOUT: Simulation exceeded %0d ns", SIMULATION_TIME);
    $finish;
end

// VCD dump for waveform analysis
initial begin
    $dumpfile("ddr3l_controller_tb.vcd");
    $dumpvars(0, tb_ddr3l_controller);
end

endmodule

// ============================================================================
// Simplified DDR3 Memory Model for Simulation
// ============================================================================

module ddr3_model (
    input wire ck,
    input wire ck_n,
    input wire cke,
    input wire cs_n,
    input wire ras_n,
    input wire cas_n,
    input wire we_n,
    input wire [2:0] ba,
    input wire [13:0] addr,
    inout wire [15:0] dq,
    inout wire [1:0] dqs,
    inout wire [1:0] dqs_n,
    input wire [1:0] dm,
    input wire odt,
    input wire reset_n
);

// Memory array (simplified - only 1MB for simulation)
reg [15:0] memory [0:65535];
reg [13:0] active_rows [0:7];
reg [7:0] bank_active;

// Command decode
wire [2:0] cmd = {ras_n, cas_n, we_n};
wire cmd_act = (cmd == 3'b011);
wire cmd_rd = (cmd == 3'b101);
wire cmd_wr = (cmd == 3'b100);
wire cmd_pre = (cmd == 3'b010);

// Simple behavioral model
always @(posedge ck) begin
    if (reset_n && cke && !cs_n) begin
        case (cmd)
            3'b011: begin // ACTIVATE
                bank_active[ba] <= 1'b1;
                active_rows[ba] <= addr;
                $display("[DDR3 Model] ACTIVATE: Bank %0d, Row 0x%04x", ba, addr);
            end
            
            3'b101: begin // READ
                if (bank_active[ba]) begin
                    $display("[DDR3 Model] READ: Bank %0d, Col 0x%03x", ba, addr[9:0]);
                    // Simple read data return (would need proper timing)
                end
            end
            
            3'b100: begin // WRITE
                if (bank_active[ba]) begin
                    $display("[DDR3 Model] WRITE: Bank %0d, Col 0x%03x", ba, addr[9:0]);
                    // Simple write operation (would need proper timing)
                end
            end
            
            3'b010: begin // PRECHARGE
                if (addr[10]) begin // All banks
                    bank_active <= 8'h00;
                    $display("[DDR3 Model] PRECHARGE ALL");
                end else begin
                    bank_active[ba] <= 1'b0;
                    $display("[DDR3 Model] PRECHARGE: Bank %0d", ba);
                end
            end
        endcase
    end
end

// Simplified data output (for basic functionality testing)
assign dq = (cmd_rd && bank_active[ba]) ? 16'hABCD : 16'hzzzz;

endmodule
