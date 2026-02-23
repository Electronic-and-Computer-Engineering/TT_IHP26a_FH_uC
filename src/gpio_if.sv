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
    output reg  [31:0] o_wb_rdt,
    output reg         o_wb_ack,

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
    localparam HALF_TICK  = TICK_LIMIT / 2;

    reg [TICK_BITS-1:0] tx_timer;
    reg [10:0]          tx_shifter;
    reg [3:0]           tx_bit_ctr;

    reg [TICK_BITS-1:0] rx_timer;
    reg [3:0]           rx_bit_ctr;
    reg [7:0]           rx_shifter;
    reg [7:0]           rx_data_out;
    reg                 rx_data_valid;
    reg                 rx_busy;
    reg [1:0]           rx_sync;

    wire tx_busy = (tx_bit_ctr != 0);
    wire rx_line;
    
    // Sync RX input
    always @(posedge i_wb_clk) rx_sync <= {rx_sync[0], i_uart_rx};
    assign rx_line = rx_sync[1];


    // -------------------------------------------------------------------------
    // Main Bus Logic
    // -------------------------------------------------------------------------
    
    // Global ACK: Asserted if we are selected and strobed
    
    assign o_wb_ack =  i_wb_stb ? 1'b1 : 1'b0;

    always_comb begin
        o_wb_rdt = 32'd0;
        if (i_wb_stb) begin
            if (sel_gpio) begin
                // === GPIO ACCESS ===
                o_wb_rdt = {24'd0, i_gpio_in, o_gpio_out};
            end 
            else if (sel_uart) begin
                // === UART ACCESS ===
                // Read: Status + Data
                o_wb_rdt = {tx_busy, rx_data_valid, 22'd0, rx_data_out};
            end
        end

    end
    always @(posedge i_wb_clk) begin
        if (i_wb_rst) begin
            // GPIO Reset
            o_gpio_out <= 4'b0;
            
            // UART Reset
            tx_timer   <= 0;
            tx_bit_ctr <= 0;
            tx_shifter <= 11'b11111111111;
            rx_shifter <= 8'd0;
            o_uart_tx  <= 1'b1;
            rx_timer   <= 0;
            rx_bit_ctr <= 0;
            rx_busy    <= 0;
            rx_data_valid <= 0;
            rx_data_out <= 8'd0;

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
                    end else if (!i_wb_we) begin
                        // Read: Status + Data
                        // Clear valid flag
                        rx_data_valid <= 0;
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

            // --- UART RX STATE MACHINE ---
            if (!rx_busy) begin
                if (rx_line == 0) begin
                    rx_busy    <= 1;
                    rx_timer   <= 0;
                    rx_bit_ctr <= 0;
                end
            end else begin
                rx_timer <= rx_timer + 1;
                if (rx_timer == HALF_TICK) begin
                    if (rx_bit_ctr == 0) begin
                        if (rx_line == 1) rx_busy <= 0;
                    end else if (rx_bit_ctr <= 8) begin
                        rx_shifter <= {rx_line, rx_shifter[7:1]};
                    end else begin
                        rx_busy       <= 0;
                        rx_data_out   <= rx_shifter;
                        rx_data_valid <= 1;
                    end
                end
                if (rx_timer == TICK_LIMIT-1) begin
                    rx_timer   <= 0;
                    rx_bit_ctr <= rx_bit_ctr + 1;
                end
            end
        end
    end
endmodule