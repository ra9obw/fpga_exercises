module fifo_stream_test#(    
    parameter WDTH = 160,
    parameter DEPTH = 200,
    parameter REGISTERED = 0
)(
	input		clk,
	input		reset,
    input  [WDTH-1:0]   in_data,
    input           in_valid,
    output [7:0]    fifo_usedw,
    output          overflow,
    output		    out_valid,
	input 		    out_ready,
	output [WDTH-1:0]	out_data
);

    wire            fifo_empty;
    wire            fifo_read_req;
    wire   [31:0]   fifo_q;
    
    rcv_fifo rcv_fifo_ch(
        .clock  (clk),
        .aclr   (reset),
        .data   (in_data),
        .wrreq  (in_valid),
        .rdreq  (fifo_read_req),
        .empty  (fifo_empty),
        .q      (fifo_q),
        .usedw  (fifo_usedw)
    );

    wire		    tmp_stream_valid;
	wire 		    tmp_stream_ready;
	wire [31:0]	    tmp_stream_data;

    fifo_pop_stream_adapter pop_st_adapter(
        .clk    (clk),
        .reset  (reset),
        .fifo_empty     (fifo_empty),
        .fifo_read_req  (fifo_read_req),
        .fifo_q         (fifo_q),
        .out_valid   (tmp_stream_valid),
        .out_ready   (tmp_stream_ready),
        .out_data    (tmp_stream_data)
    );
generate
    if(REGISTERED) begin
        stream_pipe fifo_st_pipe(
            .clk    (clk),
            .reset  (reset),
            .in_valid   (tmp_stream_valid),
            .in_ready   (tmp_stream_ready),
            .in_data    (tmp_stream_data),
            .out_valid   (out_valid),
            .out_ready   (out_ready),
            .out_data    (out_data)
        );        
    end else begin
        assign out_valid = tmp_stream_valid;
        assign out_data = tmp_stream_data;
        assign tmp_stream_ready = out_ready;
    end
endgenerate
endmodule


module fifo_pop_stream_adapter#(
    parameter WDTH = 32
)(
	input		clk,
	input		reset,
    input wire          fifo_empty,
    output wire         fifo_read_req,
    input [WDTH-1:0]    fifo_q,
    output		        out_valid,
	input 		        out_ready,
	output [WDTH-1:0]   out_data
);

    reg [$size(fifo_q)-1:0] adapter_data;
    reg adapter_valid;
    wire fifo_read_ready;
    wire fifo_read_valid;

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            adapter_data <= 0;
            adapter_valid <= 1'b0;
        end else begin
            if(fifo_read_ready) 
                adapter_valid <= fifo_read_valid;

            if(out_valid & out_ready)
                adapter_data <= fifo_q;
        end
    end

    assign fifo_read_ready = out_ready | !adapter_valid;
    assign fifo_read_valid = !fifo_empty;
    
    assign fifo_read_req = fifo_read_valid & fifo_read_ready;
    assign out_valid = adapter_valid;
    assign out_data  = out_ready ? fifo_q : adapter_data;

endmodule


module stream_pipe#(
    parameter WDTH = 32
)(
	input		clk,
	input		reset,
    input		        in_valid,
	output 		        in_ready,
	input [WDTH-1:0]    in_data,
    output		        out_valid,
	input 		        out_ready,
	output [WDTH-1:0]   out_data
);

    reg [WDTH-1:0] buffer_data;
    reg buffer_valid;

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            buffer_data <= 0;
            buffer_valid <= 0;
        end else begin
            if(in_valid & in_ready)
                buffer_data <= in_data;
            if(in_ready) 
                buffer_valid <= in_valid;
        end
    end

    assign in_ready = (out_ready || !buffer_valid);
    assign out_data = buffer_data;
    assign out_valid = buffer_valid;

endmodule

//###############################################
//######## TASK3 PIPELINE STREAM ADAPTER ########
//###############################################

