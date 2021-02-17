
`timescale 1ns / 1ps

module alarm_tb;
  parameter per = 10.0;

  // inputs
  reg front_door;
  reg rear_door;
  reg window;
  reg clk;
  reg reset;
  reg [3:0] keypad = 4'b0011;

  // outputs
  wire alarm_siren;
  wire is_armed;
  wire is_wait_delay;

  task check_state;
    input exp_arm, exp_wait, exp_siren;
    input [80*8-1:0] string;
  begin
    if ((is_armed      !== exp_arm)  || 
        (is_wait_delay !== exp_wait) || 
        (alarm_siren   !== exp_siren)  )
    begin
      $display("%t error %s ", $realtime(), string);
      $display("%t armed=%b, wait=%b, siren=%b", $realtime(), is_armed, is_wait_delay, alarm_siren);

      $stop;
      $finish; // end the simulation on an error

    end
  end
  endtask

  // instantiate the unit under test (uut)
  alarm uut (
    .front_door(front_door), 
    .rear_door(rear_door), 
    .window(window), 
    .clk(clk), 
    .reset(reset), 
    .keypad(keypad), 
    .alarm_siren(alarm_siren), 
    .is_armed(is_armed),
    .is_wait_delay(is_wait_delay)
  );

  initial begin
    // initialize inputs
    clk = 0;
    reset = 0;
    front_door = 0;
    rear_door = 0;
    window = 0;
    keypad = 4'b0000;   
  end

  initial
    $timeformat(-9,2," ns", 12);
      
  always #(per/2) clk = ~clk;

  initial  
  begin
    $display("%t       starting test - asserting reset",$realtime());
    reset = 1'b1;
    #(10 * per) reset = 1'b0;
    $display("%t       deasserting reset",$realtime());
    #(1 * per);
    // test that reset took you to the disarmed state
    check_state(0,0,0,"reset state is not disarmed");
    // and that you stay there
    #(10 * per) ;
    check_state(0,0,0,"did not remain in disarmed state");
       
    #(10 * per) ;

    $display("%t       testing arming",$realtime());
    keypad = 4'b0011;
    #(1 * per);
    // test that arm code took you to the armed state
    check_state(1,0,0,"arming code doesn't arm alarm");
    // and that we stay armed even if the code goes away
    keypad = 4'b0000;
    #(10 * per) ;
    check_state(1,0,0,"doesn't remain in the armed state");

    $display("%t       testing disarming",$realtime());
    // check that disarming from the armed state works
    keypad = 4'b1100;
    #(1 * per) ;
    // test that disarm code took you to the disarmed state
    check_state(0,0,0,"disarming code doesn't disarm alarm");
    // and that we stay disarmed
    keypad = 4'b0000;
    #(10 * per) ;
    check_state(0,0,0,"doesn't remain disarmed");

    #(10 * per) ;

    $display("%t       testing arming, faulting and disarming before alarm",
      $realtime());
    keypad = 4'b0011;
    #(1 * per);
    // test that arm code took you to the armed state
    check_state(1,0,0,"arming code doesn't re-arm alarm");
    keypad = 4'b0000;
    front_door = 1; // fault the front door
    #(1 * per);
    check_state(0,1,0,"faulting a zone doesn't start wait");
    front_door = 0; // unfault it right away
    #(50 * per);
    check_state(0,1,0,"not still waiting after 50 clocks");
    keypad = 4'b1100;
    #(1 * per) ;
    // test that disarm code took you to the disarmed state
    check_state(0,0,0,"disarming while waiting doesn't work");
    keypad = 4'b0000;

    #(10 * per) ;
    $display("%t       testing arming, faulting and waiting for alarm",
      $realtime());
    keypad = 4'b0011;
    #(1 * per);
    // test that arm code took you to the armed state
    check_state(1,0,0,"arming code doesn't re-arm alarm");
    keypad = 4'b0000;
    rear_door = 1; // fault the rear door
    #(1 * per);
    check_state(0,1,0,"faulting a zone doesn't start wait");
    rear_door = 0; // unfault the rear door
    #(110 * per);
    check_state(0,0,1,"alarm siren didn't go off");
    keypad = 4'b1100;
    #(1 * per) ;
    // test that disarm code took you to the disarmed state
    check_state(0,0,0,"disarming while the alarm siren is on doesn't work");
    keypad = 4'b0000;

    #(10 * per) ;
    $display("%t       test passed", $realtime());
    $finish;

  end      
  
endmodule