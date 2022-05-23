/*==================================*/
`include "lab9.v"
`timescale 1ps / 1ps
`define PAT         "data.dat"
`define End_CYCLE   10000
`define CYCLE       50.0
`define out         2
`define in          1
`define pattern_set 50
`define set_length  1
`define empty       0
`define positive    1
`define MAX         `pattern_set * `set_length

module lab9tb;

integer fd;
integer charcount;

reg [99:0] line;

reg [2:0] inout_flag;

integer loop_in;
integer loop_gold;


reg clk = 0;
reg reset = 0;

reg [13:0]IntakeData[0:`MAX];

reg [13:0]goldup[0:`MAX];
reg [13:0]goldlow[0:`MAX];

reg fail;
reg getdata;
reg [3:0]state;
reg [3:0]loop;
reg [8:0]correct;
reg [5:0]testset;

integer i;

reg [13:0]Intake;
reg give_valid;
wire [13:0]UpPrime;
wire [13:0]LowPrime;
wire out_valid;

lab9 lab9(.clk(clk), 
        .reset(reset), 
        .give_valid(give_valid),
        .Intake(Intake), 
        .UpPrime(UpPrime), 
        .LowPrime(LowPrime), 
        .out_valid(out_valid));

always begin #(`CYCLE/2) clk = ~clk; end

initial begin
    //$dumpfile("Lab.fsdb");
    //$dumpvars(0, lab8tb);
    for(i = 0; i < `MAX; i = i+1)
        $dumpvars(1, IntakeData[i], goldup[i], goldlow[i]);
end

initial begin
    $display("----------------------");
    $display("-- Simulation Start --");
    $display("----------------------");
    @(posedge clk);  #2 reset = 1'b1; 
    #(`CYCLE*2);  
    @(posedge clk);  #2 reset = 1'b0;
end

integer cycle=`empty;
always @(posedge clk) begin
    cycle = cycle + 1;
    if (cycle > `End_CYCLE) begin
        $display("--------------------------------------------------");
        $display("-- Failed waiting valid signal, Simulation STOP --");
        $display("--------------------------------------------------");
        $finish;
    end
end

initial begin
    fd = $fopen(`PAT,"r");
    if (fd == `empty) begin
        $display ("pattern handle null");
        $finish;
    end
    else if (!$feof(fd)) begin
        loop_in = 0;
        loop_gold = 0;
        getdata = `positive;
        charcount = $fgets (line, fd);
        while(charcount > `empty && getdata) begin
            if(line == "end\n")             getdata = `empty;
            else if(line == "input\n")      inout_flag = `in;
            else if(line == "output\n")     inout_flag = `out;
            else if(inout_flag == `in)
            begin
                charcount = $sscanf(line, "%d", IntakeData[loop_in]);
                // $display("in %d %d %d", IntakeData[loop_in], daty[loop_in], loop_in);
                loop_in = loop_in + 1;
            end
            else if(inout_flag == `out)
            begin
                charcount = $sscanf(line, "%d %d", goldup[loop_gold], goldlow[loop_gold]);
                // $display("out %d %d %d", goldup[loop_gold], goldlow[loop_gold], loop_gold);
                loop_gold = loop_gold + 1;
            end
            charcount = $fgets (line, fd);
        end
        $fclose(fd);
    end
end
reg [9:0]cyclecount;

always @(negedge clk ) begin
    if (reset) begin
        fail = 0;
        state = 0;
        loop = 0;
        loop_in = 0;
        loop_gold = 0;
        correct = 0;
        testset = 1;
        cyclecount = 0;
    end 
    else 
    begin
        // $display("state : %d %d %d", state, testset, loop);
        
        case(state)
            4'd0 : begin
                fail = 0;
                state = 1;
                loop = 0;
                cyclecount = 0;
            end
            4'd1 : begin
                if(loop >= `set_length)
                begin
                    state = 2;
                    give_valid = 0;
                    loop = 0;
                end
                else
                begin
                    give_valid = `positive;
                    Intake = IntakeData[loop_in];
                    // dataY = daty[loop_in];
                    loop = loop + 1;
                    loop_in = loop_in + 1;
                end
            end
            4'd2 : begin
                if(out_valid == `positive)
                begin
                    // $display("cycle %d %d", cycle, cyclecount);
                    if(UpPrime != goldup[loop_gold] || LowPrime != goldlow[loop_gold])
                    begin
                        $display("Set %d fail, \nexpect \t(UpPrime : %d, LowPrime : %d), \nbut get (UpPrime : %d, LowPrime : %d).\n", testset, goldup[loop_gold], goldlow[loop_gold], UpPrime, LowPrime);
                        fail = 1;
                    end
                    else if(UpPrime == goldup[loop_gold] || LowPrime == goldlow[loop_gold])
                    begin
                        $display("Set %d correct, \nexpect \t(UpPrime : %d, LowPrime : %d), \nget \t(UpPrime : %d, LowPrime : %d).\n", testset, goldup[loop_gold], goldlow[loop_gold], UpPrime, LowPrime);
                        correct = correct + 1;
                    end

                    if(loop == `set_length - 1)
                    begin
                        // $display("%d", testset);
                        loop = 0;
                        testset = testset + 1;
                        if (testset <= `pattern_set)
                            state = 0;
                        else
                            state = 3;
                    end
                    loop = loop + 1;
                    loop_gold = loop_gold + 1;
                end


                cyclecount = cyclecount + 1;
                if (cyclecount >= 300)
                    state = 4;
            end
            4'd3 : begin
                $display ("-------------------------------------------------");
                if(fail == 0 && correct == `set_length * `pattern_set)
                    $display("--    Simulation finish,  ALL PASS.            --");
                else
                    $display("--    Simulation Failed.  Pass : %d.          --", correct);
                $display ("-------------------------------------------------");
                $finish;
            end
            4'd4 : begin
                $display ("-------------------------------------------------");
                $display("--    Failed.      Calculate too long.         --");
                $display ("-------------------------------------------------");
                $finish;
            end
        endcase
    end
end

endmodule // End of module

/*==================================*/