module stream_pipeline_adapter_test#(    
    parameter WDTH = 160,
    parameter PIPE_DLY = 200,
    parameter STORAGE_DEPTH = 200,
    parameter USE_STREAM_FIFO = 0
)(
    input		clk,
    input		reset,
    input		        in_valid,
    output 		        in_ready,
    input [WDTH-1:0]    in_data,
    output		        out_valid,
    input 		        out_ready,
    output [WDTH-1:0]   out_data
);

    generate
        if(STORAGE_DEPTH < PIPE_DLY) 
            initial $error("STORAGE_DEPTH [%0d] SHOULD BE not less then PIPE_DLY [%0d]", STORAGE_DEPTH, PIPE_DLYs);
    endgenerate

    wire  [WDTH-1:0]    bb_data;

    pipeline_test_box #(
        .WDTH(WDTH),
        .PIPE_DLY(PIPE_DLY)
    ) ppb_inst (
        .clk    (clk),
        .reset  (reset),
        .in_data    (in_data),
        .out_data   (bb_data)
    );

    stream_pipeline_adapter#(
        .WDTH(WDTH),
        .STORAGE_DEPTH(STORAGE_DEPTH),
        .USE_STREAM_FIFO(USE_STREAM_FIFO),
        .STREAM_FIFO_REGISTERED(1)
    ) sta_inst (
        .clk    (clk),
        .reset  (reset),
        .in_valid   (in_valid),
        .in_ready   (in_ready),
        .in_data    (bb_data),
        .out_valid  (out_valid),
        .out_ready  (out_ready),
        .out_data   (out_data)
    );
endmodule


module stream_pipeline_adapter#(
    parameter WDTH = 32,
    parameter PIPE_DLY = 10,
    parameter STORAGE_DEPTH = 10,
    parameter USE_STREAM_FIFO = 1,
    parameter STREAM_FIFO_REGISTERED = 1
)(
	input		clk,
	input		reset,
    input		        in_valid,
	output 		        in_ready,
	input [WDTH-1:0]    in_data,
    output  	        out_valid,
	input 		        out_ready,
	output [WDTH-1:0]   out_data
);

    localparam PIPE_CNT_BASE = $clog2(STORAGE_DEPTH+1);

    generate
        if(STORAGE_DEPTH < 1) 
            initial $error("PIPE_DELAY SHOULD BE 1 or more: %0d", STORAGE_DEPTH);
    endgenerate

    wire in_fire;
    wire out_fire;

    logic [PIPE_DLY-1:0] in_valid_pipe;
    logic [PIPE_CNT_BASE-1:0] pipe_load_cnt;

    wire pipe_is_full;
    wire pipe_is_empty;
    wire valid_pipe_out;

    wire [WDTH-1:0] pipe_data_mux;

    assign in_fire = in_ready & in_valid;

    assign pipe_is_full = (pipe_load_cnt == STORAGE_DEPTH);
    assign pipe_is_empty = (pipe_load_cnt == 0);
    assign valid_pipe_out = in_valid_pipe[$size(in_valid_pipe)-1];
    assign out_fire = out_ready & out_valid;

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            in_valid_pipe <= 0;
            pipe_load_cnt <= 0;
        end else begin
            in_valid_pipe <= {in_valid_pipe[$size(in_valid_pipe)-2:0], in_fire};
            if(in_fire & !out_fire & !pipe_is_full) 
                pipe_load_cnt <= pipe_load_cnt + 1;
            else if(!in_fire & out_fire & !pipe_is_empty) 
                pipe_load_cnt <= pipe_load_cnt - 1;
        end
    end

