
`timescale 1 ps / 1 ps

module pipeline_test_box
#(
    parameter WDTH = 32,
    parameter PIPE_DLY = 10
)(
	input		clk,
	input		reset,
	input [WDTH-1:0]    in_data,
	output [WDTH-1:0]   out_data
);
    logic [WDTH-1:0] shift_storage_data[PIPE_DLY];
    always_ff @(posedge clk or posedge reset)
        if(reset)
            for (int i = 0; i<PIPE_DLY; i=i+1)
                shift_storage_data[i] <= 0;
        else begin
            shift_storage_data[0] <= in_data;
            for (int i = 1; i<PIPE_DLY; i=i+1)
                shift_storage_data[i] <= shift_storage_data[i-1];
        end
    assign out_data = shift_storage_data[PIPE_DLY-1];
endmodule

module stream_pipeline_adapter_tb();
    parameter SYS_CLOCK_PERIOD = 10000;
    parameter WDTH = 32;
    parameter PIPE_DLY = 10;

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
    integer received_count = 0;
    integer errors = 0;
    logic detailed_log;

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
        .PIPE_DLY(PIPE_DLY)
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


    initial begin
        clk = 0;
        forever #(SYS_CLOCK_PERIOD/2) clk = ~clk;
    end

int start_value = 1234;
int data_value = start_value;


    // Основной тест
    initial begin
       
        // Инициализация
        detailed_log = 1'b1;
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
        assert (in_ready) else $display("in should be ready %t", $time);

        while (sent_count < PIPE_DLY) begin
            @(posedge clk);
            in_data <= data_value;
            in_valid <= 1;
            expected_queue.push_back(data_value);
            #10
            data_value++;
            sent_count++; 
            assert (in_ready) else $display("in should be ready %t", $time);
        end
        @(posedge clk);
        in_valid <= 0;
        assert (!in_ready) else $display("in should be not ready ready %t", $time);
        
        sent_count <= 0;
        repeat (10) @(posedge clk);
        while (sent_count < PIPE_DLY) begin
            @(posedge clk);
            out_ready <= 1;
            sent_count++;
        end
        @(posedge clk);
        out_ready <= 0;
        #1000
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
