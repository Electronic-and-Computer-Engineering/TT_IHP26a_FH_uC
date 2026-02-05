#define GPIO_ADDR 0x40000000
#define UART_ADDR 0x41000000

#define UART_REG  (*(volatile unsigned int*)UART_ADDR)

// Bit Masks
#define TX_BUSY_MASK   (1 << 31)
#define RX_VALID_MASK  (1 << 30)



// --- SEND CHAR ---
void put_char(unsigned int   c) {
    // Wait until TX is NOT busy
    volatile unsigned int *uart = (unsigned int *)UART_ADDR;

    unsigned int busy = 1;
    while (busy){
        busy = (*uart & TX_BUSY_MASK) != 0;
    }
    *uart = c;
}
char hello[] = "Hello, World!\n";
int main(void)
{
    volatile unsigned int *gpio = (unsigned int *)GPIO_ADDR;
    *gpio = 0x0;
    
    volatile unsigned int *uart = (unsigned int *)UART_ADDR;


    // Initialize outputs to 0

    while (1)
    {

        // Read GPIO register
        unsigned int v = *gpio;

        // Extract input bits [7:4]
        unsigned char in = (v >> 4) & 0xF;

        // Drive outputs [3:0] with inputs
        *gpio = in;

        for (int i = 0; hello[i] != '\0'; i++) {
            put_char(hello[i]);
        }
    }
}
