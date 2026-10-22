module nortl_sync #(
    parameter DATA_WIDTH = 1
) (
    input  logic CLK_I,
    input  logic RST_ASYNC_I,

    input  logic [DATA_WIDTH-1:0] IN,
    output logic [DATA_WIDTH-1:0] OUT,

    output logic CLK_REQ
);

always @(posedge CLK_I or posedge RST_ASYNC_I)
begin
    if (RST_ASYNC_I)
    begin
        OUT <= {DATA_WIDTH{1'b0}};
    end
    else begin
        OUT <= IN;
    end
end

always_comb begin
    CLK_REQ = OUT != IN;
end

endmodule

module nortl_edge_detector(
    input  logic CLK_I,
    input  logic RST_ASYNC_I,

    input  logic SIGNAL,
    output logic RISING,
    output logic FALLING,

    output logic CLK_REQ
);

logic [1:0] sr;

always_ff @(posedge CLK_I or posedge RST_ASYNC_I)
begin
    if (RST_ASYNC_I)
    begin
        sr <= 2'b00;
    end
    else begin
        sr <= {sr[0], SIGNAL};
    end
end

always_comb begin
    RISING = (sr == 2'b01);
    FALLING = (sr == 2'b10);
end

always_comb begin
    CLK_REQ = sr != {sr[0], SIGNAL};
end

endmodule

module nortl_delay #(
    parameter DATA_WIDTH = 1,
    parameter DELAY_STEPS = 2
) (
    input logic CLK_I,
    input logic RST_ASYNC_I,

    input  logic [DATA_WIDTH-1:0] IN,
    output logic [DATA_WIDTH-1:0] OUT,

    output logic CLK_REQ
);

logic [DATA_WIDTH-1:0] shiftreg [DELAY_STEPS-1:0];

always_ff @(posedge CLK_I or posedge RST_ASYNC_I) begin
    if (RST_ASYNC_I)
    begin
        for (int i=DELAY_STEPS-1; i>=0; i=i-1)
        begin
            shiftreg[i] <= {DATA_WIDTH{1'b0}};
        end
    end
    else begin
        if (DELAY_STEPS == 1)
        begin
            shiftreg[0] <= IN;
        end
        else begin
            for (int i=DELAY_STEPS-2; i>=0; i=i-1)
            begin
                shiftreg[i+1] <= shiftreg[i];
            end
            shiftreg[0] <= IN;
        end
    end
end

always_comb begin
    if (DELAY_STEPS == 1)
    begin
        OUT = shiftreg[0];
    end
    else begin
        OUT = shiftreg[DELAY_STEPS-1];
    end
end

always_comb begin
    CLK_REQ = 0;

    if (DELAY_STEPS == 1)
    begin
        CLK_REQ = CLK_REQ | (shiftreg[0] != IN);
    end
    else begin
        for (int i=DELAY_STEPS-2; i>=0; i=i-1)
        begin
            CLK_REQ = CLK_REQ | (shiftreg[i+1] != shiftreg[i]);
        end
        CLK_REQ = CLK_REQ | (shiftreg[0] != IN);
    end
end


endmodule

module nortl_count_down_timer #(
    parameter DATA_WIDTH = 16
) (
    input  logic CLK_I,
    input  logic RST_ASYNC_I,

    input  logic RELOAD,
    input  logic [DATA_WIDTH-1:0] DELAY,
    output logic ZERO,

    output logic CLK_REQ
);

logic [DATA_WIDTH-1:0] counter;

always_ff @(posedge CLK_I or posedge RST_ASYNC_I)
begin
    if (RST_ASYNC_I)
    begin
        counter <= 0;
    end
    else begin
        if (RELOAD)
        begin
            if (DELAY > 2)
            begin
                counter <= DELAY - 2;
            end
        end
        else if (counter != 0) begin
            counter <= counter - 1;
        end
    end
end

always_comb begin
    ZERO = (counter == 0) & ~RELOAD;

    if (DELAY == 1)
    begin
        ZERO = ~RELOAD;
    end
    if (DELAY == 0)
    begin
        ZERO = ~RELOAD;
    end
end

always_comb begin
    CLK_REQ = RELOAD | (counter > 0);
end

endmodule

module nortl_clock_gate (
    input logic CLK_I,
    input logic EN,
    output logic GCLK_O
);

logic enable_latch;

always_latch begin
    if (~CLK_I)
    begin
        enable_latch = EN;
    end
end

always_comb begin
    GCLK_O = enable_latch & CLK_I;
end

endmodule


module commodore  (input logic CLK_I,
input logic RST_ASYNC_I,
input logic [7:0] KEY_CODE,
input logic KEY_VALID,
output logic red,
output logic green,
output logic blue,
output logic vsync,
output logic hsync);
logic [5:0] memory_00_00;
logic [5:0] memory_00_01;
logic [5:0] memory_00_02;
logic [5:0] memory_00_03;
logic [5:0] memory_01_00;
logic [5:0] memory_01_01;
logic [5:0] memory_01_02;
logic [5:0] memory_01_03;
logic [1:0] col_cursor;
logic row_cursor;
logic [5:0] input_code;
logic [9:0] counter_v;
logic [9:0] counter_h;
logic stop_vga;
logic WORKER_1_reset;
logic WORKER_1_start;
logic [1-1:0] WORKER_1_select;
logic WORKER_1_idle;
logic EVENT_KEY_VALID_rising;
logic EVENT_KEY_VALID_falling;
enum {IDLE, STATE_1, STATE_2, STATE_3, STATE_4, STATE_5, STATE_6, STATE_7, STATE_8, STATE_9, STATE_10, STATE_11, STATE_12, STATE_13, STATE_14, STATE_15, STATE_16, STATE_17, STATE_18, STATE_19, STATE_20, STATE_21, STATE_22, STATE_23, STATE_24, STATE_25, STATE_26, STATE_27, STATE_28, STATE_29, STATE_30, STATE_31, STATE_32, STATE_33, STATE_34} state, state_nxt;
enum {WORKER_1_IDLE, WORKER_1_STATE_1, WORKER_1_STATE_2, WORKER_1_STATE_3, WORKER_1_STATE_4, WORKER_1_STATE_5} WORKER_1_state, WORKER_1_state_nxt;
nortl_edge_detector I_EVENT_EDGE_DETECTOR_KEY_VALID (.CLK_I(CLK_I), .RST_ASYNC_I(RST_ASYNC_I), .SIGNAL(KEY_VALID), .RISING(EVENT_KEY_VALID_rising), .FALLING(EVENT_KEY_VALID_falling));

always_comb
begin
   begin
      state_nxt = state;
   end
     case (state)
      IDLE: begin
         state_nxt = STATE_1;
      end
      STATE_2: begin
         state_nxt = STATE_3;
      end
      STATE_3: begin
         if (EVENT_KEY_VALID_rising)
         begin
            state_nxt = STATE_4;
         end
      end
      STATE_4: begin
         state_nxt = STATE_5;
      end
      STATE_5: begin
         if ((KEY_CODE == 8))
         begin
            state_nxt = STATE_7;
         end
         if (~((KEY_CODE == 8)))
         begin
            state_nxt = STATE_18;
         end
      end
      STATE_6: begin
         state_nxt = STATE_34;
      end
      STATE_7: begin
         if ((col_cursor == 0))
         begin
            state_nxt = STATE_9;
         end
         if (~((col_cursor == 0)))
         begin
            state_nxt = STATE_15;
         end
      end
      STATE_8: begin
         state_nxt = STATE_16;
      end
      STATE_9: begin
         if ((row_cursor != 0))
         begin
            state_nxt = STATE_11;
         end
         if (~((row_cursor != 0)))
         begin
            state_nxt = STATE_13;
         end
      end
      STATE_10: begin
         state_nxt = STATE_14;
      end
      STATE_11: begin
         state_nxt = STATE_12;
      end
      STATE_13, STATE_12: begin
         state_nxt = STATE_10;
      end
      STATE_15, STATE_14: begin
         state_nxt = STATE_8;
      end
      STATE_16: begin
         state_nxt = STATE_17;
      end
      STATE_18: begin
         if ((KEY_CODE == 127))
         begin
            state_nxt = STATE_20;
         end
         if (~((KEY_CODE == 127)))
         begin
            state_nxt = STATE_23;
         end
      end
      STATE_19: begin
         state_nxt = STATE_33;
      end
      STATE_20: begin
         state_nxt = STATE_21;
      end
      STATE_21: begin
         state_nxt = STATE_22;
      end
      STATE_23: begin
         state_nxt = STATE_24;
      end
      STATE_24: begin
         if ((col_cursor == 3))
         begin
            state_nxt = STATE_26;
         end
         if (~((col_cursor == 3)))
         begin
            state_nxt = STATE_31;
         end
      end
      STATE_25: begin
         state_nxt = STATE_32;
      end
      STATE_26: begin
         if ((row_cursor == 1))
         begin
            state_nxt = STATE_28;
         end
         if (~((row_cursor == 1)))
         begin
            state_nxt = STATE_29;
         end
      end
      STATE_27: begin
         state_nxt = STATE_30;
      end
      STATE_29, STATE_28: begin
         state_nxt = STATE_27;
      end
      STATE_31, STATE_30: begin
         state_nxt = STATE_25;
      end
      STATE_32, STATE_22: begin
         state_nxt = STATE_19;
      end
      STATE_33, STATE_17: begin
         state_nxt = STATE_6;
      end
      STATE_34, STATE_1: begin
         state_nxt = STATE_2;
      end
   endcase
   begin
      WORKER_1_state_nxt = WORKER_1_state;
   end
     case (WORKER_1_state)
      WORKER_1_IDLE: begin
         if ((WORKER_1_start & (WORKER_1_select == 1)))
         begin
            WORKER_1_state_nxt = WORKER_1_STATE_1;
         end
      end
      WORKER_1_STATE_2: begin
         WORKER_1_state_nxt = WORKER_1_STATE_3;
      end
      WORKER_1_STATE_3: begin
         if (stop_vga)
         begin
            WORKER_1_state_nxt = WORKER_1_STATE_5;
         end
      end
      WORKER_1_STATE_4, WORKER_1_STATE_1: begin
         WORKER_1_state_nxt = WORKER_1_STATE_2;
      end
      WORKER_1_STATE_5: begin
         WORKER_1_state_nxt = WORKER_1_STATE_4;
      end
   endcase
end

always_ff @(posedge CLK_I or posedge RST_ASYNC_I)
begin
   if (RST_ASYNC_I)
   begin
      memory_00_00 <= 0;
      memory_00_01 <= 0;
      memory_00_02 <= 0;
      memory_00_03 <= 0;
      memory_01_00 <= 0;
      memory_01_01 <= 0;
      memory_01_02 <= 0;
      memory_01_03 <= 0;
      col_cursor <= 0;
      row_cursor <= 0;
      input_code <= 0;
      counter_v <= 0;
      counter_h <= 0;
      stop_vga <= 0;
      red <= 0;
      green <= 0;
      blue <= 0;
      vsync <= 0;
      hsync <= 0;
      WORKER_1_reset <= 0;
      WORKER_1_start <= 0;
      WORKER_1_select <= 0;
      WORKER_1_idle <= 1;
   end
   else 
   begin
      WORKER_1_reset <= 0;
      WORKER_1_start <= 0;
        case (state_nxt)
         IDLE: begin
            memory_00_00 <= 0;
            memory_00_01 <= 0;
            memory_00_02 <= 0;
            memory_00_03 <= 0;
            memory_01_00 <= 0;
            memory_01_01 <= 0;
            memory_01_02 <= 0;
            memory_01_03 <= 0;
            col_cursor <= 0;
            row_cursor <= 0;
            input_code <= 0;
            counter_v <= 0;
            counter_h <= 0;
            stop_vga <= 0;
            red <= 0;
            green <= 0;
            blue <= 0;
            vsync <= 0;
            hsync <= 0;
            WORKER_1_reset <= 0;
            WORKER_1_start <= 0;
            WORKER_1_select <= 0;
            WORKER_1_idle <= 1;
         end
         STATE_1: begin
            WORKER_1_start <= 1;
            WORKER_1_select <= 1;
         end
         STATE_11: begin
            col_cursor <= 3;
         end
         STATE_12: begin
            row_cursor <= (row_cursor - 1);
         end
         STATE_13: begin
            col_cursor <= 0;
            row_cursor <= 0;
         end
         STATE_15: begin
            col_cursor <= (col_cursor - 1);
         end
         STATE_17: begin
            if (((row_cursor == 0) & (col_cursor == 0)))
            begin
               memory_00_00 <= 0;
            end
            if (((row_cursor == 0) & (col_cursor == 1)))
            begin
               memory_00_01 <= 0;
            end
            if (((row_cursor == 0) & (col_cursor == 2)))
            begin
               memory_00_02 <= 0;
            end
            if (((row_cursor == 0) & (col_cursor == 3)))
            begin
               memory_00_03 <= 0;
            end
            if (((row_cursor == 1) & (col_cursor == 0)))
            begin
               memory_01_00 <= 0;
            end
            if (((row_cursor == 1) & (col_cursor == 1)))
            begin
               memory_01_01 <= 0;
            end
            if (((row_cursor == 1) & (col_cursor == 2)))
            begin
               memory_01_02 <= 0;
            end
            if (((row_cursor == 1) & (col_cursor == 3)))
            begin
               memory_01_03 <= 0;
            end
         end
         STATE_20: begin
            memory_00_00 <= 0;
            memory_00_01 <= 0;
            memory_00_02 <= 0;
            memory_00_03 <= 0;
            memory_01_00 <= 0;
            memory_01_01 <= 0;
            memory_01_02 <= 0;
            memory_01_03 <= 0;
         end
         STATE_23: begin
            input_code <= ((KEY_CODE == 255) ? 31 : ((KEY_CODE == 254) ? 31 : ((KEY_CODE == 253) ? 31 : ((KEY_CODE == 252) ? 31 : ((KEY_CODE == 251) ? 31 : ((KEY_CODE == 250) ? 31 : ((KEY_CODE == 249) ? 31 : ((KEY_CODE == 248) ? 31 : ((KEY_CODE == 247) ? 31 : ((KEY_CODE == 246) ? 31 : ((KEY_CODE == 245) ? 31 : ((KEY_CODE == 244) ? 31 : ((KEY_CODE == 243) ? 31 : ((KEY_CODE == 242) ? 31 : ((KEY_CODE == 241) ? 31 : ((KEY_CODE == 240) ? 31 : ((KEY_CODE == 239) ? 31 : ((KEY_CODE == 238) ? 31 : ((KEY_CODE == 237) ? 31 : ((KEY_CODE == 236) ? 31 : ((KEY_CODE == 235) ? 31 : ((KEY_CODE == 234) ? 31 : ((KEY_CODE == 233) ? 31 : ((KEY_CODE == 232) ? 31 : ((KEY_CODE == 231) ? 31 : ((KEY_CODE == 230) ? 31 : ((KEY_CODE == 229) ? 31 : ((KEY_CODE == 228) ? 31 : ((KEY_CODE == 227) ? 31 : ((KEY_CODE == 226) ? 31 : ((KEY_CODE == 225) ? 31 : ((KEY_CODE == 224) ? 31 : ((KEY_CODE == 223) ? 31 : ((KEY_CODE == 222) ? 31 : ((KEY_CODE == 221) ? 31 : ((KEY_CODE == 220) ? 31 : ((KEY_CODE == 219) ? 31 : ((KEY_CODE == 218) ? 31 : ((KEY_CODE == 217) ? 31 : ((KEY_CODE == 216) ? 31 : ((KEY_CODE == 215) ? 31 : ((KEY_CODE == 214) ? 31 : ((KEY_CODE == 213) ? 31 : ((KEY_CODE == 212) ? 31 : ((KEY_CODE == 211) ? 31 : ((KEY_CODE == 210) ? 31 : ((KEY_CODE == 209) ? 31 : ((KEY_CODE == 208) ? 31 : ((KEY_CODE == 207) ? 31 : ((KEY_CODE == 206) ? 31 : ((KEY_CODE == 205) ? 31 : ((KEY_CODE == 204) ? 31 : ((KEY_CODE == 203) ? 31 : ((KEY_CODE == 202) ? 31 : ((KEY_CODE == 201) ? 31 : ((KEY_CODE == 200) ? 31 : ((KEY_CODE == 199) ? 31 : ((KEY_CODE == 198) ? 31 : ((KEY_CODE == 197) ? 31 : ((KEY_CODE == 196) ? 31 : ((KEY_CODE == 195) ? 31 : ((KEY_CODE == 194) ? 31 : ((KEY_CODE == 193) ? 31 : ((KEY_CODE == 192) ? 31 : ((KEY_CODE == 191) ? 31 : ((KEY_CODE == 190) ? 31 : ((KEY_CODE == 189) ? 31 : ((KEY_CODE == 188) ? 31 : ((KEY_CODE == 187) ? 31 : ((KEY_CODE == 186) ? 31 : ((KEY_CODE == 185) ? 31 : ((KEY_CODE == 184) ? 31 : ((KEY_CODE == 183) ? 31 : ((KEY_CODE == 182) ? 31 : ((KEY_CODE == 181) ? 31 : ((KEY_CODE == 180) ? 31 : ((KEY_CODE == 179) ? 31 : ((KEY_CODE == 178) ? 31 : ((KEY_CODE == 177) ? 31 : ((KEY_CODE == 176) ? 31 : ((KEY_CODE == 175) ? 31 : ((KEY_CODE == 174) ? 31 : ((KEY_CODE == 173) ? 31 : ((KEY_CODE == 172) ? 31 : ((KEY_CODE == 171) ? 31 : ((KEY_CODE == 170) ? 31 : ((KEY_CODE == 169) ? 31 : ((KEY_CODE == 168) ? 31 : ((KEY_CODE == 167) ? 31 : ((KEY_CODE == 166) ? 31 : ((KEY_CODE == 165) ? 31 : ((KEY_CODE == 164) ? 31 : ((KEY_CODE == 163) ? 31 : ((KEY_CODE == 162) ? 31 : ((KEY_CODE == 161) ? 31 : ((KEY_CODE == 160) ? 31 : ((KEY_CODE == 159) ? 31 : ((KEY_CODE == 158) ? 31 : ((KEY_CODE == 157) ? 31 : ((KEY_CODE == 156) ? 31 : ((KEY_CODE == 155) ? 31 : ((KEY_CODE == 154) ? 31 : ((KEY_CODE == 153) ? 31 : ((KEY_CODE == 152) ? 31 : ((KEY_CODE == 151) ? 31 : ((KEY_CODE == 150) ? 31 : ((KEY_CODE == 149) ? 31 : ((KEY_CODE == 148) ? 31 : ((KEY_CODE == 147) ? 31 : ((KEY_CODE == 146) ? 31 : ((KEY_CODE == 145) ? 31 : ((KEY_CODE == 144) ? 31 : ((KEY_CODE == 143) ? 31 : ((KEY_CODE == 142) ? 31 : ((KEY_CODE == 141) ? 31 : ((KEY_CODE == 140) ? 31 : ((KEY_CODE == 139) ? 31 : ((KEY_CODE == 138) ? 31 : ((KEY_CODE == 137) ? 31 : ((KEY_CODE == 136) ? 31 : ((KEY_CODE == 135) ? 31 : ((KEY_CODE == 134) ? 31 : ((KEY_CODE == 133) ? 31 : ((KEY_CODE == 132) ? 31 : ((KEY_CODE == 131) ? 31 : ((KEY_CODE == 130) ? 31 : ((KEY_CODE == 129) ? 31 : ((KEY_CODE == 128) ? 31 : ((KEY_CODE == 127) ? 31 : ((KEY_CODE == 126) ? 31 : ((KEY_CODE == 125) ? 31 : ((KEY_CODE == 124) ? 31 : ((KEY_CODE == 123) ? 31 : ((KEY_CODE == 122) ? 31 : ((KEY_CODE == 121) ? 31 : ((KEY_CODE == 120) ? 31 : ((KEY_CODE == 119) ? 31 : ((KEY_CODE == 118) ? 31 : ((KEY_CODE == 117) ? 31 : ((KEY_CODE == 116) ? 31 : ((KEY_CODE == 115) ? 31 : ((KEY_CODE == 114) ? 31 : ((KEY_CODE == 113) ? 31 : ((KEY_CODE == 112) ? 31 : ((KEY_CODE == 111) ? 31 : ((KEY_CODE == 110) ? 31 : ((KEY_CODE == 109) ? 31 : ((KEY_CODE == 108) ? 31 : ((KEY_CODE == 107) ? 31 : ((KEY_CODE == 106) ? 31 : ((KEY_CODE == 105) ? 31 : ((KEY_CODE == 104) ? 31 : ((KEY_CODE == 103) ? 31 : ((KEY_CODE == 102) ? 31 : ((KEY_CODE == 101) ? 31 : ((KEY_CODE == 100) ? 31 : ((KEY_CODE == 99) ? 31 : ((KEY_CODE == 98) ? 31 : ((KEY_CODE == 97) ? 31 : ((KEY_CODE == 96) ? 31 : ((KEY_CODE == 95) ? 31 : ((KEY_CODE == 94) ? 31 : ((KEY_CODE == 93) ? 61 : ((KEY_CODE == 92) ? 31 : ((KEY_CODE == 91) ? 59 : ((KEY_CODE == 90) ? 58 : ((KEY_CODE == 89) ? 57 : ((KEY_CODE == 88) ? 56 : ((KEY_CODE == 87) ? 55 : ((KEY_CODE == 86) ? 54 : ((KEY_CODE == 85) ? 53 : ((KEY_CODE == 84) ? 52 : ((KEY_CODE == 83) ? 51 : ((KEY_CODE == 82) ? 50 : ((KEY_CODE == 81) ? 49 : ((KEY_CODE == 80) ? 48 : ((KEY_CODE == 79) ? 47 : ((KEY_CODE == 78) ? 46 : ((KEY_CODE == 77) ? 45 : ((KEY_CODE == 76) ? 44 : ((KEY_CODE == 75) ? 43 : ((KEY_CODE == 74) ? 42 : ((KEY_CODE == 73) ? 41 : ((KEY_CODE == 72) ? 40 : ((KEY_CODE == 71) ? 39 : ((KEY_CODE == 70) ? 38 : ((KEY_CODE == 69) ? 37 : ((KEY_CODE == 68) ? 36 : ((KEY_CODE == 67) ? 35 : ((KEY_CODE == 66) ? 34 : ((KEY_CODE == 65) ? 33 : ((KEY_CODE == 64) ? 32 : ((KEY_CODE == 63) ? 31 : ((KEY_CODE == 62) ? 30 : ((KEY_CODE == 61) ? 29 : ((KEY_CODE == 60) ? 28 : ((KEY_CODE == 59) ? 27 : ((KEY_CODE == 58) ? 26 : ((KEY_CODE == 57) ? 25 : ((KEY_CODE == 56) ? 24 : ((KEY_CODE == 55) ? 23 : ((KEY_CODE == 54) ? 22 : ((KEY_CODE == 53) ? 21 : ((KEY_CODE == 52) ? 20 : ((KEY_CODE == 51) ? 19 : ((KEY_CODE == 50) ? 18 : ((KEY_CODE == 49) ? 17 : ((KEY_CODE == 48) ? 16 : ((KEY_CODE == 47) ? 15 : ((KEY_CODE == 46) ? 14 : ((KEY_CODE == 45) ? 13 : ((KEY_CODE == 44) ? 12 : ((KEY_CODE == 43) ? 11 : ((KEY_CODE == 42) ? 10 : ((KEY_CODE == 41) ? 9 : ((KEY_CODE == 40) ? 8 : ((KEY_CODE == 39) ? 7 : ((KEY_CODE == 38) ? 6 : ((KEY_CODE == 37) ? 5 : ((KEY_CODE == 36) ? 31 : ((KEY_CODE == 35) ? 31 : ((KEY_CODE == 34) ? 2 : ((KEY_CODE == 33) ? 1 : ((KEY_CODE == 32) ? 0 : 31))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))));
         end
         STATE_24: begin
            if (((row_cursor == 0) & (col_cursor == 0)))
            begin
               memory_00_00 <= input_code;
            end
            if (((row_cursor == 0) & (col_cursor == 1)))
            begin
               memory_00_01 <= input_code;
            end
            if (((row_cursor == 0) & (col_cursor == 2)))
            begin
               memory_00_02 <= input_code;
            end
            if (((row_cursor == 0) & (col_cursor == 3)))
            begin
               memory_00_03 <= input_code;
            end
            if (((row_cursor == 1) & (col_cursor == 0)))
            begin
               memory_01_00 <= input_code;
            end
            if (((row_cursor == 1) & (col_cursor == 1)))
            begin
               memory_01_01 <= input_code;
            end
            if (((row_cursor == 1) & (col_cursor == 2)))
            begin
               memory_01_02 <= input_code;
            end
            if (((row_cursor == 1) & (col_cursor == 3)))
            begin
               memory_01_03 <= input_code;
            end
         end
         STATE_26, STATE_21: begin
            col_cursor <= 0;
         end
         STATE_28, STATE_22: begin
            row_cursor <= 0;
         end
         STATE_29: begin
            row_cursor <= (row_cursor + 1);
         end
         STATE_31: begin
            col_cursor <= (col_cursor + 1);
         end
      endcase
        case (WORKER_1_state_nxt)
         WORKER_1_STATE_1: begin
            WORKER_1_idle <= 0;
         end
         WORKER_1_STATE_3: begin
            counter_h <= ((counter_h == 799) ? 0 : (counter_h + 1));
            if (((counter_h == 799) && (counter_v == 520)))
            begin
               counter_v <= 0;
            end
            else if ((counter_h == 799))
            begin
               counter_v <= (counter_v + 1);
            end
            else 
            begin
               counter_v <= counter_v;
            end
            if ((counter_h < 656))
            begin
               hsync <= 1;
            end
            else if ((counter_h > 751))
            begin
               hsync <= 1;
            end
            else 
            begin
               hsync <= 0;
            end
            if ((counter_v < 490))
            begin
               vsync <= 1;
            end
            else if ((counter_v > 491))
            begin
               vsync <= 1;
            end
            else 
            begin
               vsync <= 0;
            end
            red <= (((((counter_h < 640) && (counter_v < 400)) ? ((((((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 63) ? 64'h003C66060C180018 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 62) ? 64'h003C66060C180018 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 61) ? 64'h003C0C0C0C0C3C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 60) ? 64'h003C66060C180018 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 59) ? 64'h003C303030303C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 58) ? 64'h007E060C18307E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 57) ? 64'h0066663C18181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 56) ? 64'h0066663C183C6666 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 55) ? 64'h0063636B7F776300 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 54) ? 64'h00666666663C1800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 53) ? 64'h0066666666663C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 52) ? 64'h007E181818181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 51) ? 64'h003E603C06067C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 50) ? 64'h007C667C6C666600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 49) ? 64'h003C6666666E3C0E : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 48) ? 64'h007C667C60606000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 47) ? 64'h003C666666663C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 46) ? 64'h0066767E6E666600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 45) ? 64'h0063777F6B636300 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 44) ? 64'h0060606060607E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 43) ? 64'h00666C78786C6600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 42) ? 64'h001E060606663C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 41) ? 64'h003E0C0C0C0C3E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 40) ? 64'h0066667E66666600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 39) ? 64'h003E606E66663E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 38) ? 64'h007E607860606000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 37) ? 64'h007E607C60607E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 36) ? 64'h00786C66666C7800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 35) ? 64'h003E606060603E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 34) ? 64'h007C667C66667C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 33) ? 64'h00183C667E666600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 32) ? 64'h003C665E563A063C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 31) ? 64'h003C66060C180018 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 30) ? 64'h0060380C0C386000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 29) ? 64'h00003E003E000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 28) ? 64'h00061C30301C0600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 27) ? 64'h0000181800181808 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 26) ? 64'h0000181800181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 25) ? 64'h003C66663E06663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 24) ? 64'h003C66663C66663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 23) ? 64'h007E66060C181818 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 22) ? 64'h003C66607C66663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 21) ? 64'h007F607C0606663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 20) ? 64'h00060E1E667F0606 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 19) ? 64'h003C66061C06663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 18) ? 64'h003C66061C30667E : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 17) ? 64'h0018381818181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 16) ? 64'h003C666E7E76663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 15) ? 64'h0002060C18306000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 14) ? 64'h0000000000181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 13) ? 64'h000000003E000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 12) ? 64'h0000000000181808 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 11) ? 64'h000018187E181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 10) ? 64'h000024187E182400 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 9) ? 64'h0030181818183000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 8) ? 64'h000C181818180C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 7) ? 64'h0018180800000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 6) ? 64'h00386C38766C3A00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 5) ? 64'h0062660C18332300 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 4) ? 64'h0000000000000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 3) ? 64'h0000000000000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 2) ? 64'h0024242400000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 1) ? 64'h0018181818001800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 0) ? 64'h0000000000000000 : 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >> (((~(((counter_v >> 1) & 7)) & 7) << 3) | (~(((counter_h >> 1) & 7)) & 7))) & 1) != 0) ? 3'h7 : 3'h0) : 3'h0) & 4) != 0);
            green <= (((((counter_h < 640) && (counter_v < 400)) ? ((((((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 63) ? 64'h003C66060C180018 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 62) ? 64'h003C66060C180018 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 61) ? 64'h003C0C0C0C0C3C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 60) ? 64'h003C66060C180018 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 59) ? 64'h003C303030303C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 58) ? 64'h007E060C18307E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 57) ? 64'h0066663C18181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 56) ? 64'h0066663C183C6666 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 55) ? 64'h0063636B7F776300 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 54) ? 64'h00666666663C1800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 53) ? 64'h0066666666663C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 52) ? 64'h007E181818181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 51) ? 64'h003E603C06067C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 50) ? 64'h007C667C6C666600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 49) ? 64'h003C6666666E3C0E : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 48) ? 64'h007C667C60606000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 47) ? 64'h003C666666663C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 46) ? 64'h0066767E6E666600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 45) ? 64'h0063777F6B636300 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 44) ? 64'h0060606060607E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 43) ? 64'h00666C78786C6600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 42) ? 64'h001E060606663C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 41) ? 64'h003E0C0C0C0C3E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 40) ? 64'h0066667E66666600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 39) ? 64'h003E606E66663E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 38) ? 64'h007E607860606000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 37) ? 64'h007E607C60607E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 36) ? 64'h00786C66666C7800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 35) ? 64'h003E606060603E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 34) ? 64'h007C667C66667C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 33) ? 64'h00183C667E666600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 32) ? 64'h003C665E563A063C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 31) ? 64'h003C66060C180018 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 30) ? 64'h0060380C0C386000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 29) ? 64'h00003E003E000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 28) ? 64'h00061C30301C0600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 27) ? 64'h0000181800181808 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 26) ? 64'h0000181800181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 25) ? 64'h003C66663E06663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 24) ? 64'h003C66663C66663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 23) ? 64'h007E66060C181818 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 22) ? 64'h003C66607C66663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 21) ? 64'h007F607C0606663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 20) ? 64'h00060E1E667F0606 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 19) ? 64'h003C66061C06663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 18) ? 64'h003C66061C30667E : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 17) ? 64'h0018381818181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 16) ? 64'h003C666E7E76663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 15) ? 64'h0002060C18306000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 14) ? 64'h0000000000181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 13) ? 64'h000000003E000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 12) ? 64'h0000000000181808 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 11) ? 64'h000018187E181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 10) ? 64'h000024187E182400 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 9) ? 64'h0030181818183000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 8) ? 64'h000C181818180C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 7) ? 64'h0018180800000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 6) ? 64'h00386C38766C3A00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 5) ? 64'h0062660C18332300 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 4) ? 64'h0000000000000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 3) ? 64'h0000000000000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 2) ? 64'h0024242400000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 1) ? 64'h0018181818001800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 0) ? 64'h0000000000000000 : 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >> (((~(((counter_v >> 1) & 7)) & 7) << 3) | (~(((counter_h >> 1) & 7)) & 7))) & 1) != 0) ? 3'h7 : 3'h0) : 3'h0) & 2) != 0);
            blue <= (((((counter_h < 640) && (counter_v < 400)) ? ((((((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 63) ? 64'h003C66060C180018 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 62) ? 64'h003C66060C180018 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 61) ? 64'h003C0C0C0C0C3C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 60) ? 64'h003C66060C180018 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 59) ? 64'h003C303030303C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 58) ? 64'h007E060C18307E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 57) ? 64'h0066663C18181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 56) ? 64'h0066663C183C6666 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 55) ? 64'h0063636B7F776300 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 54) ? 64'h00666666663C1800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 53) ? 64'h0066666666663C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 52) ? 64'h007E181818181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 51) ? 64'h003E603C06067C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 50) ? 64'h007C667C6C666600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 49) ? 64'h003C6666666E3C0E : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 48) ? 64'h007C667C60606000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 47) ? 64'h003C666666663C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 46) ? 64'h0066767E6E666600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 45) ? 64'h0063777F6B636300 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 44) ? 64'h0060606060607E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 43) ? 64'h00666C78786C6600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 42) ? 64'h001E060606663C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 41) ? 64'h003E0C0C0C0C3E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 40) ? 64'h0066667E66666600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 39) ? 64'h003E606E66663E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 38) ? 64'h007E607860606000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 37) ? 64'h007E607C60607E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 36) ? 64'h00786C66666C7800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 35) ? 64'h003E606060603E00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 34) ? 64'h007C667C66667C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 33) ? 64'h00183C667E666600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 32) ? 64'h003C665E563A063C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 31) ? 64'h003C66060C180018 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 30) ? 64'h0060380C0C386000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 29) ? 64'h00003E003E000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 28) ? 64'h00061C30301C0600 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 27) ? 64'h0000181800181808 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 26) ? 64'h0000181800181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 25) ? 64'h003C66663E06663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 24) ? 64'h003C66663C66663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 23) ? 64'h007E66060C181818 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 22) ? 64'h003C66607C66663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 21) ? 64'h007F607C0606663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 20) ? 64'h00060E1E667F0606 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 19) ? 64'h003C66061C06663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 18) ? 64'h003C66061C30667E : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 17) ? 64'h0018381818181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 16) ? 64'h003C666E7E76663C : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 15) ? 64'h0002060C18306000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 14) ? 64'h0000000000181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 13) ? 64'h000000003E000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 12) ? 64'h0000000000181808 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 11) ? 64'h000018187E181800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 10) ? 64'h000024187E182400 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 9) ? 64'h0030181818183000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 8) ? 64'h000C181818180C00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 7) ? 64'h0018180800000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 6) ? 64'h00386C38766C3A00 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 5) ? 64'h0062660C18332300 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 4) ? 64'h0000000000000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 3) ? 64'h0000000000000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 2) ? 64'h0024242400000000 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 1) ? 64'h0018181818001800 : ((((((counter_v >> 1) >> 3) == 1) ? ((((counter_h >> 1) >> 3) == 3) ? memory_01_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_01_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_01_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_01_00 : 6'h00)))) : ((((counter_v >> 1) >> 3) == 0) ? ((((counter_h >> 1) >> 3) == 3) ? memory_00_03 : ((((counter_h >> 1) >> 3) == 2) ? memory_00_02 : ((((counter_h >> 1) >> 3) == 1) ? memory_00_01 : ((((counter_h >> 1) >> 3) == 0) ? memory_00_00 : 6'h00)))) : 6'h00)) == 0) ? 64'h0000000000000000 : 0)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) >> (((~(((counter_v >> 1) & 7)) & 7) << 3) | (~(((counter_h >> 1) & 7)) & 7))) & 1) != 0) ? 3'h7 : 3'h0) : 3'h0) & 1) != 0);
         end
      endcase
   end
end
// synthesis translate_off

always_ff @(posedge CLK_I or posedge RST_ASYNC_I)
begin
   if (RST_ASYNC_I)
   begin
      
   end
   else 
   begin
      
      
   end
end
// synthesis translate_on

always_comb
begin
   
end

always_ff @(posedge CLK_I or posedge RST_ASYNC_I)
begin
   if (RST_ASYNC_I)
   begin
      state <= IDLE;
   end
   else 
   begin
      if (0)
      begin
         state <= IDLE;
      end
      else 
      begin
         state <= state_nxt;
      end
   end
end

always_ff @(posedge CLK_I or posedge RST_ASYNC_I)
begin
   if (RST_ASYNC_I)
   begin
      WORKER_1_state <= WORKER_1_IDLE;
   end
   else 
   begin
      if (WORKER_1_reset)
      begin
         WORKER_1_state <= WORKER_1_IDLE;
      end
      else 
      begin
         WORKER_1_state <= WORKER_1_state_nxt;
      end
   end
end
endmodule