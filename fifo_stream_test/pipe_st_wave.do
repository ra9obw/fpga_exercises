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
add wave -noupdate /stream_pipeline_adapter_tb/start_value
add wave -noupdate /stream_pipeline_adapter_tb/data_value
add wave -noupdate -radix unsigned /stream_pipeline_adapter_tb/uut/pipe_load_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {240998 ps} 0} {{Cursor 2} {523621 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 380
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
WaveRestoreZoom {212356 ps} {567753 ps}
