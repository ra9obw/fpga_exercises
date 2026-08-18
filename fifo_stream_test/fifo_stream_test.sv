module fifo_stream_test#(    
    parameter WDTH = 160,
    parameter PIPE_DLY = 200,
    parameter REGISTERED = 0
)(
	input		clk,
	input		reset,
    input  [WDTH-1:0]   in_flow_data,
    input           in_flow_valid,
    // output [7:0]    fifo_usedw,
    output          overflow,
    output		    out_stream_valid,
	input 		    out_stream_ready,
	output [WDTH-1:0]	out_stream_data
);

    wire            fifo_empty;
    wire            fifo_read_req;
    wire   [31:0]   fifo_q;
    
    rcv_fifo rcv_fifo_ch(
        .clock  (clk),
        .aclr   (reset),
        .data   (in_flow_data),
        .wrreq  (in_flow_valid),
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
            .out_valid   (out_stream_valid),
            .out_ready   (out_stream_ready),
            .out_data    (out_stream_data)
        );        
    end else begin
        assign out_stream_valid = tmp_stream_valid;
        assign out_stream_data = tmp_stream_data;
        assign tmp_stream_ready = out_stream_ready;
    end
endgenerate


endmodule

module stream_pipeline_adapter_test#(    
    parameter WDTH = 32,
    parameter PIPE_DLY = 10
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
        .PIPE_DLY(PIPE_DLY)
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


module stream_pipeline_adapter#(
    parameter WDTH = 32,
    parameter PIPE_DLY = 10
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

    localparam PIPE_CNT_BASE = $clog2(PIPE_DLY+1);

    generate
        if(PIPE_DLY < 1) 
            initial $error("PIPE_DELAY SHOULD BE 1 or more: %0d", PIPE_DLY);
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

    assign pipe_is_full = (pipe_load_cnt == PIPE_DLY);
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

    wire shift_storage_valid;
    wire [WDTH-1:0] shift_storage_head;

    pipeline_adapter_mem_storage #(
        .WDTH(WDTH),
        .PIPE_DLY(PIPE_DLY)
    ) storage_int (
        .clk        (clk),
        .reset      (reset),
        .in_data    (in_data),
        .in_valid   (valid_pipe_out),
        .out_ready  (out_ready),
        .out_data   (shift_storage_head),
        .out_valid  (shift_storage_valid)
    );

    assign in_ready = out_ready || !pipe_is_full;
    assign out_data = (out_ready & !shift_storage_valid) ? in_data : shift_storage_head;
    assign out_valid = (out_ready & valid_pipe_out) || shift_storage_valid;

endmodule

