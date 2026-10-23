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
output logic red,
output logic green,
output logic blue,
output logic vsync,
output logic hsync,
input logic BIT_INPUT);
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
logic [15:0] RX_COUNTER;
logic [3:0] RX_BIT_IDX;
logic [7:0] RX_SHIFT;
logic [7:0] RX_BYTE;
logic WORKER_1_reset;
logic WORKER_1_start;
logic [1-1:0] WORKER_1_select;
logic WORKER_1_idle;
logic EVENT_BIT_INPUT_rising;
logic EVENT_BIT_INPUT_falling;
logic [1-1:0] RETURN_ADDRESS;
logic [1-1:0] BACKUP_ADDRESS_ZONE1;
logic [1-1:0] BACKUP_ADDRESS_ZONE2;
enum {IDLE, STATE_1, STATE_2, STATE_3, STATE_4, STATE_5, STATE_6, STATE_7, STATE_8, STATE_9, STATE_10, STATE_11, STATE_12, STATE_13, STATE_14, STATE_15, STATE_16, STATE_17, STATE_18, STATE_19, STATE_20, STATE_21, STATE_22, STATE_23, STATE_24, STATE_25, STATE_26, STATE_27, STATE_28, STATE_29, STATE_30, STATE_31, STATE_32, STATE_33, STATE_34, STATE_35, STATE_36, STATE_37, STATE_38, STATE_39, STATE_40, STATE_41, STATE_42, STATE_43, STATE_44, STATE_45, STATE_46, STATE_47, STATE_48, STATE_49, STATE_50, STATE_51} state, state_nxt;
enum {WORKER_1_IDLE, WORKER_1_STATE_1, WORKER_1_STATE_2, WORKER_1_STATE_3, WORKER_1_STATE_4, WORKER_1_STATE_5} WORKER_1_state, WORKER_1_state_nxt;
nortl_edge_detector I_EVENT_EDGE_DETECTOR_BIT_INPUT (.CLK_I(CLK_I), .RST_ASYNC_I(RST_ASYNC_I), .SIGNAL(BIT_INPUT), .RISING(EVENT_BIT_INPUT_rising), .FALLING(EVENT_BIT_INPUT_falling));

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
         if (EVENT_BIT_INPUT_falling)
         begin
            state_nxt = STATE_4;
         end
      end
      STATE_4: begin
         state_nxt = STATE_5;
      end
      STATE_6: begin
         if ((RX_COUNTER != 0))
         begin
            state_nxt = STATE_8;
         end
         if (~((RX_COUNTER != 0)))
         begin
            state_nxt = STATE_7;
         end
      end
      STATE_7: begin
         if ((RETURN_ADDRESS == 0))
         begin
            state_nxt = STATE_10;
         end
      end
      STATE_8: begin
         state_nxt = STATE_9;
      end
      STATE_9, STATE_5: begin
         state_nxt = STATE_6;
      end
      STATE_10: begin
         if ((RX_BIT_IDX != 8))
         begin
            state_nxt = STATE_12;
         end
         if (~((RX_BIT_IDX != 8)))
         begin
            state_nxt = STATE_11;
         end
      end
      STATE_11: begin
         state_nxt = STATE_19;
      end
      STATE_12: begin
         state_nxt = STATE_13;
      end
      STATE_14: begin
         if ((RX_COUNTER != 0))
         begin
            state_nxt = STATE_16;
         end
         if (~((RX_COUNTER != 0)))
         begin
            state_nxt = STATE_15;
         end
      end
      STATE_15: begin
         if ((RETURN_ADDRESS == 0))
         begin
            state_nxt = STATE_18;
         end
      end
      STATE_16: begin
         state_nxt = STATE_17;
      end
      STATE_17, STATE_13: begin
         state_nxt = STATE_14;
      end
      STATE_18: begin
         state_nxt = STATE_10;
      end
      STATE_19: begin
         state_nxt = STATE_20;
      end
      STATE_20: begin
         if ((RX_BYTE == 8))
         begin
            state_nxt = STATE_22;
         end
         if (~((RX_BYTE == 8)))
         begin
            state_nxt = STATE_33;
         end
      end
      STATE_21: begin
         state_nxt = STATE_51;
      end
      STATE_22: begin
         if ((col_cursor == 0))
         begin
            state_nxt = STATE_24;
         end
         if (~((col_cursor == 0)))
         begin
            state_nxt = STATE_30;
         end
      end
      STATE_23: begin
         state_nxt = STATE_31;
      end
      STATE_24: begin
         if ((row_cursor != 0))
         begin
            state_nxt = STATE_26;
         end
         if (~((row_cursor != 0)))
         begin
            state_nxt = STATE_28;
         end
      end
      STATE_25: begin
         state_nxt = STATE_29;
      end
      STATE_26: begin
         state_nxt = STATE_27;
      end
      STATE_28, STATE_27: begin
         state_nxt = STATE_25;
      end
      STATE_30, STATE_29: begin
         state_nxt = STATE_23;
      end
      STATE_31: begin
         state_nxt = STATE_32;
      end
      STATE_33: begin
         if ((RX_BYTE == 127))
         begin
            state_nxt = STATE_35;
         end
         if (~((RX_BYTE == 127)))
         begin
            state_nxt = STATE_40;
         end
      end
      STATE_34: begin
         state_nxt = STATE_50;
      end
      STATE_35: begin
         state_nxt = STATE_36;
      end
      STATE_36: begin
         if ((RETURN_ADDRESS == 0))
         begin
            state_nxt = STATE_37;
         end
      end
      STATE_37: begin
         state_nxt = STATE_38;
      end
      STATE_38: begin
         state_nxt = STATE_39;
      end
      STATE_40: begin
         state_nxt = STATE_41;
      end
      STATE_41: begin
         if ((col_cursor == 3))
         begin
            state_nxt = STATE_43;
         end
         if (~((col_cursor == 3)))
         begin
            state_nxt = STATE_48;
         end
      end
      STATE_42: begin
         state_nxt = STATE_49;
      end
      STATE_43: begin
         if ((row_cursor == 1))
         begin
            state_nxt = STATE_45;
         end
         if (~((row_cursor == 1)))
         begin
            state_nxt = STATE_46;
         end
      end
      STATE_44: begin
         state_nxt = STATE_47;
      end
      STATE_46, STATE_45: begin
         state_nxt = STATE_44;
      end
      STATE_48, STATE_47: begin
         state_nxt = STATE_42;
      end
      STATE_49, STATE_39: begin
         state_nxt = STATE_34;
      end
      STATE_50, STATE_32: begin
         state_nxt = STATE_21;
      end
      STATE_51, STATE_1: begin
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
      RX_COUNTER <= 0;
      RX_BIT_IDX <= 0;
      RX_SHIFT <= 0;
      RX_BYTE <= 0;
      WORKER_1_reset <= 0;
      WORKER_1_start <= 0;
      WORKER_1_select <= 0;
      WORKER_1_idle <= 1;
      RETURN_ADDRESS <= 0;
      BACKUP_ADDRESS_ZONE1 <= 0;
      BACKUP_ADDRESS_ZONE2 <= 0;
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
            RX_COUNTER <= 0;
            RX_BIT_IDX <= 0;
            RX_SHIFT <= 0;
            RX_BYTE <= 0;
            WORKER_1_reset <= 0;
            WORKER_1_start <= 0;
            WORKER_1_select <= 0;
            WORKER_1_idle <= 1;
            RETURN_ADDRESS <= 0;
            BACKUP_ADDRESS_ZONE1 <= 0;
            BACKUP_ADDRESS_ZONE2 <= 0;
         end
         STATE_1: begin
            WORKER_1_start <= 1;
            WORKER_1_select <= 1;
         end
         STATE_4: begin
            RETURN_ADDRESS <= 0;
            BACKUP_ADDRESS_ZONE1 <= RETURN_ADDRESS;
         end
         STATE_5: begin
            RX_COUNTER <= 92;
         end
         STATE_10: begin
            RETURN_ADDRESS <= BACKUP_ADDRESS_ZONE1;
            RX_BIT_IDX <= 0;
         end
         STATE_11: begin
            RX_BYTE <= RX_SHIFT;
         end
         STATE_12: begin
            RX_SHIFT <= ((RX_SHIFT >> 1) | (BIT_INPUT ? 8'h80 : 8'h00));
            RX_BIT_IDX <= (RX_BIT_IDX + 1);
            RETURN_ADDRESS <= 0;
            BACKUP_ADDRESS_ZONE1 <= RETURN_ADDRESS;
         end
         STATE_13: begin
            RX_COUNTER <= 63;
         end
         STATE_16, STATE_8: begin
            RX_COUNTER <= (RX_COUNTER - 1);
         end
         STATE_18: begin
            RETURN_ADDRESS <= BACKUP_ADDRESS_ZONE1;
         end
         STATE_26: begin
            col_cursor <= 3;
         end
         STATE_27: begin
            row_cursor <= (row_cursor - 1);
         end
         STATE_28: begin
            col_cursor <= 0;
            row_cursor <= 0;
         end
         STATE_30: begin
            col_cursor <= (col_cursor - 1);
         end
         STATE_32: begin
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
         STATE_35: begin
            RETURN_ADDRESS <= 0;
            BACKUP_ADDRESS_ZONE2 <= RETURN_ADDRESS;
         end
         STATE_36: begin
            memory_00_00 <= 0;
            memory_00_01 <= 0;
            memory_00_02 <= 0;
            memory_00_03 <= 0;
            memory_01_00 <= 0;
            memory_01_01 <= 0;
            memory_01_02 <= 0;
            memory_01_03 <= 0;
         end
         STATE_37: begin
            RETURN_ADDRESS <= BACKUP_ADDRESS_ZONE2;
         end
         STATE_40: begin
            input_code <= ((RX_BYTE == 255) ? 31 : ((RX_BYTE == 254) ? 31 : ((RX_BYTE == 253) ? 31 : ((RX_BYTE == 252) ? 31 : ((RX_BYTE == 251) ? 31 : ((RX_BYTE == 250) ? 31 : ((RX_BYTE == 249) ? 31 : ((RX_BYTE == 248) ? 31 : ((RX_BYTE == 247) ? 31 : ((RX_BYTE == 246) ? 31 : ((RX_BYTE == 245) ? 31 : ((RX_BYTE == 244) ? 31 : ((RX_BYTE == 243) ? 31 : ((RX_BYTE == 242) ? 31 : ((RX_BYTE == 241) ? 31 : ((RX_BYTE == 240) ? 31 : ((RX_BYTE == 239) ? 31 : ((RX_BYTE == 238) ? 31 : ((RX_BYTE == 237) ? 31 : ((RX_BYTE == 236) ? 31 : ((RX_BYTE == 235) ? 31 : ((RX_BYTE == 234) ? 31 : ((RX_BYTE == 233) ? 31 : ((RX_BYTE == 232) ? 31 : ((RX_BYTE == 231) ? 31 : ((RX_BYTE == 230) ? 31 : ((RX_BYTE == 229) ? 31 : ((RX_BYTE == 228) ? 31 : ((RX_BYTE == 227) ? 31 : ((RX_BYTE == 226) ? 31 : ((RX_BYTE == 225) ? 31 : ((RX_BYTE == 224) ? 31 : ((RX_BYTE == 223) ? 31 : ((RX_BYTE == 222) ? 31 : ((RX_BYTE == 221) ? 31 : ((RX_BYTE == 220) ? 31 : ((RX_BYTE == 219) ? 31 : ((RX_BYTE == 218) ? 31 : ((RX_BYTE == 217) ? 31 : ((RX_BYTE == 216) ? 31 : ((RX_BYTE == 215) ? 31 : ((RX_BYTE == 214) ? 31 : ((RX_BYTE == 213) ? 31 : ((RX_BYTE == 212) ? 31 : ((RX_BYTE == 211) ? 31 : ((RX_BYTE == 210) ? 31 : ((RX_BYTE == 209) ? 31 : ((RX_BYTE == 208) ? 31 : ((RX_BYTE == 207) ? 31 : ((RX_BYTE == 206) ? 31 : ((RX_BYTE == 205) ? 31 : ((RX_BYTE == 204) ? 31 : ((RX_BYTE == 203) ? 31 : ((RX_BYTE == 202) ? 31 : ((RX_BYTE == 201) ? 31 : ((RX_BYTE == 200) ? 31 : ((RX_BYTE == 199) ? 31 : ((RX_BYTE == 198) ? 31 : ((RX_BYTE == 197) ? 31 : ((RX_BYTE == 196) ? 31 : ((RX_BYTE == 195) ? 31 : ((RX_BYTE == 194) ? 31 : ((RX_BYTE == 193) ? 31 : ((RX_BYTE == 192) ? 31 : ((RX_BYTE == 191) ? 31 : ((RX_BYTE == 190) ? 31 : ((RX_BYTE == 189) ? 31 : ((RX_BYTE == 188) ? 31 : ((RX_BYTE == 187) ? 31 : ((RX_BYTE == 186) ? 31 : ((RX_BYTE == 185) ? 31 : ((RX_BYTE == 184) ? 31 : ((RX_BYTE == 183) ? 31 : ((RX_BYTE == 182) ? 31 : ((RX_BYTE == 181) ? 31 : ((RX_BYTE == 180) ? 31 : ((RX_BYTE == 179) ? 31 : ((RX_BYTE == 178) ? 31 : ((RX_BYTE == 177) ? 31 : ((RX_BYTE == 176) ? 31 : ((RX_BYTE == 175) ? 31 : ((RX_BYTE == 174) ? 31 : ((RX_BYTE == 173) ? 31 : ((RX_BYTE == 172) ? 31 : ((RX_BYTE == 171) ? 31 : ((RX_BYTE == 170) ? 31 : ((RX_BYTE == 169) ? 31 : ((RX_BYTE == 168) ? 31 : ((RX_BYTE == 167) ? 31 : ((RX_BYTE == 166) ? 31 : ((RX_BYTE == 165) ? 31 : ((RX_BYTE == 164) ? 31 : ((RX_BYTE == 163) ? 31 : ((RX_BYTE == 162) ? 31 : ((RX_BYTE == 161) ? 31 : ((RX_BYTE == 160) ? 31 : ((RX_BYTE == 159) ? 31 : ((RX_BYTE == 158) ? 31 : ((RX_BYTE == 157) ? 31 : ((RX_BYTE == 156) ? 31 : ((RX_BYTE == 155) ? 31 : ((RX_BYTE == 154) ? 31 : ((RX_BYTE == 153) ? 31 : ((RX_BYTE == 152) ? 31 : ((RX_BYTE == 151) ? 31 : ((RX_BYTE == 150) ? 31 : ((RX_BYTE == 149) ? 31 : ((RX_BYTE == 148) ? 31 : ((RX_BYTE == 147) ? 31 : ((RX_BYTE == 146) ? 31 : ((RX_BYTE == 145) ? 31 : ((RX_BYTE == 144) ? 31 : ((RX_BYTE == 143) ? 31 : ((RX_BYTE == 142) ? 31 : ((RX_BYTE == 141) ? 31 : ((RX_BYTE == 140) ? 31 : ((RX_BYTE == 139) ? 31 : ((RX_BYTE == 138) ? 31 : ((RX_BYTE == 137) ? 31 : ((RX_BYTE == 136) ? 31 : ((RX_BYTE == 135) ? 31 : ((RX_BYTE == 134) ? 31 : ((RX_BYTE == 133) ? 31 : ((RX_BYTE == 132) ? 31 : ((RX_BYTE == 131) ? 31 : ((RX_BYTE == 130) ? 31 : ((RX_BYTE == 129) ? 31 : ((RX_BYTE == 128) ? 31 : ((RX_BYTE == 127) ? 31 : ((RX_BYTE == 126) ? 31 : ((RX_BYTE == 125) ? 31 : ((RX_BYTE == 124) ? 31 : ((RX_BYTE == 123) ? 31 : ((RX_BYTE == 122) ? 31 : ((RX_BYTE == 121) ? 31 : ((RX_BYTE == 120) ? 31 : ((RX_BYTE == 119) ? 31 : ((RX_BYTE == 118) ? 31 : ((RX_BYTE == 117) ? 31 : ((RX_BYTE == 116) ? 31 : ((RX_BYTE == 115) ? 31 : ((RX_BYTE == 114) ? 31 : ((RX_BYTE == 113) ? 31 : ((RX_BYTE == 112) ? 31 : ((RX_BYTE == 111) ? 31 : ((RX_BYTE == 110) ? 31 : ((RX_BYTE == 109) ? 31 : ((RX_BYTE == 108) ? 31 : ((RX_BYTE == 107) ? 31 : ((RX_BYTE == 106) ? 31 : ((RX_BYTE == 105) ? 31 : ((RX_BYTE == 104) ? 31 : ((RX_BYTE == 103) ? 31 : ((RX_BYTE == 102) ? 31 : ((RX_BYTE == 101) ? 31 : ((RX_BYTE == 100) ? 31 : ((RX_BYTE == 99) ? 31 : ((RX_BYTE == 98) ? 31 : ((RX_BYTE == 97) ? 31 : ((RX_BYTE == 96) ? 31 : ((RX_BYTE == 95) ? 31 : ((RX_BYTE == 94) ? 31 : ((RX_BYTE == 93) ? 61 : ((RX_BYTE == 92) ? 31 : ((RX_BYTE == 91) ? 59 : ((RX_BYTE == 90) ? 58 : ((RX_BYTE == 89) ? 57 : ((RX_BYTE == 88) ? 56 : ((RX_BYTE == 87) ? 55 : ((RX_BYTE == 86) ? 54 : ((RX_BYTE == 85) ? 53 : ((RX_BYTE == 84) ? 52 : ((RX_BYTE == 83) ? 51 : ((RX_BYTE == 82) ? 50 : ((RX_BYTE == 81) ? 49 : ((RX_BYTE == 80) ? 48 : ((RX_BYTE == 79) ? 47 : ((RX_BYTE == 78) ? 46 : ((RX_BYTE == 77) ? 45 : ((RX_BYTE == 76) ? 44 : ((RX_BYTE == 75) ? 43 : ((RX_BYTE == 74) ? 42 : ((RX_BYTE == 73) ? 41 : ((RX_BYTE == 72) ? 40 : ((RX_BYTE == 71) ? 39 : ((RX_BYTE == 70) ? 38 : ((RX_BYTE == 69) ? 37 : ((RX_BYTE == 68) ? 36 : ((RX_BYTE == 67) ? 35 : ((RX_BYTE == 66) ? 34 : ((RX_BYTE == 65) ? 33 : ((RX_BYTE == 64) ? 32 : ((RX_BYTE == 63) ? 31 : ((RX_BYTE == 62) ? 30 : ((RX_BYTE == 61) ? 29 : ((RX_BYTE == 60) ? 28 : ((RX_BYTE == 59) ? 27 : ((RX_BYTE == 58) ? 26 : ((RX_BYTE == 57) ? 25 : ((RX_BYTE == 56) ? 24 : ((RX_BYTE == 55) ? 23 : ((RX_BYTE == 54) ? 22 : ((RX_BYTE == 53) ? 21 : ((RX_BYTE == 52) ? 20 : ((RX_BYTE == 51) ? 19 : ((RX_BYTE == 50) ? 18 : ((RX_BYTE == 49) ? 17 : ((RX_BYTE == 48) ? 16 : ((RX_BYTE == 47) ? 15 : ((RX_BYTE == 46) ? 14 : ((RX_BYTE == 45) ? 13 : ((RX_BYTE == 44) ? 12 : ((RX_BYTE == 43) ? 11 : ((RX_BYTE == 42) ? 10 : ((RX_BYTE == 41) ? 9 : ((RX_BYTE == 40) ? 8 : ((RX_BYTE == 39) ? 7 : ((RX_BYTE == 38) ? 6 : ((RX_BYTE == 37) ? 5 : ((RX_BYTE == 36) ? 31 : ((RX_BYTE == 35) ? 31 : ((RX_BYTE == 34) ? 2 : ((RX_BYTE == 33) ? 1 : ((RX_BYTE == 32) ? 0 : 31))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))));
         end
         STATE_41: begin
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
         STATE_43, STATE_38: begin
            col_cursor <= 0;
         end
         STATE_45, STATE_39: begin
            row_cursor <= 0;
         end
         STATE_46: begin
            row_cursor <= (row_cursor + 1);
         end
         STATE_48: begin
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