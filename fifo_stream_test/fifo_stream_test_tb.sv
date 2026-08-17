// `timescale 1 ps / 1 ps

// module fifo_stream_test_tb();
//     parameter SYS_CLOCK_PERIOD = 10000;        //100MHz

//         reg		clk;
//         reg		reset;
//         reg  [31:0]   in_flow_data;
//         reg           in_flow_valid;
//         wire [7:0]    fifo_usedw;
//         wire		    out_stream_valid;
//         reg 		    out_stream_ready;
//         wire [31:0]	out_stream_data;

//     fifo_stream_test uut(
// /*input		    */ .clk             (clk),
// /*input		    */ .reset           (reset),
// /*input  [31:0] */ .in_flow_data    (in_flow_data),
// /*input         */ .in_flow_valid   (in_flow_valid),
// /*output [7:0]  */ .fifo_usedw      (fifo_usedw),
// /*output		*/ .out_stream_valid(out_stream_valid),
// /*input 		*/ .out_stream_ready(out_stream_ready),
// /*output [31:0]	*/ .out_stream_data (out_stream_data)
//     );

// task push_to_fifo_head(
// 	input [31:0] i_data
// );
// begin
// 	@(posedge clk); 
// 	in_flow_valid = 1;
// 	in_flow_data = i_data;
// end
// endtask

// task push_to_fifo_tail();
// begin
// 	@(posedge clk); 
// 	in_flow_valid = 0;
// 	in_flow_data = 0;
// end
// endtask

// task push_to_fifo_single(
// 	input [31:0] i_data
// );
// begin
// 	@(posedge clk); 
// 	in_flow_valid = 1;
// 	in_flow_data = i_data;
//     push_to_fifo_tail();
// end
// endtask


// bit [31:0] fifo_content [] = {  32'h11111111, 
//                                 32'h22222222,
// 					            32'h33333333,
//                                 32'h44444444
// 				       };

// initial begin
//     clk = 1;
//     forever
//         #(SYS_CLOCK_PERIOD/2) clk = !clk;
// end


// initial begin
//     in_flow_data <= 1'b0;
//     in_flow_valid <= 1'b0;
//     out_stream_ready <= 1'b0;
//     reset <= 1'b0;
//     #100_000
//     reset <= 1'b1;
//     #100_000
//     reset <= 1'b0;
//     repeat (20) @(posedge clk);
//     foreach(fifo_content[j]) begin
//         $display("fifo value = 0x%08h", fifo_content[j]);
//         push_to_fifo_head(fifo_content[j]);
//     end
//     push_to_fifo_tail();
//     repeat (20) @(posedge clk);
//     out_stream_ready <= 1'b1;
//     @(posedge clk);
//     out_stream_ready <= 1'b0;
//     @(posedge clk);
//     out_stream_ready <= 1'b1;
//     repeat (50) @(posedge clk);
//     $stop;
// end



// task automatic print_stream_transaction( );
//   @(posedge clk iff (out_stream_ready && out_stream_valid));
//   $display("[%t] stream data=0x%08x",
//            $time,
//            out_stream_data
//            );
// endtask

// initial begin
//   forever begin
//     print_stream_transaction();
//   end
// end


// endmodule

