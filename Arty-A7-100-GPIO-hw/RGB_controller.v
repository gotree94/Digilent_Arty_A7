// -----------------------------------------------------------------------------
// RGB_controller.v -- Verilog-1995 compatible
// -----------------------------------------------------------------------------
module RGB_controller (GCLK, RGB_LED_1_O, RGB_LED_2_O);

    input        GCLK;
    output [2:0] RGB_LED_1_O;  // [2]=Red, [1]=Green, [0]=Blue
    output [2:0] RGB_LED_2_O;

    // constants
    parameter [7:0]  WINDOW        = 8'hFF;
    parameter [19:0] DELTACOUNTMAX = 20'd1000000;
    parameter [8:0]  VALCOUNTMAX   = 9'b101_111_111;

    // counters
    reg [7:0]  windowcount;
    reg [19:0] deltacount;
    reg [8:0]  valcount;

    // intensities
    wire [7:0] incVal;
    wire [7:0] decVal;

    reg [7:0] redVal,   greenVal,   blueVal;
    reg [7:0] redVal2,  greenVal2,  blueVal2;

    reg [2:0] rgbLedReg1;
    reg [2:0] rgbLedReg2;

    assign incVal = {1'b0, valcount[6:0]};
    assign decVal = {1'b0,
                     ~valcount[6], ~valcount[5], ~valcount[4],
                     ~valcount[3], ~valcount[2], ~valcount[1], ~valcount[0]};

    // window counter
    always @(posedge GCLK) begin
        if (windowcount < WINDOW) windowcount <= windowcount + 8'd1;
        else                      windowcount <= 8'd0;
    end

    // delta counter
    always @(posedge GCLK) begin
        if (deltacount < DELTACOUNTMAX) deltacount <= deltacount + 20'd1;
        else                            deltacount <= 20'd0;
    end

    // value counter
    always @(posedge GCLK) begin
        if (deltacount == 20'd0) begin
            if (valcount < VALCOUNTMAX) valcount <= valcount + 9'd1;
            else                        valcount <= 9'd0;
        end
    end

    // color selection (combinational)
    always @(*) begin
        case (valcount[8:7])
            2'b00: begin
                redVal   = incVal; greenVal = decVal; blueVal  = 8'd0;
                redVal2  = incVal; greenVal2= decVal; blueVal2 = 8'd0;
            end
            2'b01: begin
                redVal   = decVal; greenVal = 8'd0;   blueVal  = incVal;
                redVal2  = decVal; greenVal2= 8'd0;   blueVal2 = incVal;
            end
            default: begin
                redVal   = 8'd0;   greenVal = incVal; blueVal  = decVal;
                redVal2  = 8'd0;   greenVal2= incVal; blueVal2 = decVal;
            end
        endcase
    end

    // PWM compare
    always @(posedge GCLK) begin
        rgbLedReg1[2] <= (redVal   > windowcount);
        rgbLedReg1[1] <= (greenVal > windowcount);
        rgbLedReg1[0] <= (blueVal  > windowcount);

        rgbLedReg2[2] <= (redVal2   > windowcount);
        rgbLedReg2[1] <= (greenVal2 > windowcount);
        rgbLedReg2[0] <= (blueVal2  > windowcount);
    end

    assign RGB_LED_1_O = rgbLedReg1;
    assign RGB_LED_2_O = rgbLedReg2;

    // reset init
    initial begin
        windowcount = 8'd0;
        deltacount  = 20'd0;
        valcount    = 9'd0;
        rgbLedReg1  = 3'b000;
        rgbLedReg2  = 3'b000;
    end

endmodule
