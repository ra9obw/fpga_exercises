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
add wave -noupdate -format Analog-Step -height 84 -max 10.0 -radix unsigned -childformat {{{/stream_pipeline_adapter_tb/uut/pipe_load_cnt[3]} -radix unsigned} {{/stream_pipeline_adapter_tb/uut/pipe_load_cnt[2]} -radix unsigned} {{/stream_pipeline_adapter_tb/uut/pipe_load_cnt[1]} -radix unsigned} {{/stream_pipeline_adapter_tb/uut/pipe_load_cnt[0]} -radix unsigned}} -subitemconfig {{/stream_pipeline_adapter_tb/uut/pipe_load_cnt[3]} {-height 13 -radix unsigned} {/stream_pipeline_adapter_tb/uut/pipe_load_cnt[2]} {-height 13 -radix unsigned} {/stream_pipeline_adapter_tb/uut/pipe_load_cnt[1]} {-height 13 -radix unsigned} {/stream_pipeline_adapter_tb/uut/pipe_load_cnt[0]} {-height 13 -radix unsigned}} /stream_pipeline_adapter_tb/uut/pipe_load_cnt
add wave -noupdate -radix hexadecimal /stream_pipeline_adapter_tb/uut/in_data
add wave -noupdate -radix unsigned /stream_pipeline_adapter_tb/uut/genblk2/storage_int/wr_cnt
add wave -noupdate -radix unsigned /stream_pipeline_adapter_tb/uut/genblk2/storage_int/rd_cnt
add wave -noupdate -radix hexadecimal /stream_pipeline_adapter_tb/uut/genblk2/storage_int/mem_rdata
add wave -noupdate /stream_pipeline_adapter_tb/uut/genblk2/storage_int/empty
add wave -noupdate -radix hexadecimal -childformat {{{/stream_pipeline_adapter_tb/uut/genblk2/storage_int/haed_data[0]} -radix hexadecimal} {{/stream_pipeline_adapter_tb/uut/genblk2/storage_int/haed_data[1]} -radix hexadecimal}} -expand -subitemconfig {{/stream_pipeline_adapter_tb/uut/genblk2/storage_int/haed_data[0]} {-radix hexadecimal} {/stream_pipeline_adapter_tb/uut/genblk2/storage_int/haed_data[1]} {-radix hexadecimal}} /stream_pipeline_adapter_tb/uut/genblk2/storage_int/haed_data
add wave -noupdate -radix unsigned /stream_pipeline_adapter_tb/uut/genblk2/storage_int/head_pointer
add wave -noupdate /stream_pipeline_adapter_tb/uut/genblk2/storage_int/mem_readed
add wave -noupdate -radix unsigned /stream_pipeline_adapter_tb/uut/genblk2/storage_int/items
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2316523 ps} 0} {{Cursor 2} {12033925 ps} 0}
quietly wave cursor active 1
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
WaveRestoreZoom {2094371 ps} {2601831 ps}