`timescale 1 ps / 1 ps

module fifo_stream_test_tb();
    parameter SYS_CLOCK_PERIOD = 10000;
    parameter DATA_WIDTH = 32;
    parameter FIFO_DEPTH = 256;
    parameter TEST_COUNT = 20;

    reg		clk;
    reg		reset;
    reg  [DATA_WIDTH-1:0]   in_flow_data;
    reg           in_flow_valid;
    wire [7:0]    fifo_usedw;
    wire		  out_stream_valid;
    reg 		  out_stream_ready;
    wire [DATA_WIDTH-1:0]	out_stream_data;

    // Очередь для ожидаемых данных
    reg [DATA_WIDTH-1:0] expected_queue [$];
    reg [DATA_WIDTH-1:0] sent_data [$];
    
    // Статистика
    integer sent_count = 0;
    integer received_count = 0;
    integer errors = 0;
    logic detailed_log;
    
    fifo_stream_test uut(
        .clk             (clk),
        .reset           (reset),
        .in_flow_data    (in_flow_data),
        .in_flow_valid   (in_flow_valid),
        .fifo_usedw      (fifo_usedw),
        .out_stream_valid(out_stream_valid),
        .out_stream_ready(out_stream_ready),
        .out_stream_data (out_stream_data)
    );

    // Генератор тактов
    initial begin
        clk = 0;
        forever #(SYS_CLOCK_PERIOD/2) clk = ~clk;
    end

    // Генератор случайных данных
    function automatic [DATA_WIDTH-1:0] random_data;
        integer seed;
        seed = $urandom();
        random_data = $urandom(seed) & 32'hFFFFFFFF;
    endfunction

    task automatic check_results();       // Проверка что все данные получены
        repeat (20) @(posedge clk);
        if(received_count == sent_count) begin
            $display("\n=== SUCCESS: All %0d data items received correctly ===", received_count);
        end else begin
            $display("\n=== FAILURE: Sent %0d, Received %0d ===", sent_count, received_count);
        end
        
        if(errors > 0) begin
            $display("=== FAILURE: %0d errors detected ===", errors);
        end
        
        $display("Test completed at time %t", $time);
    endtask

    task automatic reset_counters();
        @(posedge clk);
        expected_queue.delete();
        sent_data.delete();
        sent_count = 0;
        received_count = 0;
        errors = 0;
        @(posedge clk);
    endtask

    integer i;
    integer seed = 12345;

    task automatic fill_fifo_with_random_gaps(
        input int target_count = TEST_COUNT
    );
        int sended_count = 0;
        // Создаем тестовые данные с известными значениями
        for(i = 0, sended_count=0; sended_count < target_count; i++) begin           
            @(posedge clk);
            in_flow_data <= 32'h10000000 + i;
            sent_data.push_back(32'h10000000 + i);
            expected_queue.push_back(32'h10000000 + i);
            in_flow_valid <= 1;
            sent_count = sent_count + 1;
            sended_count++;
            if(detailed_log) $display("[%t] SENT[%0d]: 0x%08h\t%d\t%d", $time, i, 32'h10000000 + i, sended_count, target_count);
            
            // Случайные паузы между записями
            if($urandom() % 3 == 0) begin
                @(posedge clk);
                in_flow_valid <= 0;
                repeat ($urandom() % 5) @(posedge clk);
            end
        end
        // Завершаем запись
        @(posedge clk);
        in_flow_valid <= 0;
    endtask

    task automatic fill_fifo_with_pattern(
        input [9:0] pattern,          // битовый паттерн (1 - писать, 0 - не писать)
        input int start_value = 1234, // начальное значение данных
        input int max_cycles = 1000   // максимальное число циклов для безопасности
    );
        int bit_index = 0;
        int data_value = start_value;
        int cycles_done = 0;
        int writes_done = 0;
        int pattern_bits = 10;          // количество бит в паттерне
        
        // Подсчет количества единиц в паттерне
        int total_writes = 0;
        for (int i = 0; i < pattern_bits; i++) begin
            if (pattern[i]) total_writes++;
        end
        
        in_flow_valid <= 0;
        in_flow_data <= 0;

        while (cycles_done < max_cycles && writes_done < total_writes) begin
            @(posedge clk);
            cycles_done++;
            
            // Определяем, нужно ли писать в этом такте
            if (pattern[bit_index]) begin
                in_flow_valid <= 1;
                in_flow_data <= data_value;

                sent_data.push_back(data_value);
                expected_queue.push_back(data_value);
                sent_count = sent_count + 1;

                data_value++;
                writes_done++;

            end else begin
                in_flow_valid <= 0;
            end
            
            // Переход к следующему биту (циклический обход паттерна)
            bit_index = (bit_index + 1) % pattern_bits;
        end
        
        // Отключаем запись
        @(posedge clk);
        in_flow_valid <= 0;
        
        // Финальный отчет
        if(detailed_log) begin
            $display("[%0t] === FILL COMPLETE ===", $time);
            $display("    Writes done: %0d/%0d", writes_done, total_writes);
            $display("    Cycles used: %0d", cycles_done);
            $display("    Next value: 0x%h", data_value);
            $display("    FIFO usedw: %0d", fifo_usedw);
            $display("===========================");
        end
    endtask

    task automatic pop_stream_with_pattern(
        input [9:0] pattern           // битовый паттерн (1 - писать, 0 - не писать)
    );
        int pattern_bits = 10; 
        for (int i = 0; i < pattern_bits; i++) begin
            @(posedge clk);
            out_stream_ready <= pattern[i];
        end
        @(posedge clk);
        out_stream_ready <= 0;
    endtask


    task automatic drive_out_stream_with_gaps(
        input int target_count = TEST_COUNT,
        input int max_cycles = 3*TEST_COUNT
    );
        int fifo_rcv_count = 0;

        for(i = 0; ((i < max_cycles) && (fifo_rcv_count < target_count)); i++) begin
            @(posedge clk);
            // Разные паттерны ready
            if(i < TEST_COUNT/2) begin
                out_stream_ready <= 1;
            end else if(i < TEST_COUNT) begin
            // Медленное чтение с паузами
                if(i % 2 == 0) 
                    out_stream_ready <= 1;
                else
                    out_stream_ready <= 0;
            end else if(i < 3*TEST_COUNT/2) begin
                // Медленное чтение с паузами
                if(i % 4 == 0) 
                    out_stream_ready <= 1;
                else
                    out_stream_ready <= 0;
            end else begin
                out_stream_ready <= 1;
            end
            

            if (out_stream_ready && out_stream_valid) begin
                fifo_rcv_count++;
                // $display("[%t] RCV\t%d\t%d\t%d\t%d", $time, i, max_cycles, fifo_rcv_count, target_count);
            end
        end
    endtask

    task automatic drive_out_stream_random_gaps(
        input int target_count = TEST_COUNT,
        input int max_cycles = 3*TEST_COUNT
    );
        int fifo_rcv_count = 0;

        for(i = 0; ((i < max_cycles) && (fifo_rcv_count < target_count)); i++) begin
            @(posedge clk);
            out_stream_ready <= 1;
            #10
            if (out_stream_ready && out_stream_valid) begin
                fifo_rcv_count++;
            end
            
            if($urandom() % 3 == 0) begin
                @(posedge clk);
                out_stream_ready <= 0;
                repeat ($urandom() % 5) @(posedge clk);
            end
            
        end
    endtask

    // Основной тест
    initial begin
       
        // Инициализация

        detailed_log = 1'b0;


        in_flow_data <= 0;
        in_flow_valid <= 0;
        out_stream_ready <= 0;
        reset <= 0;
        
        // Сброс
        #100_000;
        reset <= 1;
        #100_000;
        reset <= 0;


        repeat (10) @(posedge clk);
        $display("\n=== fill wait and read with no gap ===");
        
        fill_fifo_with_pattern(  10'b1111000000 );
        repeat (10) @(posedge clk);
        pop_stream_with_pattern( 10'b1111000000 );
        
        check_results();
        reset_counters();


        repeat (10) @(posedge clk);
        $display("\n=== fill and read in parallel PATTERN 1 ===");

        fork
            fill_fifo_with_pattern(  10'b0001111000 );
            pop_stream_with_pattern( 10'b1111000000 );
        join

        check_results();
        reset_counters();

        

        repeat (10) @(posedge clk);
        $display("\n=== fill and read in parallel PATTERN 2 ===");

        fork
            fill_fifo_with_pattern(  10'b0000001011 );
            pop_stream_with_pattern( 10'b0001101000 );
        join

        check_results();
        reset_counters();
        
        repeat (10) @(posedge clk);

        // $stop;

        $display("\n=== random fill and gap read ===");
        
        fill_fifo_with_random_gaps();    
        drive_out_stream_with_gaps();
        
        check_results();
        reset_counters();
        
        repeat (20) @(posedge clk);
        $display("\n=== parallel fill and read with random gaps  ===");
        
        fork 
            fill_fifo_with_random_gaps(300);
            drive_out_stream_random_gaps(300, 10000);
        join
        
        
        check_results();
        #1000
        $stop;
    end

    // Автоматическая проверка выходных данных
    always @(posedge clk) begin
        if(out_stream_valid && out_stream_ready) begin
            received_count = received_count + 1;
            
            // Проверяем соответствие данных
            if(expected_queue.size() > 0) begin
                automatic reg [DATA_WIDTH-1:0] expected = expected_queue.pop_front();
                
                if(out_stream_data !== expected) begin
                    $error("[%t] DATA MISMATCH: Expected 0x%08h, Got 0x%08h", 
                           $time, expected, out_stream_data);
                    errors = errors + 1;
                end else begin
                    if(detailed_log) $display("[%t] VERIFIED[%0d]: 0x%08h OK", $time, received_count-1, out_stream_data);
                end
            end else begin
                $warning("[%t] Unexpected data: 0x%08h", $time, out_stream_data);
                errors = errors + 1;
            end
        end
    end


endmodule


// `timescale 1 ps / 1 ps

