`include "lab10.v"

/*==================================*/
`timescale 1ps / 1ps
//  `define PAT        "data1.dat"
// `define PAT        "data2.dat"
`define PAT        "data3.dat"
`define End_CYCLE  100000
`define CYCLE      30.0  

module lab10tb();

integer linedata;
integer char_count;
string data;
string strdata;

// ====================================================================
// I/O Pins                                                          //
// ====================================================================
reg clk = 0;
reg reset = 0;
reg [3:0] code_pos;
reg [2:0] code_len;
reg [7:0] chardata;
wire finish;
wire [7:0] char_nxt;

lab10 lab10 (.clk(clk),
            .reset(reset),
            .code_pos(code_pos),
            .code_len(code_len),
            .chardata(chardata),
            .finish(finish),
            .char_nxt(char_nxt)
            );


// ====================================================================
// Initialize                                                        //
// ====================================================================
always begin #(`CYCLE/2) clk = ~clk; end

initial
begin
    $display("----------------------");
    $display("-- Simulation Start --");
    $display("----------------------");
    @(posedge clk); #1; reset = 1'b1; 
    #(`CYCLE*2);  
    @(posedge clk); #1;   reset = 1'b0;
end

initial
begin
    linedata = $fopen(`PAT,"r");
    if(linedata == 0)
    begin
        $display ("pattern handle null");
        $finish;
    end
end


// ====================================================================
// Handle end-cycle exceeding situation                              //
// ====================================================================
reg [22:0] cycle=0;

always@(posedge clk)
begin
    cycle = cycle + 1;
    if (cycle > `End_CYCLE)
    begin
        $display("--------------------------------------------------");
        $display("---------- Time Exceed, Simulation STOP ----------");
        $display("--------------------------------------------------");
        $fclose(linedata);
        $finish;
    end

    if ((finish) && (cycle > 2059))
    begin
        $display("--------------------------------------------------");
        $display("----------  Finish Signal Time Exceed.  ----------");
        $display("--------------------------------------------------");
        $fclose(linedata);
        $finish;
    end
end


// ====================================================================
// Check if answers correct                                          //
// ====================================================================

integer strindex;
integer decode_err;
integer decode_pass;

reg [7:0] gold_char_nxt;
reg [7:0] gold_char;
reg [7:0] gold_char_nxt_fin;
wire [7:0] get_char_nxt;

string sgold_char_nxt;
string sgold_char_nxt_fin;
string scode_pos;
string scode_len;
string schardata;

reg [2:0]state;
reg [399:0] rdata;
reg [7:0]ix;

assign get_char_nxt = char_nxt;

always@(negedge clk)
begin
    if(reset)
    begin
        state = 0;
        decode_err = 0;
        decode_pass = 0;
    end
    else if (!$feof(linedata) && !finish)
    begin
        case(state)
            3'd0:
            begin
                
                char_count = $fgets(rdata, linedata);
                if (finish)  char_count = 0;

                data = rdata;
                if (data.substr(0,6) == "decode:")
                begin
                    //wait_valid = 1;
                    strindex = 0;
                    strdata = data.substr(13,data.len() - 2);
                    sgold_char_nxt = strdata.substr(strindex, strindex);//.atohex();
                    scode_pos = data.substr(7,7);//.atoi();
                    scode_len = data.substr(9,9);//.atoi();
                    //sgold_char_nxt_fin = data.getc(11);
                    sgold_char_nxt_fin = data.substr(11, 11);
                    schardata = data.substr(11, 11);//.atohex();
                    gold_char = gold_char_nxt;
                    gold_char_nxt = sgold_char_nxt[0];
                    code_pos = scode_pos[0];
                    code_len = scode_len[0];
                    chardata = schardata[0];
                    gold_char_nxt_fin = sgold_char_nxt_fin[0];

                    if(gold_char_nxt_fin==8'h24) begin
                        chardata = gold_char_nxt_fin;
                    end

                    if(!(gold_char_nxt_fin==8'h24 && code_pos==0 && code_len==0)) begin
                        // chardata = gold_char_nxt_fin;
                        $display("  == Decoding string \"%s\"", strdata);
                    end
                end
                
                if(get_char_nxt !== gold_char)
                begin
                    decode_err = decode_err + 1;
                    $display("cycle %5h, failed to decode %s, expect %s, get %s >> Fail",cycle,strdata,gold_char,get_char_nxt);
                end
                else 
                begin
                    decode_pass = decode_pass + 1;
                    $display("cycle %5h, expect %s, get %s >> Pass",cycle,gold_char,get_char_nxt); 
                end

                if (!(code_pos == 0 && code_len == 0))
                begin
                    ix = 1;
                    state = 1;
                end
            end
            3'd1:
            begin
                
                if (ix < code_len) ix = ix + 1;
                else state = 0;

                strindex = strindex + 1;
                sgold_char_nxt = strdata.substr(strindex, strindex);//.atohex();
                //if (sgold_char_nxt[0] != 0)
                gold_char = gold_char_nxt;
                gold_char_nxt = sgold_char_nxt[0];

                if(get_char_nxt !== gold_char)
                begin
                    decode_err = decode_err + 1;
                    $display("cycle %5h, failed to decode %s, expect %s, get %s >> Fail",cycle,strdata,gold_char,get_char_nxt);
                end
                else 
                begin
                    decode_pass = decode_pass + 1;
                    $display("cycle %5h, expect %s, get %s >> Pass",cycle,gold_char,get_char_nxt); 
                end
            end
        endcase
    end
    else
    begin
        if(finish) begin
            if(decode_pass == 2050) begin
                $display("-----------------------------------------------");
                // $display("-- Simulation finish, ALL PASS  --");
                
                $display("--------- Decoding finished, ALL PASS ---------"); 
                $display("-----------------------------------------------");
            end
            else begin
                $display("-----------------------------------------------");
                $display("-- Simulation finish");
                
                if(decode_err != 0) begin
                    $display("----- Decoding failed, There are %d errors", decode_err); 
                end
                $display("-----------------------------------------------");
            end
            $fclose(linedata);
            $finish;
        end
    end
end

endmodule