generate
    if(USE_STREAM_FIFO) begin
        fifo_stream_test
        #(    
            .WDTH(WDTH),
            .DEPTH(STORAGE_DEPTH),
            .REGISTERED(1)
        )stream_fifo_inst(
            .clk         (clk),
            .reset       (reset),
            .in_data     (in_data),
            .in_valid    (valid_pipe_out),
            .out_valid   (out_valid),
            .out_ready   (out_ready),
            .out_data    (out_data)
        );
    end else begin
        // pipeline_adapter_mem_storage
        pipeline_adapter_2ticks_mem_storage
        // pipeline_adapter_shiftreg_storage
        #(
            .WDTH(WDTH),
            .DEPTH(STORAGE_DEPTH)
        ) storage_int (
            .clk        (clk),
            .reset      (reset),
            .in_data    (in_data),
            .in_valid   (valid_pipe_out),
            .out_ready  (out_ready),
            .out_data   (out_data),
            .out_valid  (out_valid)
        );
    end
endgenerate

    assign in_ready = out_ready || !pipe_is_full;
    
endmodule


module pipeline_adapter_mem_storage#(
    parameter WDTH = 32,
    parameter DEPTH = 10
)(
    input		        clk,
	input		        reset,
    input  [WDTH-1:0]   in_data,
    input               in_valid,
    input               out_ready,
    output logic [WDTH-1:0]   out_data,
    output logic        out_valid
);

    `define INCR_WRAP(reg, max) (reg == max) ? 0 : reg + 1

    localparam ADDR_WDTH = $clog2(DEPTH);

    logic [ADDR_WDTH-1:0] wr_cnt;
    logic [ADDR_WDTH-1:0] rd_cnt;

    logic [WDTH-1:0] bypass_data;

    logic [$clog2(DEPTH):0] item_count;

    wire empty;
    assign empty = (item_count == 0);

    logic out_fire;
    assign out_fire = (out_valid & out_ready);

    wire [WDTH-1:0] mem_rdata;

    logic mem_valid;

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            wr_cnt <= 0;
            rd_cnt <= 1;
            bypass_data <= 0;
            item_count <= 0;
            mem_valid <= 0;
    
        end else begin

            if(out_fire & !empty) begin
                rd_cnt <= `INCR_WRAP(rd_cnt, DEPTH-1);
            end
            if(in_valid & (!out_ready || !empty)) begin
                wr_cnt <= `INCR_WRAP(wr_cnt, DEPTH-1);
            end
            
            case({in_valid, out_fire})
                2'b10: item_count <= item_count + 1;
                2'b01: item_count <= item_count - 1;
                2'b11: item_count <= item_count;
                default: item_count <= item_count;
            endcase

            mem_valid <= out_fire & (item_count > 1);

            if(in_valid & (empty || (out_fire & (item_count == 1))))
                bypass_data <= in_data;
            else if(mem_valid)
                bypass_data <= mem_rdata;
        end
    end

    simple_dual_port_ram #(
        .DATA_WIDTH(WDTH),
        .ADDR_WIDTH(ADDR_WDTH)
    ) dp_ram (
        .clk(clk),
        .we(in_valid),
        .write_addr(wr_cnt),
        .read_addr(rd_cnt),
        .write_data(in_data),
        .read_data(mem_rdata)
    );

    always_comb begin
        out_valid = (in_valid & empty) || !empty;
        out_data = empty ? in_data : (mem_valid ? mem_rdata : bypass_data );
    end

endmodule


module pipeline_adapter_2ticks_mem_storage#(
    parameter WDTH = 32,
    parameter DEPTH = 10
)(
    input		        clk,
	input		        reset,
    input  [WDTH-1:0]   in_data,
    input               in_valid,
    input               out_ready,
    output logic [WDTH-1:0]   out_data,
    output logic        out_valid
);

    generate
        if(DEPTH < 2) 
            initial $error("MEM DEPTH should be 2 or more: %0d", DEPTH);
    endgenerate

    `define INCR_WRAP(reg, max) (reg == max) ? 0 : reg + 1
    `define SHIFT_UD(reg) reg[$size(reg)-1:0]

    localparam ADDR_WDTH = $clog2(DEPTH);
    localparam MEM_PIPE_DELAY = 2;

    logic [ADDR_WDTH-1:0] wr_cnt;
    logic [ADDR_WDTH-1:0] rd_cnt;

    logic [$clog2(DEPTH):0] items;

    wire empty;
    assign empty = (items == 0);

    logic out_fire;
    assign out_fire = (out_valid & out_ready);

    wire [WDTH-1:0] mem_rdata;

    wire inc_items;
    wire dec_items;

    assign inc_items = in_valid & !out_fire;
    assign dec_items = !in_valid & out_fire;

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            wr_cnt <= 0;
            rd_cnt <= 2;
            items <= 0;
        end else begin
            if(out_fire & !empty) begin
                rd_cnt <= `INCR_WRAP(rd_cnt, DEPTH-1);
            end
            if(in_valid & (!out_ready || !empty)) begin
                wr_cnt <= `INCR_WRAP(wr_cnt, DEPTH-1);
            end
            
            case({in_valid, out_fire})
                2'b10: items <= items + 1;
                2'b01: items <= items - 1;
                2'b11: items <= items;
                default: items <= items;
            endcase
            // items <= items + inc_items - dec_items;

        end
    end

    // simple_dual_port_ram #(
    //     .DATA_WIDTH(WDTH),
    //     .ADDR_WIDTH(ADDR_WDTH),
    //     .OUTPUT_REGISTERED(1)
    // ) dp_ram (
    //     .clk(clk),
    //     .we(in_valid),
    //     .write_addr(wr_cnt),
    //     .read_addr(rd_cnt),
    //     .write_data(in_data),
    //     .read_data(mem_rdata)
    // );
    true_dp_ram dp_ram (
        .clock(clk),
        .data(in_data),
        .rdaddress(rd_cnt),
        .wraddress(wr_cnt),
        .wren(in_valid),
        .q(mem_rdata)
    );

    localparam HP_WDTH =  $clog2(MEM_PIPE_DELAY);
    logic [HP_WDTH-1:0] head_pointer;

    typedef enum logic [3:0] {
        STREAM, PAUSE, STALL, RESUME, MEMORY, MEM_BREAK, RELEASE
    } state_t;

    state_t current_state, next_state;


    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            current_state <= STREAM;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;
        case (current_state)
            STREAM: begin
                if(inc_items)
                    next_state = PAUSE;
            end
            PAUSE: begin
                if((head_pointer == (MEM_PIPE_DELAY-1)) & inc_items)
                    next_state = STALL;
                else if((head_pointer == 0) & dec_items)
                    next_state = STREAM;
            end
            STALL: begin
                if(out_fire)
                    next_state = RESUME;
            end
            RESUME: begin
                if((head_pointer == MEM_PIPE_DELAY-1) & !out_ready)
                    next_state = STALL;
                else if((head_pointer == 0) & out_ready)
                    next_state = MEMORY;
            end
            MEMORY: begin
                if((items == (MEM_PIPE_DELAY+1)) & dec_items)
                    next_state = RELEASE;
                else if(!out_ready)
                    next_state = MEM_BREAK;
            end
            MEM_BREAK: begin
                if((head_pointer == MEM_PIPE_DELAY-1) & dec_items)
                    next_state = STALL;
                else if((head_pointer == 0) & out_ready)
                    next_state = MEMORY;
            end
            RELEASE: begin
                if((items == 1) & out_ready)
                    next_state = STREAM;
                else if(!out_ready)
                    next_state = MEM_BREAK;
            end
            default: begin
                next_state = STREAM;
            end
        endcase
    end


    logic [WDTH-1:0] head_data[MEM_PIPE_DELAY];
    logic [WDTH-1:0] tail_data[MEM_PIPE_DELAY];
    logic [MEM_PIPE_DELAY-1:0] mem_readed;

    wire shift_mem_data;
    assign shift_mem_data = (current_state != STREAM) & (current_state != PAUSE);

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            head_pointer <= 0;
            mem_readed <= 0;
            for(int i=0; i<MEM_PIPE_DELAY; i++) begin
                head_data[i] <= 0;
                tail_data[i] <= 0;
            end
        end else begin
            mem_readed <= {`SHIFT_UD(mem_readed), out_fire & (items > MEM_PIPE_DELAY)};
            //
            if(in_valid & (current_state == STREAM) || ((next_state == PAUSE)  )) begin
                head_data[0] <= in_data;
                for(int i=1; i<MEM_PIPE_DELAY; i++) begin
                    head_data[i] <= head_data[i-1];
                end
            end else if(out_fire & shift_mem_data) begin
                head_data[0] <= mem_rdata;
                for(int i=1; i<MEM_PIPE_DELAY; i++) begin
                    head_data[i] <= head_data[i-1];
                end
            end
            //
            if(in_valid) begin
                tail_data[0] <= in_data;
                for(int i=1; i<MEM_PIPE_DELAY; i++) begin
                    tail_data[i] <= tail_data[i-1];
                end
            end
            //head_pointer
            //насколько глубоко по конвейерной задержке сдвинулись
            case(current_state)
                STREAM: begin
                    head_pointer <= 0;
                end
                PAUSE: begin
                    if(inc_items & (head_pointer < (MEM_PIPE_DELAY-1))) head_pointer <= head_pointer + 1;
                    else if(dec_items & (head_pointer > 0)) head_pointer <= head_pointer - 1;
                end
                STALL: begin
                    head_pointer <= MEM_PIPE_DELAY-1;
                end
                RESUME: begin
                    if(!out_ready) head_pointer <= head_pointer + 1;
                    else if(out_ready) head_pointer <= head_pointer - 1;
                end
                MEMORY: begin
                    head_pointer <= 0;
                end
                MEM_BREAK: begin
                    if(!out_ready) head_pointer <= head_pointer + 1;
                    else head_pointer <= head_pointer - 1;
                end
                RELEASE: begin
                    if(dec_items) head_pointer <= head_pointer + 1;
                end
                default: begin
                    
                end            
            endcase
    
        end
    end

    always_comb begin
        out_valid = (in_valid & empty) || !empty;
        // out_data = empty ? in_data : (&mem_readed ? mem_rdata : head_data[head_pointer]);
        case(current_state)
            STREAM: begin
                out_data = in_data;
            end
            PAUSE: begin
                out_data = head_data[head_pointer];
            end
            STALL: begin
                out_data = head_data[head_pointer];
            end
            RESUME: begin
                out_data = head_data[head_pointer];
            end
            MEMORY: begin
                out_data = mem_rdata;
            end
            MEM_BREAK: begin
                out_data = head_data[head_pointer];
            end
            RELEASE: begin
                out_data = tail_data[MEM_PIPE_DELAY-1-head_pointer];
            end
            default: begin        
            end
        endcase
    end