// module fifo_stream_test_tb();
//     parameter SYS_CLOCK_PERIOD = 10000;
//     parameter DATA_WIDTH = 32;
//     parameter FIFO_DEPTH = 256;
//     parameter TEST_COUNT = 20;

//     // Сигналы
//     reg		clk;
//     reg		reset;
//     reg  [DATA_WIDTH-1:0]   in_flow_data;
//     reg           in_flow_valid;
//     wire [7:0]    fifo_usedw;
//     wire		  out_stream_valid;
//     reg 		  out_stream_ready;
//     wire [DATA_WIDTH-1:0]	out_stream_data;

//     // Очереди для проверки
//     reg [DATA_WIDTH-1:0] expected_queue [$];
//     reg [DATA_WIDTH-1:0] received_queue [$];
    
//     // Статистика
//     integer sent_count = 0;
//     integer received_count = 0;
//     integer errors = 0;
//     integer test_id = 0;
    
//     // DUT
//     fifo_stream_test uut(
//         .clk             (clk),
//         .reset           (reset),
//         .in_flow_data    (in_flow_data),
//         .in_flow_valid   (in_flow_valid),
//         .fifo_usedw      (fifo_usedw),
//         .out_stream_valid(out_stream_valid),
//         .out_stream_ready(out_stream_ready),
//         .out_stream_data (out_stream_data)
//     );

