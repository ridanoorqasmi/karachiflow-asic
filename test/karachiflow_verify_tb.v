`timescale 1ns / 1ps

module karachi_tf_tb;

    // ============================================================
    // KARACHIFLOW - COMPLETE RTL VERIFICATION TESTBENCH
    // Compatible with Vivado 2018.2 / Icarus Verilog
    // ============================================================

    parameter integer MIN_GREEN     = 5;
    parameter integer MAX_GREEN     = 10;
    parameter integer YELLOW_TIME   = 2;
    parameter integer ALL_RED_TIME  = 2;

    parameter integer TIMEOUT       = 50;
    parameter integer RANDOM_CYCLES = 500;


    // ============================================================
    // DUT SIGNALS
    // ============================================================

    reg clk;
    reg rst_n;

    reg [1:0] traffic_a;
    reg [1:0] traffic_b;

    reg emergency_a;
    reg emergency_b;

    wire a_red;
    wire a_yellow;
    wire a_green;

    wire b_red;
    wire b_yellow;
    wire b_green;


    // ============================================================
    // TEST VARIABLES
    // ============================================================

    integer tests_passed;
    integer tests_failed;

    integer i;
    integer seed;
    integer ok;
    integer violation;
    integer saw_a;
    integer saw_b;

    reg [31:0] random_value;


    // ============================================================
    // DEVICE UNDER TEST
    // ============================================================

    karachiflow #(
        .MIN_GREEN(MIN_GREEN),
        .MAX_GREEN(MAX_GREEN),
        .YELLOW_TIME(YELLOW_TIME),
        .ALL_RED_TIME(ALL_RED_TIME)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .traffic_a(traffic_a),
        .traffic_b(traffic_b),

        .emergency_a(emergency_a),
        .emergency_b(emergency_b),

        .a_red(a_red),
        .a_yellow(a_yellow),
        .a_green(a_green),

        .b_red(b_red),
        .b_yellow(b_yellow),
        .b_green(b_green)
    );


    // ============================================================
    // CLOCK
    // 10 ns period
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // STATE HELPER FUNCTIONS
    //
    // Dummy argument is used because Vivado 2018.2 requires
    // Verilog functions to have at least one input.
    // ============================================================

    function is_a_green;
        input dummy;
        begin
            is_a_green =
                (a_red    === 1'b0) &&
                (a_yellow === 1'b0) &&
                (a_green  === 1'b1) &&
                (b_red    === 1'b1) &&
                (b_yellow === 1'b0) &&
                (b_green  === 1'b0);
        end
    endfunction


    function is_a_yellow;
        input dummy;
        begin
            is_a_yellow =
                (a_red    === 1'b0) &&
                (a_yellow === 1'b1) &&
                (a_green  === 1'b0) &&
                (b_red    === 1'b1) &&
                (b_yellow === 1'b0) &&
                (b_green  === 1'b0);
        end
    endfunction


    function is_all_red;
        input dummy;
        begin
            is_all_red =
                (a_red    === 1'b1) &&
                (a_yellow === 1'b0) &&
                (a_green  === 1'b0) &&
                (b_red    === 1'b1) &&
                (b_yellow === 1'b0) &&
                (b_green  === 1'b0);
        end
    endfunction


    function is_b_green;
        input dummy;
        begin
            is_b_green =
                (a_red    === 1'b1) &&
                (a_yellow === 1'b0) &&
                (a_green  === 1'b0) &&
                (b_red    === 1'b0) &&
                (b_yellow === 1'b0) &&
                (b_green  === 1'b1);
        end
    endfunction


    function is_b_yellow;
        input dummy;
        begin
            is_b_yellow =
                (a_red    === 1'b1) &&
                (a_yellow === 1'b0) &&
                (a_green  === 1'b0) &&
                (b_red    === 1'b0) &&
                (b_yellow === 1'b1) &&
                (b_green  === 1'b0);
        end
    endfunction


    // ============================================================
    // CLOCK STEP
    // ============================================================

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask


    // ============================================================
    // RESET DUT
    // ============================================================

    task reset_dut;
        begin

            rst_n = 1'b0;

            traffic_a = 2'b00;
            traffic_b = 2'b00;

            emergency_a = 1'b0;
            emergency_b = 1'b0;

            tick;
            tick;

            @(negedge clk);
            rst_n = 1'b1;

            #1;
        end
    endtask


    // ============================================================
    // RESULT REPORTING
    // ============================================================

    task pass_test;
        input [8*80-1:0] test_name;
        begin
            tests_passed = tests_passed + 1;
            $display("PASS: %0s", test_name);
        end
    endtask


    task fail_test;
        input [8*80-1:0] test_name;
        begin
            tests_failed = tests_failed + 1;
            $display("FAIL: %0s", test_name);
        end
    endtask


    // ============================================================
    // WAIT HELPERS
    // ============================================================

    task wait_for_a_yellow;
        output integer success;
        integer count;

        begin
            success = 0;
            count   = 0;

            while ((count < TIMEOUT) &&
                   !is_a_yellow(1'b0)) begin

                tick;
                count = count + 1;
            end

            if (is_a_yellow(1'b0))
                success = 1;
        end
    endtask


    task wait_for_all_red;
        output integer success;
        integer count;

        begin
            success = 0;
            count   = 0;

            while ((count < TIMEOUT) &&
                   !is_all_red(1'b0)) begin

                tick;
                count = count + 1;
            end

            if (is_all_red(1'b0))
                success = 1;
        end
    endtask


    task wait_for_b_green;
        output integer success;
        integer count;

        begin
            success = 0;
            count   = 0;

            while ((count < TIMEOUT) &&
                   !is_b_green(1'b0)) begin

                tick;
                count = count + 1;
            end

            if (is_b_green(1'b0))
                success = 1;
        end
    endtask


    task wait_for_b_yellow;
        output integer success;
        integer count;

        begin
            success = 0;
            count   = 0;

            while ((count < TIMEOUT) &&
                   !is_b_yellow(1'b0)) begin

                tick;
                count = count + 1;
            end

            if (is_b_yellow(1'b0))
                success = 1;
        end
    endtask


    task wait_for_a_green;
        output integer success;
        integer count;

        begin
            success = 0;
            count   = 0;

            while ((count < TIMEOUT) &&
                   !is_a_green(1'b0)) begin

                tick;
                count = count + 1;
            end

            if (is_a_green(1'b0))
                success = 1;
        end
    endtask


    // ============================================================
    // CONTINUOUS SAFETY MONITOR
    // ============================================================

    always @(posedge clk) begin

        #1;

        if (rst_n) begin

            // Never allow both roads to be green.

            if ((a_green === 1'b1) &&
                (b_green === 1'b1)) begin

                $display(
                    "FATAL SAFETY ERROR @ %0t: BOTH ROADS GREEN",
                    $time
                );

                $stop;
            end


            // Road A must show exactly one signal.

            if ((a_red + a_yellow + a_green) !== 1) begin

                $display(
                    "FATAL OUTPUT ERROR @ %0t: INVALID ROAD A LIGHTS",
                    $time
                );

                $stop;
            end


            // Road B must show exactly one signal.

            if ((b_red + b_yellow + b_green) !== 1) begin

                $display(
                    "FATAL OUTPUT ERROR @ %0t: INVALID ROAD B LIGHTS",
                    $time
                );

                $stop;
            end
        end
    end


    // ============================================================
    // MAIN TEST SEQUENCE
    // ============================================================

    initial begin

        tests_passed = 0;
        tests_failed = 0;

        seed = 32'h4B46574C;

        rst_n       = 1'b0;
        traffic_a   = 2'b00;
        traffic_b   = 2'b00;
        emergency_a = 1'b0;
        emergency_b = 1'b0;


        $display("");
        $display("==============================================");
        $display("       KARACHIFLOW RTL VERIFICATION");
        $display("==============================================");
        $display("");


        // ========================================================
        // T01 - RESET
        // ========================================================

        reset_dut;

        if (is_a_green(1'b0))
            pass_test("T01 Reset -> safe A_GREEN state");
        else
            fail_test("T01 Reset -> safe A_GREEN state");


        // ========================================================
        // T02 - NORMAL A OPERATION
        // ========================================================

        reset_dut;

        traffic_a = 2'b10;
        traffic_b = 2'b01;

        violation = 0;

        for (i = 0; i < MIN_GREEN; i = i + 1) begin

            tick;

            if (!is_a_green(1'b0))
                violation = 1;
        end

        if (!violation)
            pass_test("T02 Normal A green operation");
        else
            fail_test("T02 Normal A green operation");


        // ========================================================
        // T03 - DEMAND-DRIVEN A -> B
        // ========================================================

        reset_dut;

        traffic_a = 2'b01;
        traffic_b = 2'b11;

        wait_for_a_yellow(ok);

        if (!ok) begin

            fail_test("T03 Demand-driven A -> B transfer");

        end
        else begin

            wait_for_all_red(ok);

            if (!ok) begin

                fail_test("T03 Demand-driven A -> B transfer");

            end
            else begin

                wait_for_b_green(ok);

                if (ok)
                    pass_test("T03 Demand-driven A -> B transfer");
                else
                    fail_test("T03 Demand-driven A -> B transfer");

            end
        end


        // ========================================================
        // T04 - MIN_GREEN
        // ========================================================

        reset_dut;

        traffic_a = 2'b01;
        traffic_b = 2'b11;

        violation = 0;

        for (i = 0; i < MIN_GREEN; i = i + 1) begin

            tick;

            if (!is_a_green(1'b0))
                violation = 1;
        end

        if (!violation)
            pass_test("T04 MIN_GREEN prevents premature transfer");
        else
            fail_test("T04 MIN_GREEN prevents premature transfer");


        // ========================================================
        // T05 - MAX_GREEN FAIRNESS
        // ========================================================

        reset_dut;

        traffic_a = 2'b11;
        traffic_b = 2'b01;

        wait_for_a_yellow(ok);

        if (!ok) begin

            fail_test("T05 MAX_GREEN starvation prevention");

        end
        else begin

            wait_for_b_green(ok);

            if (ok)
                pass_test("T05 MAX_GREEN starvation prevention");
            else
                fail_test("T05 MAX_GREEN starvation prevention");

        end


        // ========================================================
        // T06 - NO-DEMAND HOLD BEYOND MAX_GREEN
        // ========================================================

        reset_dut;

        traffic_a = 2'b11;
        traffic_b = 2'b00;

        violation = 0;

        repeat (MAX_GREEN + 10) begin

            tick;

            if (!is_a_green(1'b0))
                violation = 1;

        end

        if (!violation)
            pass_test("T06 No-demand hold beyond MAX_GREEN");
        else
            fail_test("T06 No-demand hold beyond MAX_GREEN");


        // ========================================================
        // T07 - YELLOW CLEARANCE
        // ========================================================

        reset_dut;

        traffic_a = 2'b01;
        traffic_b = 2'b11;

        wait_for_a_yellow(ok);

        if (ok && is_a_yellow(1'b0))
            pass_test("T07 A_YELLOW clearance state exists");
        else
            fail_test("T07 A_YELLOW clearance state exists");


        // ========================================================
        // T08 - ALL-RED CLEARANCE
        // ========================================================

        wait_for_all_red(ok);

        if (ok && is_all_red(1'b0))
            pass_test("T08 ALL_RED_AB clearance state exists");
        else
            fail_test("T08 ALL_RED_AB clearance state exists");


        // ========================================================
        // T09 - REVERSE TRANSITION B -> A
        // ========================================================

        reset_dut;

        traffic_a = 2'b01;
        traffic_b = 2'b11;

        wait_for_b_green(ok);

        if (!ok) begin

            fail_test("T09 Demand-driven B -> A transfer");

        end
        else begin

            @(negedge clk);

            traffic_a = 2'b11;
            traffic_b = 2'b01;

            wait_for_b_yellow(ok);

            if (!ok) begin

                fail_test("T09 Demand-driven B -> A transfer");

            end
            else begin

                wait_for_all_red(ok);

                if (!ok) begin

                    fail_test("T09 Demand-driven B -> A transfer");

                end
                else begin

                    wait_for_a_green(ok);

                    if (ok)
                        pass_test("T09 Demand-driven B -> A transfer");
                    else
                        fail_test("T09 Demand-driven B -> A transfer");

                end
            end
        end


        // ========================================================
        // T10 - EMERGENCY B WHILE A IS GREEN
        // ========================================================

        reset_dut;

        traffic_a = 2'b11;
        traffic_b = 2'b00;

        tick;

        @(negedge clk);
        emergency_b = 1'b1;

        tick;

        if (!is_a_yellow(1'b0)) begin

            fail_test("T10 Emergency B safely preempts A");

        end
        else begin

            wait_for_all_red(ok);

            if (!ok) begin

                fail_test("T10 Emergency B safely preempts A");

            end
            else begin

                wait_for_b_green(ok);

                if (ok)
                    pass_test("T10 Emergency B safely preempts A");
                else
                    fail_test("T10 Emergency B safely preempts A");

            end
        end


        // ========================================================
        // T11 - EMERGENCY A WHILE B IS GREEN
        // ========================================================

        reset_dut;

        traffic_a = 2'b01;
        traffic_b = 2'b11;

        wait_for_b_green(ok);

        if (!ok) begin

            fail_test("T11 Emergency A safely preempts B");

        end
        else begin

            @(negedge clk);

            traffic_a   = 2'b00;
            traffic_b   = 2'b11;

            emergency_a = 1'b1;

            tick;

            if (!is_b_yellow(1'b0)) begin

                fail_test("T11 Emergency A safely preempts B");

            end
            else begin

                wait_for_all_red(ok);

                if (!ok) begin

                    fail_test("T11 Emergency A safely preempts B");

                end
                else begin

                    wait_for_a_green(ok);

                    if (ok)
                        pass_test("T11 Emergency A safely preempts B");
                    else
                        fail_test("T11 Emergency A safely preempts B");

                end
            end
        end


        // ========================================================
        // T12 - SAME-ROAD EMERGENCY RETENTION
        // ========================================================

        reset_dut;

        traffic_a = 2'b01;
        traffic_b = 2'b11;

        emergency_a = 1'b1;
        emergency_b = 1'b0;

        violation = 0;

        repeat (MAX_GREEN + 5) begin

            tick;

            if (!is_a_green(1'b0))
                violation = 1;

        end

        if (!violation)
            pass_test("T12 Same-road emergency retains A_GREEN");
        else
            fail_test("T12 Same-road emergency retains A_GREEN");


        // ========================================================
        // T13 - SIMULTANEOUS EMERGENCIES
        // ========================================================

        reset_dut;

        traffic_a = 2'b00;
        traffic_b = 2'b00;

        emergency_a = 1'b1;
        emergency_b = 1'b1;

        violation = 0;

        repeat (MAX_GREEN + 3) begin

            tick;

            if (!is_a_green(1'b0))
                violation = 1;

        end

        if (violation) begin

            fail_test("T13 Simultaneous emergency arbitration");

        end
        else begin

            @(negedge clk);

            emergency_a = 1'b0;
            emergency_b = 1'b1;

            tick;

            if (!is_a_yellow(1'b0)) begin

                fail_test("T13 Simultaneous emergency arbitration");

            end
            else begin

                wait_for_b_green(ok);

                if (ok)
                    pass_test("T13 Simultaneous emergency arbitration");
                else
                    fail_test("T13 Simultaneous emergency arbitration");

            end
        end


        // ========================================================
        // T14 - CONTINUOUS A + B DEMAND
        // ========================================================

        reset_dut;

        traffic_a = 2'b11;
        traffic_b = 2'b11;

        saw_a = 0;
        saw_b = 0;

        repeat ((MAX_GREEN +
                 YELLOW_TIME +
                 ALL_RED_TIME + 5) * 4) begin

            tick;

            if (is_a_green(1'b0))
                saw_a = 1;

            if (is_b_green(1'b0))
                saw_b = 1;

        end

        if (saw_a && saw_b)
            pass_test("T14 Continuous demand serves both roads");
        else
            fail_test("T14 Continuous demand serves both roads");


        // ========================================================
        // T15 - RANDOMIZED SAFETY STRESS
        // ========================================================

        reset_dut;

        violation = 0;

        for (i = 0; i < RANDOM_CYCLES; i = i + 1) begin

            @(negedge clk);

            random_value = $random(seed);

            traffic_a = random_value[1:0];
            traffic_b = random_value[3:2];

            emergency_a =
                (random_value[7:4] == 4'b0000);

            emergency_b =
                (random_value[11:8] == 4'b0000);

            tick;

            if (a_green && b_green)
                violation = 1;

            if ((a_red + a_yellow + a_green) !== 1)
                violation = 1;

            if ((b_red + b_yellow + b_green) !== 1)
                violation = 1;

        end

        if (!violation)
            pass_test("T15 500-cycle randomized safety stress");
        else
            fail_test("T15 500-cycle randomized safety stress");


        // ========================================================
        // T16 - EXACT A_YELLOW DURATION
        //
        // Verify that A_YELLOW remains active for exactly
        // YELLOW_TIME clock cycles.
        // ========================================================

        reset_dut;

        traffic_a = 2'b01;
        traffic_b = 2'b11;

        wait_for_a_yellow(ok);

        if (!ok) begin

            fail_test("T16 A_YELLOW exact duration");

        end
        else begin

            i = 0;

            while (is_a_yellow(1'b0) &&
                   (i < TIMEOUT)) begin

                tick;
                i = i + 1;

            end

            if (i == YELLOW_TIME) begin

                pass_test("T16 A_YELLOW exact duration");

            end
            else begin

                fail_test("T16 A_YELLOW exact duration");

                $display(
                    "     Expected = %0d cycles",
                    YELLOW_TIME
                );

                $display(
                    "     Observed = %0d cycles",
                    i
                );

            end
        end


        // ========================================================
        // T17 - EXACT ALL_RED_AB DURATION
        //
        // Verify that ALL_RED_AB remains active for exactly
        // ALL_RED_TIME clock cycles.
        // ========================================================

        if (!is_all_red(1'b0))
            wait_for_all_red(ok);
        else
            ok = 1;

        if (!ok) begin

            fail_test("T17 ALL_RED_AB exact duration");

        end
        else begin

            i = 0;

            while (is_all_red(1'b0) &&
                   (i < TIMEOUT)) begin

                tick;
                i = i + 1;

            end

            if (i == ALL_RED_TIME) begin

                pass_test("T17 ALL_RED_AB exact duration");

            end
            else begin

                fail_test("T17 ALL_RED_AB exact duration");

                $display(
                    "     Expected = %0d cycles",
                    ALL_RED_TIME
                );

                $display(
                    "     Observed = %0d cycles",
                    i
                );

            end
        end


        // ========================================================
        // FINAL REPORT
        // ========================================================

        $display("");
        $display("==============================================");
        $display("       KARACHIFLOW VERIFICATION SUMMARY");
        $display("==============================================");

        $display("Tests passed : %0d", tests_passed);
        $display("Tests failed : %0d", tests_failed);

        if ((tests_passed == 17) &&
            (tests_failed == 0)) begin

            $display("");
            $display("RESULT: 17/17 PASS");
            $display("GATE 4 CORE RTL VERIFICATION PASSED");

        end
        else begin

            $display("");
            $display("RESULT: VERIFICATION FAILED");
            $display("DO NOT PROCEED TO PHYSICAL LAYOUT");

        end

        $display("==============================================");
        $display("");

        #20;
        $finish;

    end

endmodule