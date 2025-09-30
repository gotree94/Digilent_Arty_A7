module switch_led_control (
    input  wire        CLK100MHZ, // XDC와 동일
    input  wire [3:0]  sw,        // <-- sw[0]를 위해 벡터 선언
    output wire        led0_b,
    output wire        led0_g,
    output wire        led0_r,
    output wire        led1_b,
    output wire        led1_g,
    output wire        led1_r,
    output wire        led2_b,
    output wire        led2_g,
    output wire        led2_r,
    output wire        led3_b,
    output wire        led3_g,
    output wire        led3_r,
    output wire [3:0]  led        // <-- led[0..3] 벡터로 선언
);

    // sw[0] == 1이면 모든 LED ON, 아니면 OFF
    wire on0 = sw[0];
    wire on1 = sw[1];
    wire on2 = sw[2];
    wire on3 = sw[3];

    assign led0_b = on0;
    assign led0_g = on1;
    assign led0_r = on2;
    assign led1_b = on0;
    assign led1_g = on1;
    assign led1_r = on2;
    assign led2_b = on0;
    assign led2_g = on1;
    assign led2_r = on2;
    assign led3_b = on0;
    assign led3_g = on1;
    assign led3_r = on2;

    assign led = {on0, on1, on2, on3 }; // led[3:0] 모두 on

    // 사용하지 않는 sw[3:1]은 그대로 두어도 무방 (XDC에서 주석 상태면 제약 없음)
endmodule