//     // Генератор тактов
//     initial begin
//         clk = 0;
//         forever #(SYS_CLOCK_PERIOD/2) clk = ~clk;
//     end

//     // Генератор случайных данных
//     function automatic [DATA_WIDTH-1:0] random_data();
//         return $urandom() & 32'hFFFFFFFF;
//     endfunction

//     // Очистка очередей и счетчиков
//     task reset_counters();
//         expected_queue.delete();
//         received_queue.delete();
//         sent_count = 0;
//         received_count = 0;
//         errors = 0;
//     endtask

//     // Заполнение FIFO данными
//     task send_data(input int count, input int pattern_type, input int pause_type);
//         integer i;
//         reg [DATA_WIDTH-1:0] data;
        
//         for(i = 0; i < count; i++) begin
//             @(posedge clk);
            
//             // Генерация данных по паттерну
//             case(pattern_type)
//                 0: data = 32'h10000000 + i;           // Инкремент
//                 1: data = 32'h20000000 + i*2;         // Шаг 2
//                 2: data = random_data();              // Случайные
//                 3: data = {16'hAAAA, 16'hBBBB};       // Фиксированные
//                 default: data = i;
//             endcase
            
//             in_flow_data <= data;
//             expected_queue.push_back(data);
//             in_flow_valid <= 1;
//             sent_count = sent_count + 1;
//             $display("[TEST%0d][%t] SENT[%0d]: 0x%08h", test_id, $time, i, data);
            
