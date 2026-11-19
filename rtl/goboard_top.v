`default_nettype none

module goboard_top #(
    parameter CLKS_PER_BIT = 217,   // 25 MHz / 115200
    parameter MAXQ = 10,
    parameter PW = 9
) (
    input  wire i_Clk,
    input  wire i_UART_RX,
    output wire o_UART_TX,
    output wire o_LED_1,
    output wire o_LED_2,
    output wire o_LED_3,
    output wire o_LED_4
);
    // power on reset
    reg[3:0] por = 4'd0;
    wire rst = ~&por;
    always @(posedge i_Clk) if (rst) por <= por + 1'b1;

    // uart portion from nandland go board example
    reg[1:0] rx_sync = 2'b11; 
    always @(posedge i_Clk) rx_sync <= {rx_sync[0], i_UART_RX}; // rx async from CLK, so store in reg until posedge

    wire rx_valid;
    wire[7:0] rx_data;
    reg tx_start;
    reg[7:0] tx_data;
    wire tx_active, tx_done; // dummy wires for now...
    UART_RX #(.CLKS_PER_BIT(CLKS_PER_BIT)) urx (
        .i_Rst_L(~rst), .i_Clock(i_Clk), .i_RX_Serial(rx_sync[1]),
        .o_RX_DV(rx_valid), .o_RX_Byte(rx_data));
    UART_TX #(.CLKS_PER_BIT(CLKS_PER_BIT)) utx (
        .i_Rst_L(~rst), .i_Clock(i_Clk), .i_TX_DV(tx_start), .i_TX_Byte(tx_data),
        .o_TX_Active(tx_active), .o_TX_Serial(o_UART_TX), .o_TX_Done(tx_done));

    // flags for communication via uart (FSM utils in a way)
    reg tx_busy; 
    always @(posedge i_Clk)
        if (rst || tx_done) tx_busy <= 1'b0;
        else if (tx_start) tx_busy <= 1'b1;
    wire tx_ready = ~tx_busy;


endmodule
