// -----------------------------------------------------------------------------
// UART_TX_CTRL.v  -- Verilog-1995 compatible
// -----------------------------------------------------------------------------
module UART_TX_CTRL (SEND, DATA, CLK, READY, UART_TX);

    input        SEND;
    input  [7:0] DATA;
    input        CLK;
    output       READY;
    output       UART_TX;

    // parameters (no localparam / enum)
    parameter [13:0] BIT_TMR_MAX    = 14'd10416; // round(100MHz/9600)-1
    parameter integer BIT_INDEX_MAX = 10;

    // regs / wires
    reg [1:0]  txState;          // state encoding
    reg [13:0] bitTmr;
    wire       bitDone;
    reg [3:0]  bitIndex;
    reg [9:0]  txData;
    reg        txBit;

    // state encodings
    parameter RDY      = 2'd0;
    parameter LOAD_BIT = 2'd1;
    parameter SEND_BIT = 2'd2;

    assign bitDone = (bitTmr == BIT_TMR_MAX);
    assign UART_TX = txBit;
    assign READY   = (txState == RDY);

    // next state
    always @(posedge CLK) begin
        case (txState)
            RDY: begin
                if (SEND) txState <= LOAD_BIT;
                else      txState <= RDY;
            end
            LOAD_BIT: txState <= SEND_BIT;
            SEND_BIT: begin
                if (bitDone) begin
                    if (bitIndex == BIT_INDEX_MAX) txState <= RDY;
                    else                           txState <= LOAD_BIT;
                end
            end
            default: txState <= RDY;
        endcase
    end

    // bit timer
    always @(posedge CLK) begin
        if (txState == RDY)       bitTmr <= 14'd0;
        else if (bitDone)         bitTmr <= 14'd0;
        else                      bitTmr <= bitTmr + 14'd1;
    end

    // bit index
    always @(posedge CLK) begin
        if (txState == RDY)       bitIndex <= 4'd0;
        else if (txState == LOAD_BIT) bitIndex <= bitIndex + 4'd1;
    end

    // load frame
    always @(posedge CLK) begin
        if (SEND) txData <= {1'b1, DATA, 1'b0}; // stop, data[7:0], start
    end

    // drive current bit
    always @(posedge CLK) begin
        if (txState == RDY)       txBit <= 1'b1;            // idle high
        else if (txState == LOAD_BIT) txBit <= txData[bitIndex];
    end

    // reset init
    initial begin
        txState  = RDY;
        bitTmr   = 14'd0;
        bitIndex = 4'd0;
        txData   = 10'b11_1111_1111;
        txBit    = 1'b1;
    end

endmodule
