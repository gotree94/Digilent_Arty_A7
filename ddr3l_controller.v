// ============================================================================
// DDR3L Memory Controller for Digilent Arty A7
// Target: MT41K128M16JT-125 (2Gb DDR3L)
// ============================================================================

// Top-level DDR3L Controller
module ddr3l_controller (
    // Clock and Reset
    input wire clk_200mhz,          // 200MHz reference clock
    input wire clk_100mhz,          // 100MHz system clock  
    input wire rst_n,
    
    // User Interface
    input wire [26:0] user_addr,    // 27-bit address (128MB)
    input wire [127:0] user_wdata,  // 128-bit write data
    output reg [127:0] user_rdata,  // 128-bit read data
    input wire user_rd_req,         // Read request
    input wire user_wr_req,         // Write request
    input wire [15:0] user_mask,    // Byte mask for writes
    output reg user_rd_valid,       // Read data valid
    output reg user_ready,          // Controller ready
    
    // DDR3L Physical Interface
    output wire ddr3_ck_p,          // Differential clock
    output wire ddr3_ck_n,
    output wire ddr3_cke,           // Clock enable
    output wire ddr3_cs_n,          // Chip select
    output wire ddr3_ras_n,         // Row address strobe
    output wire ddr3_cas_n,         // Column address strobe
    output wire ddr3_we_n,          // Write enable
    output wire [2:0] ddr3_ba,      // Bank address
    output wire [13:0] ddr3_addr,   // Address
    inout wire [15:0] ddr3_dq,      // Data
    inout wire [1:0] ddr3_dqs_p,    // Data strobe positive
    inout wire [1:0] ddr3_dqs_n,    // Data strobe negative
    output wire [1:0] ddr3_dm,      // Data mask
    output wire ddr3_odt,           // On-die termination
    output wire ddr3_reset_n        // Reset
);

// ============================================================================
// Parameters and Local Signals
// ============================================================================

// DDR3L Timing Parameters (for -125 speed grade)
parameter tCK = 2500;           // Clock period (2.5ns for 400MHz)
parameter tCL = 6;              // CAS latency
parameter tRCD = 6;             // RAS to CAS delay
parameter tRP = 6;              // Row precharge time
parameter tRAS_MIN = 15;        // Minimum row active time
parameter tRC = 21;             // Row cycle time
parameter tRFC = 104;           // Refresh cycle time
parameter tWR = 6;              // Write recovery time
parameter tWTR = 4;             // Write to read delay
parameter tRTP = 4;             // Read to precharge delay

// State Machine States
parameter IDLE = 4'h0;
parameter INIT = 4'h1;
parameter ACTIVE = 4'h2;
parameter READ = 4'h3;
parameter WRITE = 4'h4;
parameter PRECHARGE = 4'h5;
parameter REFRESH = 4'h6;

// Internal signals
reg [3:0] state, next_state;
reg [7:0] init_counter;
reg init_done;
reg [15:0] refresh_counter;
reg refresh_req;

// Command signals
reg [2:0] cmd;
reg [13:0] addr;
reg [2:0] bank_addr;
reg [15:0] wdata_reg [0:7];
reg [15:0] rdata_reg [0:7];

// Address mapping
wire [13:0] row_addr;
wire [9:0] col_addr;
wire [2:0] bank;
assign {bank, row_addr, col_addr} = user_addr;

// ============================================================================
// Initialization Sequence Controller
// ============================================================================

ddr3_init_controller u_init (
    .clk(clk_100mhz),
    .reset(~rst_n),
    .init_done(init_done),
    .cmd(cmd),
    .addr(addr),
    .ba(bank_addr),
    .init_counter(init_counter)
);

// ============================================================================
// Main State Machine
// ============================================================================