//             // Паузы между записями
//             case(pause_type)
//                 0: ; // Без паузы
//                 1: begin // Случайная пауза
//                     if($urandom() % 3 == 0) begin
//                         @(posedge clk);
//                         in_flow_valid <= 0;
//                         repeat ($urandom() % 5) @(posedge clk);
//                     end
//                 end
//                 2: begin // Пауза после каждого слова
//                     @(posedge clk);
//                     in_flow_valid <= 0;
//                     repeat (2) @(posedge clk);
//                 end
//                 3: begin // Длинная пауза
//                     if(i % 3 == 0) begin
//                         @(posedge clk);
//                         in_flow_valid <= 0;
//                         repeat ($urandom() % 10 + 5) @(posedge clk);
//                     end
//                 end
//                 default: ;
//             endcase
//         end
        
//         @(posedge clk);
//         in_flow_valid <= 0;
//         $display("[TEST%0d] Sent %0d items", test_id, count);
//     endtask

//     // Чтение из FIFO с различными паттернами ready
//     task read_data(input int max_cycles, input int ready_pattern, input int check_enabled);
//         integer i;
//         integer cycles = 0;
        
//         $display("[TEST%0d] Starting read with pattern %0d", test_id, ready_pattern);
        
//         while(cycles < max_cycles) begin
//             @(posedge clk);
            
//             // Управление out_stream_ready по паттерну
//             case(ready_pattern)
//                 0: out_stream_ready <= 1;                    // Всегда готов
//                 1: out_stream_ready <= (cycles % 2 == 0);    // Через такт
//                 2: out_stream_ready <= (cycles % 3 == 0);    // Каждый 3-й
//                 3: begin                                     // Случайный
//                     out_stream_ready <= ($urandom() % 3 != 0);
//                 end
//                 4: begin                                     // Паттерн: 1,1,0,1,0
//                     out_stream_ready <= !((cycles % 5 == 2) || (cycles % 5 == 4));
//                 end
//                 5: begin                                     // Быстрое начало, потом медленно
//                     if(cycles < 10) 
//                         out_stream_ready <= 1;
//                     else
//                         out_stream_ready <= (cycles % 4 == 0);
//                 end
//                 6: begin                                     // Пульсирующий
//                     if(cycles % 8 == 0)
//                         out_stream_ready <= 1;
//                     else
//                         out_stream_ready <= 0;
//                 end
//                 default: out_stream_ready <= 1;
//             endcase
            
//             cycles = cycles + 1;
            
//             // Проверка выходных данных если включена
//             if(check_enabled && out_stream_valid && out_stream_ready) begin
//                 received_count = received_count + 1;
//                 received_queue.push_back(out_stream_data);
                
//                 if(expected_queue.size() > 0) begin
//                     automatic reg [DATA_WIDTH-1:0] expected = expected_queue.pop_front();
//                     if(out_stream_data !== expected) begin
//                         $error("[TEST%0d][%t] DATA MISMATCH: Expected 0x%08h, Got 0x%08h", 
//                                test_id, $time, expected, out_stream_data);
//                         errors = errors + 1;
//                     end else begin
//                         $display("[TEST%0d][%t] VERIFIED[%0d]: 0x%08h OK", 
//                                  test_id, $time, received_count-1, out_stream_data);
//                     end
//                 end else begin
//                     $warning("[TEST%0d][%t] Unexpected data: 0x%08h", test_id, $time, out_stream_data);
//                     errors = errors + 1;
//                 end
//             end
//         end
        
