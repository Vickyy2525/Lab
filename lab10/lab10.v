/**
 *
 * @author : 409410100 徐佳琪
 * @latest changed : 2022/6/1 02:30
 */

module lab10(input clk,
			input reset,
			input [3:0]code_pos,		// 匹配字符串的開始字符串與待編碼緩沖區的距離
			input [2:0]code_len,		// 匹配字符串的長度
			input [7:0]chardata,		// 待編碼區下一個等待編碼的字符
			output reg finish,			// 有效的輸出訊號，為high時，表示目前的Decoder動作已經全部完成
			output reg [7:0]char_nxt);	// 完成的編碼

initial begin
    $dumpfile("Lab.vcd");
    $dumpvars(0, lab10tb);
end

reg [2:0]state;
reg [7:0]SearchBuf[0:8];	//the spin window
reg [5:0]index;				//紀錄讀到第幾個字


always@(posedge clk or posedge reset) begin // spin window
	if(reset) begin		// reset 都是 0
		SearchBuf[1] <= 0;
		SearchBuf[2] <= 0;
		SearchBuf[3] <= 0;
		SearchBuf[4] <= 0;
		SearchBuf[5] <= 0;
		SearchBuf[6] <= 0;
		SearchBuf[7] <= 0;
		SearchBuf[8] <= 0;
	end else begin		// 左移一位
		SearchBuf[1] <= SearchBuf[0];
		SearchBuf[2] <= SearchBuf[1];
		SearchBuf[3] <= SearchBuf[2];
		SearchBuf[4] <= SearchBuf[3];
		SearchBuf[5] <= SearchBuf[4];
		SearchBuf[6] <= SearchBuf[5];
		SearchBuf[7] <= SearchBuf[6];
		SearchBuf[8] <= SearchBuf[7];
	end
end

always@(posedge clk or posedge reset) begin // output & state control
	if(reset) begin
		SearchBuf[0] <= 0;
		finish <= 0;
		index <= 0;
		state <= 0;
	end else begin
		case (state)
            3'd0:begin     		// initial state
                if(code_pos == 0 && code_len == 0) begin
					SearchBuf[0] <= chardata;
					char_nxt <= chardata;					// 就直接輸出
					if(chardata == "$") state <= 2;			// 遇到$
				end else begin
					SearchBuf[0] <= SearchBuf[code_pos];
					char_nxt <= SearchBuf[code_pos];		// 找offset
					index <= index + 1;
					state <= 1;								// 找剩下的char
				end
            end
            3'd1:begin    		
				if (index < code_len) begin					
					SearchBuf[0] <= SearchBuf[code_pos];	// 除了chardata(最後一個字)
					char_nxt <= SearchBuf[code_pos];
					index <= index + 1;
				end else if(chardata == "$") begin			
					char_nxt <= chardata;
					state <= 2;								// 遇到$(EOF)
				end else begin								// 不是EOF，需要繼續讀取跟index歸0
					SearchBuf[0] <= chardata;				// chardata(最後一個字)
					char_nxt <= chardata;
					index <= 0;
					state <= 0;	
				end
            end	
            3'd2:begin          // finish
                finish <= 1;
            end
        endcase
	end
end

endmodule