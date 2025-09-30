// -----------------------------------------------------------------------------
// debouncer.v -- Verilog-1995 compatible
// -----------------------------------------------------------------------------
module debouncer (SIGNAL_I, CLK_I, SIGNAL_O);

    parameter integer DEBNC_CLOCKS = 1 << 16;
    parameter integer PORT_WIDTH   = 4;

    input  [PORT_WIDTH-1:0] SIGNAL_I;
    input                   CLK_I;
    output [PORT_WIDTH-1:0] SIGNAL_O;

    // per-bit counters (fixed width 32-bit for 1995 portability)
    reg [31:0] sig_cntrs_ary [0:PORT_WIDTH-1];
    reg [PORT_WIDTH-1:0] sig_out_reg;

    integer idx;

    // toggle output bit when its counter hits max
    always @(posedge CLK_I) begin
        for (idx = 0; idx < PORT_WIDTH; idx = idx + 1) begin
            if (sig_cntrs_ary[idx] == (DEBNC_CLOCKS-1))
                sig_out_reg[idx] <= ~sig_out_reg[idx];
        end
    end

    // counter control
    always @(posedge CLK_I) begin
        for (idx = 0; idx < PORT_WIDTH; idx = idx + 1) begin
            if (sig_out_reg[idx] ^ SIGNAL_I[idx]) begin
                if (sig_cntrs_ary[idx] == (DEBNC_CLOCKS-1))
                    sig_cntrs_ary[idx] <= 32'd0;
                else
                    sig_cntrs_ary[idx] <= sig_cntrs_ary[idx] + 32'd1;
            end else begin
                sig_cntrs_ary[idx] <= 32'd0;
            end
        end
    end

    assign SIGNAL_O = sig_out_reg;

    // reset init
    initial begin
        sig_out_reg = {PORT_WIDTH{1'b0}};
        for (idx = 0; idx < PORT_WIDTH; idx = idx + 1)
            sig_cntrs_ary[idx] = 32'd0;
    end

endmodule
