module fifo_stream_test_v0(
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

    typedef enum logic [2:0] {
        IDLE, STARTING, STREAMING, ENDING, PAUSING, WAITING, RESUMING
    } state_t;

    state_t current_state, next_state;
    reg [$size(fifo_q)-1:0] fifo_q_reg;
    reg fifo_read_req_reg;

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            current_state <= IDLE;
            fifo_q_reg <= 0;
            fifo_read_req_reg <= 1'b0;
        end else begin
            current_state <= next_state;
            fifo_read_req_reg <= fifo_read_req;
            if(fifo_read_req_reg) fifo_q_reg <= fifo_q;
        end
    end

    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if(!fifo_empty) begin
                    next_state = STARTING;
                end
            end
            STARTING: begin
                if(out_stream_ready) begin
                    if(!fifo_empty) begin
                        next_state = STREAMING;
                    end else begin
                        next_state = IDLE;
                    end
                end
            end
            STREAMING: begin
                if(fifo_empty) begin
                    if(out_stream_ready) begin
                        next_state = IDLE;
                    end
                    else begin
                        next_state = ENDING;
                    end
                end else begin
                    if(!out_stream_ready) begin
                        next_state = PAUSING;
                    end
                end
            end
            ENDING: begin
                if(out_stream_ready) begin
                    if(fifo_empty) begin
                        next_state = IDLE;
                    end else begin
                        next_state = STARTING;
                    end
                end
            end
            PAUSING: begin
                if(out_stream_ready) begin
                    next_state = STARTING;
                end
            end
        endcase
    end

assign fifo_read_req = !fifo_empty & (out_stream_ready | (current_state == IDLE)); //!adapter_valid
assign out_stream_valid = current_state != IDLE; //adapter_valid
assign out_stream_data  = (current_state == PAUSING) ? fifo_q_reg : fifo_q; //adapter_valid & !out_stream_ready

endmodule
