// -----------------------------------------------------------------------------
// GPIO_demo.v -- Verilog-1995 compatible
// -----------------------------------------------------------------------------
module GPIO_demo (
    SW, BTN, CLK, LED, UART_TXD,
    RGB0_Red, RGB0_Green, RGB0_Blue,
    RGB1_Red, RGB1_Green, RGB1_Blue,
    RGB2_Red, RGB2_Green, RGB2_Blue,
    RGB3_Red, RGB3_Green, RGB3_Blue
);

    input  [3:0] SW;
    input  [3:0] BTN;
    input        CLK;
    output [3:0] LED;
    output       UART_TXD;
    output       RGB0_Red, RGB0_Green, RGB0_Blue;
    output       RGB1_Red, RGB1_Green, RGB1_Blue;
    output       RGB2_Red, RGB2_Green, RGB2_Blue;
    output       RGB3_Red, RGB3_Green, RGB3_Blue;

    // constants
    parameter integer MAX_STR_LEN     = 31;
    parameter integer WELCOME_STR_LEN = 31;
    parameter integer BTN_STR_LEN     = 24;
    parameter integer RESET_CNTR_MAX  = 200000; // ~2ms @ 100MHz

    // state encoding
    parameter [2:0] RST_REG     = 3'd0;
    parameter [2:0] LD_INIT_STR = 3'd1;
    parameter [2:0] SEND_CHAR   = 3'd2;
    parameter [2:0] RDY_LOW     = 3'd3;
    parameter [2:0] WAIT_RDY    = 3'd4;
    parameter [2:0] WAIT_BTN    = 3'd5;
    parameter [2:0] LD_BTN_STR  = 3'd6;

    // regs / wires
    wire [3:0] btnDeBnc;
    reg  [3:0] btnReg;
    wire       btnDetect;

    reg  [2:0] uartState;
    wire       uartRdy;
    reg        uartSend;
    reg  [7:0] uartData;
    wire       uartTX;

    reg        sel_btn_str;
    reg  [5:0] strIndex;
    reg  [5:0] strEnd;

    reg [17:0] reset_cntr;

    // LED mirror
    assign LED = SW;

    // debounce instance (1995 style ports)
    debouncer
    #(
        .DEBNC_CLOCKS (1 << 16),
        .PORT_WIDTH   (4)
    )
    Inst_btn_debounce (
        .SIGNAL_I (BTN),
        .CLK_I    (CLK),
        .SIGNAL_O (btnDeBnc)
    );

    // button edge detect
    always @(posedge CLK) begin
        btnReg <= btnDeBnc;
    end

    assign btnDetect =
        ((~btnReg[0] & btnDeBnc[0]) |
         (~btnReg[1] & btnDeBnc[1]) |
         (~btnReg[2] & btnDeBnc[2]) |
         (~btnReg[3] & btnDeBnc[3]));

    // ~2ms guard
    always @(posedge CLK) begin
        if ((reset_cntr == RESET_CNTR_MAX) || (uartState != RST_REG))
            reset_cntr <= 18'd0;
        else
            reset_cntr <= reset_cntr + 18'd1;
    end

    // UART state machine
    always @(posedge CLK) begin
        case (uartState)
            RST_REG: begin
                if (reset_cntr == RESET_CNTR_MAX) uartState <= LD_INIT_STR;
            end

            LD_INIT_STR: uartState <= SEND_CHAR;
            SEND_CHAR  : uartState <= RDY_LOW;
            RDY_LOW    : uartState <= WAIT_RDY;

            WAIT_RDY: begin
                if (uartRdy) begin
                    if (strEnd == strIndex) uartState <= WAIT_BTN;
                    else                    uartState <= SEND_CHAR;
                end
            end

            WAIT_BTN: begin
                if (btnDetect) uartState <= LD_BTN_STR;
            end

            LD_BTN_STR: uartState <= SEND_CHAR;

            default: uartState <= RST_REG;
        endcase
    end

    // select string and set end index
    always @(posedge CLK) begin
        if (uartState == LD_INIT_STR) begin
            sel_btn_str <= 1'b0;                       // welcome
            strEnd      <= WELCOME_STR_LEN[5:0];
        end else if (uartState == LD_BTN_STR) begin
            sel_btn_str <= 1'b1;                       // button
            strEnd      <= BTN_STR_LEN[5:0];
        end
    end

    // strIndex counter
    always @(posedge CLK) begin
        if ((uartState == LD_INIT_STR) || (uartState == LD_BTN_STR))
            strIndex <= 6'd0;
        else if (uartState == SEND_CHAR)
            strIndex <= strIndex + 6'd1;
    end

    // ROM functions (Verilog-1995)
    function [7:0] welcome_byte;
        input [5:0] idx;
        begin
            case (idx)
                6'd0 : welcome_byte = 8'h0A;
                6'd1 : welcome_byte = 8'h0D;
                6'd2 : welcome_byte = 8'h41;
                6'd3 : welcome_byte = 8'h52;
                6'd4 : welcome_byte = 8'h54;
                6'd5 : welcome_byte = 8'h59;
                6'd6 : welcome_byte = 8'h20;
                6'd7 : welcome_byte = 8'h47;
                6'd8 : welcome_byte = 8'h50;
                6'd9 : welcome_byte = 8'h49;
                6'd10: welcome_byte = 8'h4F;
                6'd11: welcome_byte = 8'h2F;
                6'd12: welcome_byte = 8'h55;
                6'd13: welcome_byte = 8'h41;
                6'd14: welcome_byte = 8'h52;
                6'd15: welcome_byte = 8'h54;
                6'd16: welcome_byte = 8'h20;
                6'd17: welcome_byte = 8'h44;
                6'd18: welcome_byte = 8'h45;
                6'd19: welcome_byte = 8'h4D;
                6'd20: welcome_byte = 8'h4F;
                6'd21: welcome_byte = 8'h21;
                6'd22: welcome_byte = 8'h20;
                6'd23: welcome_byte = 8'h20;
                6'd24: welcome_byte = 8'h20;
                6'd25: welcome_byte = 8'h20;
                6'd26: welcome_byte = 8'h20;
                6'd27: welcome_byte = 8'h20;
                6'd28: welcome_byte = 8'h0A;
                6'd29: welcome_byte = 8'h0A;
                6'd30: welcome_byte = 8'h0D;
                default: welcome_byte = 8'h00;
            endcase
        end
    endfunction

    function [7:0] btn_byte;
        input [5:0] idx;
        begin
            case (idx)
                6'd0 : btn_byte = 8'h42;
                6'd1 : btn_byte = 8'h75;
                6'd2 : btn_byte = 8'h74;
                6'd3 : btn_byte = 8'h74;
                6'd4 : btn_byte = 8'h6F;
                6'd5 : btn_byte = 8'h6E;
                6'd6 : btn_byte = 8'h20;
                6'd7 : btn_byte = 8'h70;
                6'd8 : btn_byte = 8'h72;
                6'd9 : btn_byte = 8'h65;
                6'd10: btn_byte = 8'h73;
                6'd11: btn_byte = 8'h73;
                6'd12: btn_byte = 8'h20;
                6'd13: btn_byte = 8'h64;
                6'd14: btn_byte = 8'h65;
                6'd15: btn_byte = 8'h74;
                6'd16: btn_byte = 8'h65;
                6'd17: btn_byte = 8'h63;
                6'd18: btn_byte = 8'h74;
                6'd19: btn_byte = 8'h65;
                6'd20: btn_byte = 8'h64;
                6'd21: btn_byte = 8'h21;
                6'd22: btn_byte = 8'h0A;
                6'd23: btn_byte = 8'h0D;
                default: btn_byte = 8'h00;
            endcase
        end
    endfunction

    // drive UART char
    always @(posedge CLK) begin
        if (uartState == SEND_CHAR) begin
            uartSend <= 1'b1;
            if (sel_btn_str) uartData <= btn_byte(strIndex);
            else             uartData <= welcome_byte(strIndex);
        end else begin
            uartSend <= 1'b0;
        end
    end

    // UART TX block (1995 ports)
    UART_TX_CTRL u_uart_tx_ctrl (
        .SEND    (uartSend),
        .DATA    (uartData),
        .CLK     (CLK),
        .READY   (uartRdy),
        .UART_TX (uartTX)
    );

    assign UART_TXD = uartTX;

    // RGB controllers (그대로 연결)
    RGB_controller RGB_Core1 (
        .GCLK        (CLK),
        .RGB_LED_1_O ({RGB0_Red, RGB0_Blue, RGB0_Green}),
        .RGB_LED_2_O ({RGB2_Red, RGB2_Blue, RGB2_Green})
    );

    RGB_controller RGB_Core2 (
        .GCLK        (CLK),
        .RGB_LED_1_O ({RGB1_Red, RGB1_Blue, RGB1_Green}),
        .RGB_LED_2_O ({RGB3_Red, RGB3_Blue, RGB3_Green})
    );

    // reset init
    initial begin
        btnReg     = 4'b0000;
        uartState  = RST_REG;
        uartSend   = 1'b0;
        uartData   = 8'h00;
        sel_btn_str= 1'b0;
        strIndex   = 6'd0;
        strEnd     = 6'd0;
        reset_cntr = 18'd0;
    end

endmodule