module pipeline_adapter_mem_storage#(
    parameter WDTH = 32,
    parameter PIPE_DLY = 10
)(
    input		        clk,
	input		        reset,
    input  [WDTH-1:0]   in_data,
    input               in_valid,
    input               out_ready,
    output [WDTH-1:0]   out_data,
    output              out_valid
);

    `define INCR_WRAP(reg, max) \
        reg <= (reg == max) ? 0 : reg + 1

    localparam PIPE_CNT_BASE = $clog2(PIPE_DLY);

    logic [WDTH-1:0] data[PIPE_DLY];
    logic [PIPE_CNT_BASE-1:0] wr_cnt;
    logic [PIPE_CNT_BASE-1:0] rd_cnt;

    assign out_data = data[rd_cnt];

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            wr_cnt <= 0;
            rd_cnt <= 0;
            for (int i = 0; i<PIPE_DLY; i=i+1) begin
                data[i] <= 0;
            end
        end else begin
            if((out_valid || in_valid) & out_ready) 
                `INCR_WRAP(rd_cnt, PIPE_DLY-1);
            if(in_valid) begin
                `INCR_WRAP(wr_cnt, PIPE_DLY-1);
                data[wr_cnt] <= in_data;
            end
        end
    end

    assign out_valid = (wr_cnt != rd_cnt);

endmodule


module pipeline_adapter_storage#(
    parameter WDTH = 32,
    parameter PIPE_DLY = 10
)(
    input		        clk,
	input		        reset,
    input  [WDTH-1:0]   in_data,
    input               in_valid,
    input               out_ready,
    output [WDTH-1:0]   out_data,
    output              out_valid
);

    localparam PIPE_CNT_BASE = $clog2(PIPE_DLY+1);

    logic [WDTH-1:0] data[PIPE_DLY];
    logic [PIPE_CNT_BASE-1:0] cnt;
    wire full;
    wire empty;

    assign empty = (cnt == 0);
    assign full  = (cnt == (PIPE_DLY));
    assign out_data = empty ? 0 : data[cnt-1];

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            cnt <= 0;
            for (int i = 0; i<PIPE_DLY; i=i+1) begin
                data[i] <= 0;
            end
        end else begin
            if(!full & !out_ready & in_valid)
                cnt <= cnt + 1;
            else if(!empty & out_ready & !in_valid)
                cnt <= cnt - 1;
            if(in_valid) begin
                data[0] <= in_data;
                for (int i = 1; i<PIPE_DLY; i=i+1) begin
                    data[i] <= data[i-1];
                end
            end
        end
    end

    assign out_valid = !empty;

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



module stream_pipeline_adapter_var2#(
    parameter WDTH = 32,
    parameter PIPE_DLY = 10
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

    localparam PIPE_CNT_BASE = $clog2(PIPE_DLY+1);

    generate
        if(PIPE_DLY < 1) 
            initial $error("PIPE_DELAY SHOULD BE 1 or more: %0d", PIPE_DLY);
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

    assign pipe_is_full = (pipe_load_cnt == PIPE_DLY);
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


    fifo_stream_test
    #(    
        .WDTH(WDTH),
        .PIPE_DLY(PIPE_DLY),
        .REGISTERED(1)
    )stream_fifo_inst(
	    .clk            (clk),
	    .reset          (reset),
        .in_flow_data   (in_data),
        .in_flow_valid  (valid_pipe_out),
        .out_stream_valid   (out_valid),
	    .out_stream_ready   (out_ready),
	    .out_stream_data    (out_data)
    );

    assign in_ready = out_ready || !pipe_is_full;   

endmodule

// module fifo_stream_test(
// 	input		clk,
// 	input		reset,
//     input  [31:0]   in_flow_data,
//     input           in_flow_valid,
//     output [7:0]    fifo_usedw,
//     output		    out_stream_valid,
// 	input 		    out_stream_ready,
// 	output [31:0]	out_stream_data
// );


//     wire            fifo_empty;
//     wire            fifo_read_req;
//     wire   [31:0]   fifo_q;
    
//     rcv_fifo rcv_fifo_ch(
//         .clock  (clk),
//         .aclr   (reset),
//         .data   (in_flow_data),
//         .wrreq  (in_flow_valid),
//         .rdreq  (fifo_read_req),
//         .empty  (fifo_empty),
//         .q      (fifo_q),
//         .usedw  (fifo_usedw)
//     );

//     typedef enum logic [2:0] {
//         IDLE, STARTING, STREAMING, ENDING, PAUSING, WAITING, RESUMING
//     } state_t;

//     state_t current_state, next_state;
//     reg [$size(fifo_q)-1:0] fifo_q_reg;
//     reg fifo_read_req_reg;

//     always_ff @(posedge clk or posedge reset) begin
//         if(reset) begin
//             current_state <= IDLE;
//             fifo_q_reg <= 0;
//             fifo_read_req_reg <= 1'b0;
//         end else begin
//             current_state <= next_state;
//             fifo_read_req_reg <= fifo_read_req;
//             if(fifo_read_req_reg) fifo_q_reg <= fifo_q;
//         end
//     end

//     always_comb begin
//         next_state = current_state;
//         case (current_state)
//             IDLE: begin
//                 if(!fifo_empty) begin
//                     next_state = STARTING;
//                 end
//             end
//             STARTING: begin
//                 if(out_stream_ready) begin
//                     if(!fifo_empty) begin
//                         next_state = STREAMING;
//                     end else begin
//                         next_state = IDLE;
//                     end
//                 end
//             end
//             STREAMING: begin
//                 if(fifo_empty) begin
//                     if(out_stream_ready) begin
//                         next_state = IDLE;
//                     end
//                     else begin
//                         next_state = ENDING;
//                     end
//                 end else begin
//                     if(!out_stream_ready) begin
//                         next_state = PAUSING;
//                     end
//                 end
//             end
//             ENDING: begin
//                 if(out_stream_ready) begin
//                     if(fifo_empty) begin
//                         next_state = IDLE;
//                     end else begin
//                         next_state = STARTING;
//                     end
//                 end
//             end
//             PAUSING: begin
//                 if(out_stream_ready) begin
//                     next_state = STARTING;
//                 end
//             end
//         endcase
//     end

// assign fifo_read_req = !fifo_empty & (out_stream_ready | (current_state == IDLE)); //!adapter_valid
// assign out_stream_valid = current_state != IDLE; //adapter_valid
// assign out_stream_data  = (current_state == PAUSING) ? fifo_q_reg : fifo_q; //adapter_valid & !out_stream_ready

// endmodule
