`default_nettype none
`timescale 1ns/1ps

module gpio_if #(
    parameter CLK_FREQ  = 10000000,
    parameter BAUD_RATE = 9600
) (
    input  wire        i_wb_clk,
    input  wire        i_wb_rst,

    // Wishbone (minimal classic subset)
    input  wire [31:0] i_wb_adr,
    input  wire [31:0] i_wb_dat,
    input  wire        i_wb_we,
    input  wire        i_wb_stb,
    output wire [31:0] o_wb_rdt,
    output wire        o_wb_ack,

    // GPIO
    input  wire [3:0]  i_gpio_in,
    output reg  [3:0]  o_gpio_out,

    // UART
    output reg         o_uart_tx,
    input  wire        i_uart_rx
);

// -------------------------------------------------------------------------
    // Address Decoding
    // -------------------------------------------------------------------------
    // We check bit 12 to distinguish 0x0000 vs 0x1000.
    // 0x40000000 -> Bit 12 is 0 -> GPIO
    // 0x40001000 -> Bit 12 is 1 -> UART
    wire sel_gpio = i_wb_adr == 32'h40000000;  //(i_wb_adr[12] == 1'b0);
    wire sel_uart = i_wb_adr == 32'h41000000;

    // -------------------------------------------------------------------------
    // UART Internal Signals & Logic
    // -------------------------------------------------------------------------
    localparam TICK_LIMIT = CLK_FREQ / BAUD_RATE;
    localparam TICK_BITS  = $clog2(TICK_LIMIT);

    reg [TICK_BITS-1:0] tx_timer;
    reg [10:0]          tx_shifter;
    reg [3:0]           tx_bit_ctr;

    wire tx_busy = (tx_bit_ctr != 0);


    // -------------------------------------------------------------------------
    // Main Bus Logic
    // -------------------------------------------------------------------------
    
    // Global ACK: Asserted if we are selected and strobed
    assign o_wb_ack = i_wb_stb ? 1'b1 : 1'b0;

    assign o_wb_rdt = sel_gpio ? {24'd0, i_gpio_in, o_gpio_out} :
                      sel_uart ? {tx_busy, 31'd0} :
                                 32'd0;
    always @(posedge i_wb_clk) begin
        if (i_wb_rst) begin
            // GPIO Reset
            o_gpio_out <= 4'b0;
            
            // UART Reset
            tx_timer   <= 0;
            tx_bit_ctr <= 0;
            tx_shifter <= 11'b11111111111;
            o_uart_tx  <= 1'b1;

        end else begin
            
            // --- BUS READ/WRITE MUX ---
            if (i_wb_stb) begin
                if (sel_gpio) begin
                    // === GPIO ACCESS ===
                    // Write
                    if (i_wb_we) begin
                        o_gpio_out <= i_wb_dat[3:0];
                    end
                end 
                else if (sel_uart) begin // ONLY accept if NOT busy
                    // === UART ACCESS ===
                    if (i_wb_we && !tx_busy) begin
                        // Write: Start TX
                        tx_shifter <= {2'b11, i_wb_dat[7:0], 1'b0};
                        tx_bit_ctr <= 11;
                        tx_timer   <= 0;
                    end
                end
            end

            // --- UART TX STATE MACHINE ---
            if (tx_busy) begin
                if (tx_timer == TICK_LIMIT-1) begin
                    tx_timer   <= 0;
                    o_uart_tx  <= tx_shifter[0];
                    tx_shifter <= {1'b1, tx_shifter[10:1]};
                    tx_bit_ctr <= tx_bit_ctr - 1;
                end else begin
                    tx_timer <= tx_timer + 1;
                end
            end
        end
    end
endmodule
`default_nettype wire