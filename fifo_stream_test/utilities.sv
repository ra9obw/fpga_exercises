// module true_dual_port_ram_single_clock
// (
//     input [(DATA_WIDTH-1):0] data_a, data_b,
//     input [(ADDR_WIDTH-1):0] addr_a, addr_b,
//     input we_a, we_b, clk,
//     output reg [(DATA_WIDTH-1):0] q_a, q_b
//     );
//     parameter DATA_WIDTH = 8;
//     parameter ADDR_WIDTH = 6;
//     // Declare the RAM variable
//     reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
//     always @ (posedge clk) begin // Port A
//         if (we_a) begin
//             ram[addr_a] <= data_a;
//             q_a <= data_a;
//         end else
//             q_a <= ram[addr_a];
//     end

//     always @ (posedge clk) begin // Port b
//         if (we_b) begin
//             ram[addr_b] <= data_b;
//             q_b <= data_b;
//         end else 
//             q_b <= ram[addr_b];
//     end
// endmodule


module simple_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6,
    parameter OUTPUT_REGISTERED = 0 //0 - 1 tick read latency; 1 - 2 tick read latency
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
    
    //Далее сделаем условную генерацию которая определит - захватывать в регистры входные адреса и данные по клоке
    //давай дполнительный такт к задержке, но потенциально более высокое быстродействие
    //объявление внутренних регистров для адресов и записываемых данных
    logic [ADDR_WIDTH-1:0] write_addr_reg;
    logic [ADDR_WIDTH-1:0] read_addr_reg;
    logic [DATA_WIDTH-1:0] write_data_reg;
    // logic [DATA_WIDTH-1:0] read_data_buf;
    logic we_reg;
    //блок условной генерации
generate
    if(OUTPUT_REGISTERED) begin
        always @(posedge clk) begin
            write_addr_reg <= write_addr;
            write_data_reg <= write_data;
            read_addr_reg <= read_addr;
            we_reg <= we;
            // read_data_buf <= ram[read_addr_reg];
        end
    end else begin
        always_comb begin
            write_addr_reg = write_addr;
            write_data_reg = write_data;
            read_addr_reg = read_addr;
            we_reg = we;
            // read_data_buf = ram[read_addr_reg];
        end
    end
endgenerate

    // Порт записи: работает по положительному фронту тактового сигнала
    always @(posedge clk) begin
        if (we_reg) begin
            ram[write_addr_reg] <= write_data_reg;
        end
    end

    // Порт чтения: также работает по положительному фронту тактового сигнала

    always @(posedge clk) begin
        read_data <= /*read_data_buf;//*/ram[read_addr_reg];
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