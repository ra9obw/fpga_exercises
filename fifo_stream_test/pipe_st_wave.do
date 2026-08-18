onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /stream_pipeline_adapter_tb/clk
add wave -noupdate /stream_pipeline_adapter_tb/reset
add wave -noupdate /stream_pipeline_adapter_tb/in_valid
add wave -noupdate /stream_pipeline_adapter_tb/in_ready
add wave -noupdate -radix hexadecimal /stream_pipeline_adapter_tb/in_data
add wave -noupdate -radix hexadecimal /stream_pipeline_adapter_tb/bb_data
add wave -noupdate /stream_pipeline_adapter_tb/out_valid
add wave -noupdate /stream_pipeline_adapter_tb/out_ready
add wave -noupdate -radix hexadecimal /stream_pipeline_adapter_tb/out_data
add wave -noupdate /stream_pipeline_adapter_tb/sent_count
add wave -noupdate /stream_pipeline_adapter_tb/received_count
add wave -noupdate /stream_pipeline_adapter_tb/errors
add wave -noupdate /stream_pipeline_adapter_tb/detailed_log
add wave -noupdate /stream_pipeline_adapter_tb/i
add wave -noupdate /stream_pipeline_adapter_tb/seed
add wave -noupdate -format Analog-Step -height 84 -max 10.0 -radix unsigned -childformat {{{/stream_pipeline_adapter_tb/uut/pipe_load_cnt[3]} -radix unsigned} {{/stream_pipeline_adapter_tb/uut/pipe_load_cnt[2]} -radix unsigned} {{/stream_pipeline_adapter_tb/uut/pipe_load_cnt[1]} -radix unsigned} {{/stream_pipeline_adapter_tb/uut/pipe_load_cnt[0]} -radix unsigned}} -subitemconfig {{/stream_pipeline_adapter_tb/uut/pipe_load_cnt[3]} {-height 15 -radix unsigned} {/stream_pipeline_adapter_tb/uut/pipe_load_cnt[2]} {-height 15 -radix unsigned} {/stream_pipeline_adapter_tb/uut/pipe_load_cnt[1]} {-height 15 -radix unsigned} {/stream_pipeline_adapter_tb/uut/pipe_load_cnt[0]} {-height 15 -radix unsigned}} /stream_pipeline_adapter_tb/uut/pipe_load_cnt
add wave -noupdate /stream_pipeline_adapter_tb/uut/in_data
add wave -noupdate -radix hexadecimal /stream_pipeline_adapter_tb/uut/shift_storage_head
add wave -noupdate -radix hexadecimal /stream_pipeline_adapter_tb/uut/storage_int/bypass_data
add wave -noupdate -radix unsigned /stream_pipeline_adapter_tb/uut/storage_int/dp_ram/read_addr
add wave -noupdate /stream_pipeline_adapter_tb/uut/storage_int/dp_ram/we
add wave -noupdate -radix unsigned /stream_pipeline_adapter_tb/uut/storage_int/dp_ram/write_addr
add wave -noupdate /stream_pipeline_adapter_tb/uut/storage_int/addr_delte_is_one
add wave -noupdate /stream_pipeline_adapter_tb/uut/storage_int/rd_cnt_changed
add wave -noupdate -radix hexadecimal /stream_pipeline_adapter_tb/uut/storage_int/mem_rdata
add wave -noupdate -radix hexadecimal /stream_pipeline_adapter_tb/uut/storage_int/next_addr_data
add wave -noupdate -radix unsigned /stream_pipeline_adapter_tb/uut/storage_int/rd_cnt
add wave -noupdate -radix unsigned /stream_pipeline_adapter_tb/uut/storage_int/next_rd_addr
add wave -noupdate -radix unsigned /stream_pipeline_adapter_tb/uut/storage_int/rd_cnt_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {154566 ps} 0} {{Cursor 2} {3235000 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 554
configure wave -valuecolwidth 119
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {3196007 ps} {3329649 ps}