//         out_stream_ready <= 0;
//         $display("[TEST%0d] Read %0d cycles, received %0d items", test_id, max_cycles, received_count);
//     endtask

//     // ========== ТЕСТОВЫЕ СЦЕНАРИИ ==========
    
//     // Тест 1: Непрерывная запись и чтение (ready всегда 1)
//     task test_continuous_flow();
//         test_id = 1;
//         $display("\n========================================");
//         $display("TEST %0d: CONTINUOUS FLOW (ready always 1)", test_id);
//         $display("========================================");
        
//         reset_counters();
        
//         fork
//             send_data(TEST_COUNT, 0, 0);      // Без пауз, инкремент
//             read_data(TEST_COUNT * 3, 0, 1);  // ready всегда 1
//         join
        
//         check_results();
//     endtask

//     // Тест 2: Пуш одного слова с ready на один такт
//     task test_single_word_ready_one_cycle();
//         test_id = 2;
//         $display("\n========================================");
//         $display("TEST %0d: SINGLE WORD with ready one cycle", test_id);
//         $display("========================================");
        
//         reset_counters();
//         out_stream_ready <= 0;
        
//         // Отправляем одно слово
//         @(posedge clk);
//         in_flow_data <= 32'hDEADBEEF;
//         expected_queue.push_back(32'hDEADBEEF);
//         in_flow_valid <= 1;
//         sent_count = 1;
//         $display("[TEST%0d][%t] SENT: 0xDEADBEEF", test_id, $time);
        
//         @(posedge clk);
//         in_flow_valid <= 0;
        
//         // Включаем ready на один такт
//         @(posedge clk);
//         @(posedge clk);
//         out_stream_ready <= 1;
//         $display("[TEST%0d][%t] READY enabled for one cycle", test_id, $time);
        
//         @(posedge clk);
//         out_stream_ready <= 0;
        
//         // Ждем окончания проверки
//         repeat (10) @(posedge clk);
        
//         check_results();
//     endtask

//     // Тест 3: Ready через такт
//     task test_ready_every_other_cycle();
//         test_id = 3;
//         $display("\n========================================");
//         $display("TEST %0d: READY EVERY OTHER CYCLE", test_id);
//         $display("========================================");
        
//         reset_counters();
        
//         fork
//             send_data(TEST_COUNT, 1, 0);      // Шаг 2, без пауз
//             read_data(TEST_COUNT * 4, 1, 1);  // Через такт
//         join
        
//         check_results();
//     endtask

//     // Тест 4: Случайные паузы на записи и чтении
//     task test_random_pauses();
//         test_id = 4;
//         $display("\n========================================");
//         $display("TEST %0d: RANDOM PAUSES on write and read", test_id);
//         $display("========================================");
        
//         reset_counters();
        
//         fork
//             send_data(TEST_COUNT, 2, 1);      // Случайные данные, случайные паузы
//             read_data(TEST_COUNT * 6, 3, 1);  // Случайный ready
//         join
        
//         check_results();
//     endtask

//     // Тест 5: Заполнение FIFO до края
//     task test_fifo_full();
//         test_id = 5;
//         $display("\n========================================");
//         $display("TEST %0d: FILL FIFO TO FULL", test_id);
//         $display("========================================");
        
//         reset_counters();
//         out_stream_ready <= 0;
        
//         // Отправляем данных больше чем глубина FIFO
//         send_data(FIFO_DEPTH + 5, 3, 0);     // Фиксированные данные, без пауз
        
//         // Проверяем usedw
//         $display("[TEST%0d] fifo_usedw = %0d (should be %0d)", 
//                  test_id, fifo_usedw, FIFO_DEPTH);
        
//         // Начинаем чтение
//         read_data(FIFO_DEPTH * 3, 2, 1);     // Каждый 3-й такт
        
//         check_results();
//     endtask

