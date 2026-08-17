module fifo_stream_test(
	input		clk,
	input		reset,
    input  [31:0]   in_flow_data,
    input           in_flow_valid,
    output [7:0]    fifo_usedw,
    output		    out_stream_valid,
	input 		    out_stream_ready,
	output [31:0]	out_stream_data
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
        .out_valid   (out_stream_valid),
        .out_ready   (out_stream_ready),
        .out_data    (out_stream_data)
        // .out_valid   (tmp_stream_valid),
        // .out_ready   (tmp_stream_ready),
        // .out_data    (tmp_stream_data)
    );

    // stream_pipe fifo_st_pipe(
    //     .clk    (clk),
    //     .reset  (reset),
    //     .in_valid   (tmp_stream_valid),
    //     .in_ready   (tmp_stream_ready),
    //     .in_data    (tmp_stream_data),
    //     .out_valid   (out_stream_valid),
    //     .out_ready   (out_stream_ready),
    //     .out_data    (out_stream_data)
    // );

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
    reg fifo_read_req_reg;
    wire fifo_read_ready;
    wire fifo_read_valid;

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            adapter_data <= 0;
            fifo_read_req_reg <= 1'b0;
            adapter_valid <= 1'b0;
        end else begin
            if(fifo_read_ready) 
                adapter_valid <= fifo_read_valid;

            fifo_read_req_reg <= fifo_read_req;
            if(fifo_read_req_reg) 
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
    output		        out_valid,
	input 		        out_ready,
	output [WDTH-1:0]   out_data
);

    localparam PIPE_CNT_BASE = $clog2(PIPE_DLY);

    generate
        if(PIPE_DLY < 2) 
            initial $error("PIPE_DELAY SHOULD BE 2 or more: %0d", PIPE_DLY);
    endgenerate

    reg [PIPE_DLY-1:0] in_valid_pipe;
    reg [PIPE_CNT_BASE-1:0] pipe_load_cnt;
    wire pipe_is_full;
    
    reg [WDTH-1:0] buffer_data;

    wire [WDTH-1:0] shift_storage_head;
    wire shift_storage_empty;
    logic [WDTH-1:0] shift_storage_data[PIPE_DLY];//-1
    reg [PIPE_CNT_BASE-1:0] shift_storage_cnt;


    assign pipe_is_full = (pipe_load_cnt == (PIPE_DLY-1));

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            in_valid_pipe <= 0;
            pipe_load_cnt <= 0;
            buffer_data <= 0;
        end else begin

        end
    end

    assign in_ready = out_ready || !pipe_is_full;
    assign out_data = out_ready ? (shift_storage_empty ? in_data : shift_storage_head) : buffer_data;
    assign out_valid = in_valid_pipe[PIPE_DLY-1] | ;

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
