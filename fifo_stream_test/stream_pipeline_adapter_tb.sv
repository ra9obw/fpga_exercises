
`timescale 1 ps / 1 ps


module stream_pipeline_adapter_tb();
    parameter SYS_CLOCK_PERIOD = 10000;
    parameter WDTH = 32;
    parameter PIPE_DLY = 10;
    parameter STORAGE_DEPTH = 10;
    parameter USE_STREAM_FIFO = 0;
    parameter STREAM_FIFO_REGISTERED = 1;

    logic		clk;
    logic		reset;
    logic		        in_valid;
    wire 		        in_ready;
    logic [WDTH-1:0]    in_data;
    wire  [WDTH-1:0]    bb_data;
    wire		        out_valid;
    logic 		        out_ready;
    wire [WDTH-1:0]    out_data;

    // Очередь для ожидаемых данных
    reg [WDTH-1:0] expected_queue [$];
    reg [WDTH-1:0] sent_data [$];
    
    // Статистика
    integer sent_count = 0;
    integer out_valid_cnt = 0;
    integer received_count = 0;
    integer errors = 0;
    logic detailed_log;
    integer send_size;
    
    integer test_count = 1;
    integer successfull_tests = 0;
    integer failed_tests = 0;

    pipeline_test_box #(
        .WDTH(WDTH),
        .PIPE_DLY(PIPE_DLY)
    ) ppb (
        .clk    (clk),
        .reset  (reset),
        .in_data    (in_data),
        .out_data   (bb_data)
    );

    stream_pipeline_adapter#(
        .WDTH(WDTH),
        .PIPE_DLY(PIPE_DLY),
        .STORAGE_DEPTH(STORAGE_DEPTH),
        .USE_STREAM_FIFO(USE_STREAM_FIFO),
        .STREAM_FIFO_REGISTERED(STREAM_FIFO_REGISTERED)
    ) uut (
        .clk    (clk),
        .reset  (reset),
        .in_valid   (in_valid),
        .in_ready   (in_ready),
        .in_data    (bb_data),
        .out_valid  (out_valid),
        .out_ready  (out_ready),
        .out_data   (out_data)
    );


    function automatic [WDTH-1:0] random_data;
        integer seed;
        seed = $urandom();
        random_data = $urandom(seed) & 32'hFFFFFFFF;
    endfunction

    task automatic check_results();       // Проверка что все данные получены
        repeat (20) @(posedge clk);
        if(received_count != sent_count) begin
            $display("\n=== FAILURE: Sent %0d, Received %0d ===", sent_count, received_count);
        end
        
        if(errors > 0) begin
            $display("=== FAILURE: %0d errors detected ===", errors);
            failed_tests++;
        end else begin
            $display("\n=== SUCCESS: All %0d data items received correctly ===", received_count);
            successfull_tests++;
        end

        $display("Test completed at time %t", $time);
    endtask

    task automatic final_report(); 
        $display("\n=== TESTS DONE: %0d, SUCCESSFULL: %0d, FAILED: %0d ===", test_count, successfull_tests, failed_tests);
        if(test_count != successfull_tests + failed_tests )
            $warning("sum of sucessfull and falid tests not equals total test count!");
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


    task automatic push_data(
        input int push_cycles = PIPE_DLY,
        input int max_cycles = 0,
        input int start_value = 1234,
        input int flow_control = 0,
        input int random_gap = 0
    );

        int data_value = start_value;
        int cycle_count = 0;

        if(max_cycles == 0)
            max_cycles = 3*push_cycles;

        sent_count = 0;
        while ((sent_count < push_cycles) && (cycle_count < max_cycles)) begin
            @(posedge clk);
            cycle_count++;
            if(flow_control)
                #10
                if(!in_ready) begin
                    in_valid <= 0;
                    continue;
                end
            assert (in_ready) else $display("in should be ready %t", $time);
            in_data <= data_value;
            in_valid <= 1;
            expected_queue.push_back(data_value);
            #10
            data_value++;
            sent_count++; 
            if(random_gap) begin
                if($urandom() % 3 == 0) begin
                    @(posedge clk);
                    in_valid <= 0;
                    repeat ($urandom() % 5) @(posedge clk);
                end
            end
        end
        @(posedge clk);
        in_valid <= 0;
    endtask

    task automatic drive_out_ready(
        input int push_cycles = PIPE_DLY,
        input int max_cycles = 0,
        input int before_delay = 0,
        input int random_gap = 0
    );

        int cycle_count = 0;

        if(max_cycles == 0)
            max_cycles = 3*push_cycles;

        out_valid_cnt <= 0;
        repeat (before_delay) @(posedge clk);
        while ((out_valid_cnt < push_cycles) && (cycle_count < max_cycles)) begin
            @(posedge clk);
            cycle_count++;
            out_ready <= 1;
            #20
            if(out_valid)
                out_valid_cnt++;
            if(random_gap) begin
                if($urandom() % 3 == 0) begin
                    @(posedge clk);
                    out_ready <= 0;
                    repeat ($urandom() % 5) @(posedge clk);
                end
            end
        end
        @(posedge clk);
        out_ready <= 0;
    endtask

    initial begin
        clk = 0;
        forever #(SYS_CLOCK_PERIOD/2) clk = ~clk;
    end


    // Основной тест
    initial begin
       
        // Инициализация
        detailed_log = 1'b0;
        in_valid <= 0;
        in_data <= 0;
        out_ready <= 0;

        reset <= 0;
        
        // Сброс
        #100_000;
        reset <= 1;
        #100_000;
        reset <= 0;

        repeat (10) @(posedge clk);
        $display("\n=== TEST%d push PIPE_DLY items, wait, set out ready for PIPE_DLY cycles ===", test_count);
        #10
        assert (in_ready) else $display("in should be ready %t", $time);

        push_data(PIPE_DLY, 3*PIPE_DLY, 1000);

        #10
        assert (!in_ready) else $display("in should be not ready %t", $time);
        assert (out_valid) else $display("out should be valid %t", $time);
        
        drive_out_ready(PIPE_DLY, 3*PIPE_DLY, 2000);
        #10
        assert (!out_valid) else $display("out should not be valid %t", $time);
        
        check_results();
        reset_counters();
        

        test_count++;
        repeat (10) @(posedge clk);
        $display("\n=== TEST%d push PIPE_DLY items, no wait, set out ready for PIPE_DLY cycles ===", test_count);
        #10
        assert (in_ready) else $display("in should be ready %t", $time);

        fork
            push_data(PIPE_DLY, 3*PIPE_DLY, 3000);
            drive_out_ready(PIPE_DLY, 3*PIPE_DLY, PIPE_DLY);
        join
        repeat (10) @(posedge clk);
        check_results();
        reset_counters();


        test_count++;
        repeat (10) @(posedge clk);
        $display("\n=== TEST%d push PIPE_DLY items, wait 1 cycle, set out ready for PIPE_DLY cycles ===", test_count);
        #10
        assert (in_ready) else $display("in should be ready %t", $time);

        fork
            push_data(PIPE_DLY, 3*PIPE_DLY, 4000);
            drive_out_ready(PIPE_DLY, 3*PIPE_DLY, PIPE_DLY+1);
        join
        repeat (10) @(posedge clk);
        check_results();
        reset_counters();



        test_count++;
        repeat (10) @(posedge clk);
        $display("\n=== TEST%d push PIPE_DLY items, wait 2 cycles, set out ready for PIPE_DLY cycles ===", test_count);
        #10
        assert (in_ready) else $display("in should be ready %t", $time);

        fork
            push_data(PIPE_DLY, 3*PIPE_DLY, 5000);
            drive_out_ready(PIPE_DLY, 3*PIPE_DLY, PIPE_DLY+2);
        join
        repeat (10) @(posedge clk);
        check_results();
        reset_counters();




        test_count++;
        repeat (10) @(posedge clk);
        $display("\n=== TEST%d push PIPE_DLY items, wait 3 cycles, set out ready for PIPE_DLY cycles ===", test_count);
        #10
        assert (in_ready) else $display("in should be ready %t", $time);

        fork
            push_data(PIPE_DLY, 3*PIPE_DLY, 6000);
            drive_out_ready(PIPE_DLY, 3*PIPE_DLY, PIPE_DLY+3);
        join
        repeat (10) @(posedge clk);
        check_results();
        reset_counters();




        test_count++;
        repeat (10) @(posedge clk);
        $display("\n=== TEST%d push PIPE_DLY items, wait 4 cycles, set out ready for PIPE_DLY cycles ===", test_count);
        #10
        assert (in_ready) else $display("in should be ready %t", $time);

        fork
            push_data(PIPE_DLY, 3*PIPE_DLY, 7000);
            drive_out_ready(PIPE_DLY, 3*PIPE_DLY, PIPE_DLY+4);
        join
        repeat (10) @(posedge clk);
        check_results();
        reset_counters();


        test_count++;
        repeat (10) @(posedge clk);
        $display("\n=== TEST%d push PIPE_DLY items, wait 1 cycles, set out ready for PIPE_DLY and insert one not ready in middle ===", test_count);
        #10
        assert (in_ready) else $display("in should be ready %t", $time);
        
        push_data(PIPE_DLY, 3*PIPE_DLY, 8000);
        drive_out_ready(PIPE_DLY/2, 3*PIPE_DLY, PIPE_DLY);
        drive_out_ready(PIPE_DLY/2, 3*PIPE_DLY, 1);
        
        repeat (20) @(posedge clk);
        check_results();
        reset_counters();

    
        test_count++;
        repeat (10) @(posedge clk);
        $display("\n=== TEST%d push PIPE_DLY items, wait 1 cycles, set out ready for PIPE_DLY and insert 2 not ready in middle ===", test_count);
        #10
        assert (in_ready) else $display("in should be ready %t", $time);
        
        push_data(PIPE_DLY, 3*PIPE_DLY, 9000);
        drive_out_ready(PIPE_DLY/2, 3*PIPE_DLY, PIPE_DLY);
        drive_out_ready(PIPE_DLY/2, 3*PIPE_DLY, 2);
        
        repeat (20) @(posedge clk);
        check_results();
        reset_counters();



        test_count++;
        repeat (10) @(posedge clk);
        $display("\n=== TEST%d push PIPE_DLY items, wait 1 cycles, set out ready for PIPE_DLY and insert 3 not ready in middle ===", test_count);
        #10
        assert (in_ready) else $display("in should be ready %t", $time);
        
        push_data(PIPE_DLY, 3*PIPE_DLY, 10000);
        drive_out_ready(PIPE_DLY/2, 3*PIPE_DLY, PIPE_DLY);
        drive_out_ready(PIPE_DLY/2, 3*PIPE_DLY, 3);
        
        repeat (20) @(posedge clk);
        check_results();
        reset_counters();



        test_count++;
        repeat (10) @(posedge clk);
        $display("\n=== TEST%d push PIPE_DLY items, wait 1 cycles, set out ready for PIPE_DLY and insert 4 not ready in middle ===", test_count);
        #10
        assert (in_ready) else $display("in should be ready %t", $time);
        
        push_data(PIPE_DLY, 3*PIPE_DLY, 11000);
        drive_out_ready(PIPE_DLY/2, 3*PIPE_DLY, PIPE_DLY);
        drive_out_ready(PIPE_DLY/2, 3*PIPE_DLY, 4);
        
        repeat (20) @(posedge clk);
        check_results();
        reset_counters();



        repeat (10) @(posedge clk);
        send_size = 2*PIPE_DLY;
        test_count++;
        $display("\n=== TEST%d push %d items, out is ready all time ===", test_count, send_size);
        out_ready <= 1;
        #10
        assert (in_ready) else $display("in should be ready %t", $time);
        push_data(send_size);
        
        check_results();
        reset_counters();


        repeat (10) @(posedge clk);
        send_size = 2*PIPE_DLY;
        test_count++;
        $display("\n=== TEST%d push %d items with gaps, out is ready all time ===", test_count, send_size);
        out_ready <= 1;
        #10
        assert (in_ready) else $display("in should be ready %t", $time);
        push_data(send_size, .random_gap(1) );
        
        check_results();
        reset_counters();

        send_size = 5*PIPE_DLY;
        test_count++;
        $display("\n=== TEST%d push %d items with gaps, out is ready all time ===", test_count, send_size);
        out_ready <= 1;
        #10
        assert (in_ready) else $display("in should be ready %t", $time);

        push_data(send_size, 3*send_size, 1000, 1, 1);
        repeat (10) @(posedge clk);
        check_results();
        reset_counters();

        send_size = 5*PIPE_DLY;
        test_count++;
        $display("\n=== TEST%d push %d items with gaps, wait PIPE_DLY cycles, set out ready with gaps ===", test_count, send_size);
        out_ready <= 0;
        #10
        assert (in_ready) else $display("in should be ready %t", $time);

        fork
            push_data(send_size, 3*send_size, 1000, 1, 1);
            drive_out_ready(send_size, 3*send_size, 2.5*STORAGE_DEPTH, 1);
        join
        
        repeat (10) @(posedge clk);
        check_results();
        reset_counters();



        send_size = 2*PIPE_DLY;
        test_count++;
        $display("\n=== TEST%d push %d items with no gaps but with flow control, out is ready with gaps ===", test_count, send_size);
        out_ready <= 1;
        #10
        assert (in_ready) else $display("in should be ready %t", $time);
        fork
            push_data(send_size, 3*send_size, 1000, 1, 0);
            drive_out_ready(send_size, 3*send_size, 2, 1);
        join
        repeat (10) @(posedge clk);
        check_results();
        reset_counters();


        #1000
        final_report(); 
        $stop;
    end



    // Автоматическая проверка выходных данных
    always @(posedge clk) begin
        if(out_valid && out_ready) begin
            received_count = received_count + 1;
            
            // Проверяем соответствие данных
            if(expected_queue.size() > 0) begin
                automatic reg [WDTH-1:0] expected = expected_queue.pop_front();
                
                if(out_data !== expected) begin
                    $error("[%t] DATA MISMATCH: Expected 0x%08h, Got 0x%08h", 
                           $time, expected, out_data);
                    errors = errors + 1;
                    $pause;
                end else begin
                    if(detailed_log) $display("[%t] VERIFIED[%0d]: 0x%08h OK", $time, received_count-1, out_data);
                end
            end else begin
                $warning("[%t] Unexpected data: 0x%08h", $time, out_data);
                errors = errors + 1;
            end
        end
    end



endmodule
