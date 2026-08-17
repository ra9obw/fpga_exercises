onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fifo_stream_test_tb/clk
add wave -noupdate /fifo_stream_test_tb/reset
add wave -noupdate -radix hexadecimal /fifo_stream_test_tb/in_flow_data
add wave -noupdate /fifo_stream_test_tb/in_flow_valid
add wave -noupdate /fifo_stream_test_tb/fifo_usedw
add wave -noupdate /fifo_stream_test_tb/out_stream_valid
add wave -noupdate /fifo_stream_test_tb/out_stream_ready
add wave -noupdate -radix hexadecimal /fifo_stream_test_tb/out_stream_data
add wave -noupdate -expand -group {FIFO} /fifo_stream_test_tb/uut/rcv_fifo_ch/empty
add wave -noupdate -expand -group {FIFO} /fifo_stream_test_tb/uut/rcv_fifo_ch/full
add wave -noupdate -expand -group {FIFO} -radix hexadecimal /fifo_stream_test_tb/uut/rcv_fifo_ch/q
add wave -noupdate -expand -group {FIFO} /fifo_stream_test_tb/uut/rcv_fifo_ch/rdreq
add wave -noupdate -expand -group {FIFO} -radix unsigned /fifo_stream_test_tb/uut/rcv_fifo_ch/usedw
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {431078 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 411
configure wave -valuecolwidth 100
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
configure wave -timelineunits ps
update
WaveRestoreZoom {105257 ps} {1200852 ps}
