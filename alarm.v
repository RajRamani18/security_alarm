`timescale 1ns / 1ps
module alarm(
            input clk,
            input reset,
            input [3:0] keypad,
            input front_door,
            input rear_door,
            input window,
            output reg alarm_siren,
            output reg is_armed,
            output reg is_wait_delay
            );
// set the delay value (the number of clocks between a faulted zone and the
// alarm going off)
    parameter delay_val = 100;
    localparam [1:0] disarmed   = 2'b00,
                     armed      = 2'b01,
                     wait_delay = 2'b10,
                     alarm      = 2'b11; //state
    reg [1:0] curr_state, next_state;
    wire start_count;
    wire count_done;
    wire [2:0] sensors ; // front door, rear door & window sensors are combined
    reg [15:0] delay_cntr ;
    assign sensors = { front_door, rear_door, window };

// implement the state flip-flops
    always @ (posedge clk)
        if(reset)
            curr_state <= disarmed;
        else
            curr_state <= next_state;
            
            
    always @ (curr_state, sensors, keypad, count_done)
        begin
            case(curr_state)
                disarmed: 
                    begin
                        if(keypad == 4'b0011) begin
                            next_state <= armed;
                            is_armed <= 1'b1;
                            is_wait_delay <= 1'b0;
                            alarm_siren <= 1'b0;
                        end
                        else begin
                            next_state <= curr_state;
                            is_armed <= 1'b0;
                            is_wait_delay <= 1'b0;
                            alarm_siren <= 1'b0;
                        end
                    end
                    
                armed:
                    begin
                        if(keypad == 4'b1100) begin
                            next_state <= disarmed;
                            is_armed <= 1'b0;
                            is_wait_delay <= 1'b0;
                            alarm_siren <= 1'b0;
                        end
                        else if(sensors != 3'b000) begin
                            next_state <= wait_delay;
                            is_armed <= 1'b0;
                            is_wait_delay <= 1'b1;
                            alarm_siren <= 1'b0;
                        end
                        else begin
                            next_state <= curr_state;
                        end
                    end
                
                wait_delay:
                    begin
                        if(keypad == 4'b1100) begin
                            next_state <= disarmed;
                            is_armed <= 1'b0;
                            is_wait_delay <= 1'b0;
                            alarm_siren <= 1'b0;
                        end
                        else if(count_done == 1'b1) begin
                            next_state <= alarm;
                            is_armed <= 1'b0;
                            is_wait_delay <= 1'b0;
                            alarm_siren <= 1'b1;
                        end
                        else begin
                            next_state <= curr_state;
                        end
                    end
                    
                alarm:
                    begin
                        if(keypad == 4'b1100) begin
                            next_state <= disarmed;
                            is_armed <= 1'b0;
                            is_wait_delay <= 1'b0;
                            alarm_siren <= 1'b0;
                        end
                        else begin
                            next_state <= curr_state;
                        end
                    end                                        
            endcase             
        end
        
        assign start_count = ((curr_state == armed) && (sensors != 3'b000));
        
        always @ (posedge clk) begin
            if(reset)
                delay_cntr <= delay_val - 1'b1;
            else if(start_count)
                delay_cntr <= delay_val - 1'b1;
            else if(curr_state != wait_delay)
                delay_cntr <= delay_val - 1'b1;
            else if(delay_cntr != 0)
                delay_cntr <= delay_cntr - 1'b1;            
        end
        
        assign count_done = (delay_cntr == 0);
        
endmodule