module simple_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6
) (
    input wire clk,
    input wire we,                              // Сигнал разрешения записи
    input wire [ADDR_WIDTH-1:0] write_addr,     // Адрес для записи
    input wire [ADDR_WIDTH-1:0] read_addr,      // Адрес для чтения
    input wire [DATA_WIDTH-1:0] write_data,     // Данные для записи
    output reg [DATA_WIDTH-1:0] read_data       // Данные для чтения
);

    // Объявление массива памяти
    reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    // Порт записи: работает по положительному фронту тактового сигнала
    always @(posedge clk) begin
        if (we) begin
            ram[write_addr] <= write_data;
        end
    end

    // Порт чтения: также работает по положительному фронту тактового сигнала
    always @(posedge clk) begin
        read_data <= ram[read_addr];
    end

endmodule


module fifo_bram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6  // Глубина FIFO = 2^ADDR_WIDTH
) (
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] wr_data,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire full,
    output wire empty
);

    // Сигналы для связи с RAM
    wire [ADDR_WIDTH-1:0] wr_addr;
    wire [ADDR_WIDTH-1:0] rd_addr;

    // 1. Инстанцирование модуля RAM (который синтезируется как BRAM)
    simple_dual_port_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_inst (
        .clk(clk),
        .we(wr_en & ~full), // Запись разрешена, если не полна
        .write_addr(wr_addr),
        .read_addr(rd_addr),
        .write_data(wr_data),
        .read_data(rd_data)
    );

    // 2. Логика управления указателями и флагами
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    // ... Здесь реализуется логика инкремента указателей,
    // сравнения их для генерации сигналов full и empty,
    // а также обработка сброса (rst_n).
    // ...

endmodule