always @(posedge clk_100mhz or negedge rst_n) begin
    if (!rst_n) begin
        state <= INIT;
        user_ready <= 1'b0;
        user_rd_valid <= 1'b0;
        refresh_counter <= 16'h0;
        refresh_req <= 1'b0;
    end else begin
        state <= next_state;
        
        // Refresh counter (7.8us refresh interval)
        if (refresh_counter == 16'd780) begin
            refresh_counter <= 16'h0;
            refresh_req <= 1'b1;
        end else begin
            refresh_counter <= refresh_counter + 1'b1;
            if (state == REFRESH)
                refresh_req <= 1'b0;
        end
    end
end

always @(*) begin
    next_state = state;
    
    case (state)
        INIT: begin
            user_ready = 1'b0;
            if (init_done)
                next_state = IDLE;
        end
        
        IDLE: begin
            user_ready = 1'b1;
            if (refresh_req)
                next_state = REFRESH;
            else if (user_rd_req || user_wr_req)
                next_state = ACTIVE;
        end
        
        ACTIVE: begin
            user_ready = 1'b0;
            if (user_rd_req)
                next_state = READ;
            else if (user_wr_req)
                next_state = WRITE;
        end
        
        READ: begin
            next_state = PRECHARGE;
        end
        
        WRITE: begin
            next_state = PRECHARGE;
        end
        
        PRECHARGE: begin
            next_state = IDLE;
        end
        
        REFRESH: begin
            next_state = IDLE;
        end
    endcase
end

// ============================================================================
// DDR3L Physical Interface
// ============================================================================

// Clock generation
wire clk_ddr;
ODDR #(
    .DDR_CLK_EDGE("OPPOSITE_EDGE"),
    .INIT(1'b0),
    .SRTYPE("SYNC")
) u_clk_ddr (
    .Q(ddr3_ck_p),
    .C(clk_200mhz),
    .CE(1'b1),
    .D1(1'b1),
    .D2(1'b0),
    .R(1'b0),
    .S(1'b0)
);

assign ddr3_ck_n = ~ddr3_ck_p;

// Command signals
assign ddr3_cke = init_done;
assign ddr3_cs_n = 1'b0;
assign ddr3_odt = (state == WRITE) ? 1'b1 : 1'b0;
assign ddr3_reset_n = rst_n;

// Command encoding
assign {ddr3_ras_n, ddr3_cas_n, ddr3_we_n} = cmd;
assign ddr3_ba = bank_addr;
assign ddr3_addr = addr;

// Data strobe generation for writes
wire dqs_oe = (state == WRITE);
wire [1:0] dqs_out;

genvar i;
generate
    for (i = 0; i < 2; i = i + 1) begin : gen_dqs
        OBUFTDS u_dqs_buf (
            .I(dqs_out[i]),
            .T(~dqs_oe),
            .O(ddr3_dqs_p[i]),
            .OB(ddr3_dqs_n[i])
        );
    end
endgenerate

endmodule

// ============================================================================
// DDR3 Initialization Controller
// ============================================================================

module ddr3_init_controller (
    input wire clk,
    input wire reset,
    output reg init_done,
    output reg [2:0] cmd,
    output reg [13:0] addr,
    output reg [2:0] ba,
    output reg [7:0] init_counter
);

// Command encodings
parameter NOP = 3'b111;
parameter MRS = 3'b000;
parameter REF = 3'b001;
parameter PRE = 3'b010;

// Initialization states
parameter INIT_IDLE = 4'h0;
parameter INIT_WAIT_200US = 4'h1;
parameter INIT_PRECHARGE = 4'h2;
parameter INIT_REFRESH1 = 4'h3;
parameter INIT_REFRESH2 = 4'h4;
parameter INIT_MRS2 = 4'h5;
parameter INIT_MRS3 = 4'h6;
parameter INIT_MRS1 = 4'h7;
parameter INIT_MRS0 = 4'h8;
parameter INIT_DONE = 4'h9;

reg [3:0] init_state;
reg [15:0] wait_counter;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        init_state <= INIT_IDLE;
        init_done <= 1'b0;
        cmd <= NOP;
        addr <= 14'h0;
        ba <= 3'h0;
        wait_counter <= 16'h0;
        init_counter <= 8'h0;
    end else begin
        case (init_state)
            INIT_IDLE: begin
                init_state <= INIT_WAIT_200US;
                wait_counter <= 16'd20000; // 200us at 100MHz
            end
            
            INIT_WAIT_200US: begin
                if (wait_counter > 0) begin
                    wait_counter <= wait_counter - 1'b1;
                end else begin
                    init_state <= INIT_PRECHARGE;
                    cmd <= PRE;
                    addr <= 14'h0400; // Precharge all banks (A10=1)
                    wait_counter <= 16'd10;
                end
            end
            
            INIT_PRECHARGE: begin
                if (wait_counter > 0) begin
                    wait_counter <= wait_counter - 1'b1;
                    cmd <= NOP;
                end else begin
                    init_state <= INIT_REFRESH1;
                    cmd <= REF;
                    wait_counter <= 16'd104; // tRFC
                end
            end
            
            INIT_REFRESH1: begin
                if (wait_counter > 0) begin
                    wait_counter <= wait_counter - 1'b1;
                    cmd <= NOP;
                end else begin
                    init_state <= INIT_REFRESH2;
                    cmd <= REF;
                    wait_counter <= 16'd104;
                end
            end
            
            INIT_REFRESH2: begin
                if (wait_counter > 0) begin
                    wait_counter <= wait_counter - 1'b1;
                    cmd <= NOP;
                end else begin
                    init_state <= INIT_MRS2;
                    cmd <= MRS;
                    ba <= 3'h2;
                    addr <= 14'h0; // MR2: Normal operation
                    wait_counter <= 16'd4;
                end
            end
            
            INIT_MRS2: begin
                if (wait_counter > 0) begin
                    wait_counter <= wait_counter - 1'b1;
                    cmd <= NOP;
                end else begin
                    init_state <= INIT_MRS3;
                    cmd <= MRS;
                    ba <= 3'h3;
                    addr <= 14'h0; // MR3: Normal operation
                    wait_counter <= 16'd4;
                end
            end
            
            INIT_MRS3: begin
                if (wait_counter > 0) begin
                    wait_counter <= wait_counter - 1'b1;
                    cmd <= NOP;
                end else begin
                    init_state <= INIT_MRS1;
                    cmd <= MRS;
                    ba <= 3'h1;
                    addr <= 14'h0004; // MR1: OD=RZQ/6, RTT_Nom=RZQ/4
                    wait_counter <= 16'd4;
                end
            end
            
            INIT_MRS1: begin
                if (wait_counter > 0) begin
                    wait_counter <= wait_counter - 1'b1;
                    cmd <= NOP;
                end else begin
                    init_state <= INIT_MRS0;
                    cmd <= MRS;
                    ba <= 3'h0;
                    addr <= 14'h0A30; // MR0: BL=8, CL=6, WR=6
                    wait_counter <= 16'd4;
                end
            end
            
            INIT_MRS0: begin
                if (wait_counter > 0) begin
                    wait_counter <= wait_counter - 1'b1;
                    cmd <= NOP;
                end else begin
                    init_state <= INIT_DONE;
                    cmd <= NOP;
                    init_done <= 1'b1;
                end
            end
            
            INIT_DONE: begin
                cmd <= NOP;
            end
        endcase
        
        init_counter <= init_counter + 1'b1;
    end
end

endmodule

// ============================================================================
// Command Scheduler with Bank Management
// ============================================================================

module ddr3_cmd_scheduler (
    input wire clk,
    input wire rst_n,
    
    // User requests
    input wire [26:0] user_addr,
    input wire user_rd_req,
    input wire user_wr_req,
    output reg user_ready,
    
    // Memory controller interface
    output reg [2:0] cmd,
    output reg [13:0] addr,
    output reg [2:0] ba,
    output reg cmd_valid,
    input wire cmd_ready,
    
    // Bank status
    output reg [7:0] bank_active,
    output reg [13:0] active_rows [0:7]
);

// Commands
parameter CMD_NOP = 3'b111;
parameter CMD_ACT = 3'b011;
parameter CMD_RD = 3'b101;
parameter CMD_WR = 3'b100;
parameter CMD_PRE = 3'b010;

// Internal signals
wire [2:0] req_bank;
wire [13:0] req_row;
wire [9:0] req_col;
assign {req_bank, req_row, req_col} = user_addr;

reg [3:0] timing_counters [0:7]; // Per-bank timing counters
reg [2:0] current_cmd;

integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bank_active <= 8'h0;
        cmd <= CMD_NOP;
        cmd_valid <= 1'b0;
        user_ready <= 1'b0;
        
        for (i = 0; i < 8; i = i + 1) begin
            active_rows[i] <= 14'h0;
            timing_counters[i] <= 4'h0;
        end
    end else begin
        // Decrement timing counters
        for (i = 0; i < 8; i = i + 1) begin
            if (timing_counters[i] > 0)
                timing_counters[i] <= timing_counters[i] - 1'b1;
        end
        
        // Command scheduling logic
        if (cmd_ready && (user_rd_req || user_wr_req)) begin
            if (bank_active[req_bank] && (active_rows[req_bank] == req_row)) begin
                // Same row is active, issue read/write directly
                cmd <= user_rd_req ? CMD_RD : CMD_WR;
                ba <= req_bank;
                addr <= {4'b0, req_col};
                cmd_valid <= 1'b1;
                user_ready <= 1'b1;
            end else begin
                // Need to activate row first
                if (bank_active[req_bank]) begin
                    // Precharge first
                    cmd <= CMD_PRE;
                    ba <= req_bank;
                    addr <= 14'h0;
                    bank_active[req_bank] <= 1'b0;
                    timing_counters[req_bank] <= 4'd3; // tRP
                end else if (timing_counters[req_bank] == 0) begin
                    // Activate new row
                    cmd <= CMD_ACT;
                    ba <= req_bank;
                    addr <= req_row;
                    bank_active[req_bank] <= 1'b1;
                    active_rows[req_bank] <= req_row;
                    timing_counters[req_bank] <= 4'd3; // tRCD
                end
                cmd_valid <= 1'b1;
                user_ready <= 1'b0;
            end
        end else begin
            cmd <= CMD_NOP;
            cmd_valid <= 1'b0;
            user_ready <= 1'b1;
        end
    end
end

endmodule