endmodule


module pipeline_adapter_shiftreg_storage#(
    parameter WDTH = 32,
    parameter DEPTH = 10
)(
    input		        clk,
	input		        reset,
    input  [WDTH-1:0]   in_data,
    input               in_valid,
    input               out_ready,
    output [WDTH-1:0]   out_data,
    output              out_valid
);

    localparam PIPE_CNT_BASE = $clog2(DEPTH+1);

    logic [WDTH-1:0] data[DEPTH];
    logic [PIPE_CNT_BASE-1:0] cnt;
    wire full;
    wire empty;

    wire [WDTH-1:0] shift_storage_head;

    assign empty = (cnt == 0);
    assign full  = (cnt == (DEPTH));
    assign shift_storage_head = empty ? 0 : data[cnt-1];

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            cnt <= 0;
            for (int i = 0; i<DEPTH; i=i+1) begin
                data[i] <= 0;
            end
        end else begin
            if(!full & !out_ready & in_valid)
                cnt <= cnt + 1;
            else if(!empty & out_ready & !in_valid)
                cnt <= cnt - 1;
            if(in_valid) begin
                data[0] <= in_data;
                for (int i = 1; i<DEPTH; i=i+1) begin
                    data[i] <= data[i-1];
                end
            end
        end
    end

    assign out_data = (empty) ? in_data : shift_storage_head;
    assign out_valid = (empty & in_valid) || !empty;

endmodule


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