//     // Тест 6: Экстремальные паузы
//     task test_extreme_pauses();
//         test_id = 6;
//         $display("\n========================================");
//         $display("TEST %0d: EXTREME PAUSES", test_id);
//         $display("========================================");
        
//         reset_counters();
        
//         fork
//             send_data(TEST_COUNT, 2, 3);      // Длинные случайные паузы
//             read_data(TEST_COUNT * 8, 4, 1);  // Сложный паттерн ready
//         join
        
//         check_results();
//     endtask

//     // Тест 7: Смешанный сценарий - разные паттерны данных
//     task test_mixed_patterns();
//         test_id = 7;
//         $display("\n========================================");
//         $display("TEST %0d: MIXED DATA PATTERNS", test_id);
//         $display("========================================");
        
//         reset_counters();
        
//         // Отправляем разные паттерны данных
//         fork
//             begin
//                 send_data(5, 0, 0);   // Инкремент
//                 send_data(5, 1, 0);   // Шаг 2
//                 send_data(5, 2, 0);   // Случайные
//                 send_data(5, 3, 0);   // Фиксированные
//             end
//             read_data(TEST_COUNT * 4, 5, 1);  // Быстрое начало, потом медленно
//         join
        
//         check_results();
//     endtask

//     // Проверка результатов
//     task check_results();
//         $display("\n--- TEST %0d RESULTS ---", test_id);
//         $display("Sent: %0d, Received: %0d", sent_count, received_count);
        
//         if(sent_count == received_count) begin
//             $display("✅ All %0d data items received", received_count);
//         end else begin
//             $display("❌ DATA LOSS: Sent %0d, Received %0d", sent_count, received_count);
//             errors = errors + 1;
//         end
        
//         if(errors == 0) begin
//             $display("✅ TEST %0d PASSED", test_id);
//         end else begin
//             $display("❌ TEST %0d FAILED with %0d errors", test_id, errors);
//             $stop;
//         end
//         $display("========================================\n");
        
//         // Проверка оставшихся данных в очереди
//         if(expected_queue.size() > 0) begin
//             $display("⚠️  Warning: %0d items still in expected queue", expected_queue.size());
//         end
//     endtask

//     // ========== ЗАПУСК ТЕСТОВ ==========
//     initial begin
//         // Инициализация
//         in_flow_data <= 0;
//         in_flow_valid <= 0;
//         out_stream_ready <= 0;
//         reset <= 0;
        
//         // Сброс
//         #100_000;
//         reset <= 1;
//         #100_000;
//         reset <= 0;
        
//         repeat (5) @(posedge clk);
        
//         // Запуск всех тестов
//         test_continuous_flow();
//         #100_000;
        
//         // test_single_word_ready_one_cycle();
//         // #100_000;
        
//         test_ready_every_other_cycle();
//         #100_000;
        
//         test_random_pauses();
//         #100_000;
        
//         test_fifo_full();
//         #100_000;
        
//         test_extreme_pauses();
//         #100_000;
        
//         test_mixed_patterns();
//         #100_000;
        
//         // Итоговый отчет
//         $display("\n========================================");
//         $display("         FINAL TEST SUMMARY");
//         $display("========================================");
//         $display("Total errors: %0d", errors);
//         if(errors == 0) begin
//             $display("🎉 ALL TESTS PASSED!");
//         end else begin
//             $display("❌ SOME TESTS FAILED");
//         end
//         $display("========================================");
        
//         repeat (10) @(posedge clk);
//         $stop;
//     end

//     // Автоматическая проверка (дополнительная, используется в read_data)
//     always @(posedge clk) begin
//         // Дополнительная проверка на случай если read_data не используется
//         // (можно закомментировать если read_data всегда используется)
//     end

//     // Мониторинг состояния FIFO
//     always @(posedge clk) begin
//         if(fifo_usedw > FIFO_DEPTH) begin
//             $warning("[%t] FIFO OVERFLOW! usedw = %0d > %0d", $time, fifo_usedw, FIFO_DEPTH);
//         end
//     end

// endmodule