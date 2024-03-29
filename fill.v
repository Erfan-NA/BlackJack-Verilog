
module fill
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,							// On Board Keys
        SW,
        HEX0,
        LEDR,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;					
	// Declare your inputs and outputs here
    input   [9:0]   SW;
    output   [6:0]  HEX0;
    output  [9:0]   LEDR;
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] colour;
	wire [8:0] x;
	wire [8:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn
    
    bj black_jack(
        .SW(SW),
        .CLOCK_50(CLOCK_50),
        .HEX0(HEX0),
        .color_out(colour),
        .x_final(x),
        .y_final(y),
        .Player_win(LEDR[9]),
        .CPU_win(LEDR[8])
    );

	// for the VGA controller, in addition to any other functionality your design may require.
	
	
endmodule




module bj(input [9:0] SW, input CLOCK_50, output [6:0] HEX0,  output [2:0] color_out,
  output [8:0] x_final,
  output [8:0] y_final,
  output Player_win,
  output CPU_win);

  	wire [3:0] state_output_forHex;
    wire [5:0] card_output;
    wire [17:0] address_final;
    wire result;
    reg CPU_win_reg;
    reg Player_win_reg;
    always @(posedge CLOCK_50) begin
        if (final_show_winner) begin
            CPU_win_reg <= ~result;
            Player_win_reg <= result;
        end
        else begin
            CPU_win_reg <= 0;
            Player_win_reg <= 0;
        end
    end

    assign Player_win = Player_win_reg;
    assign CPU_win = CPU_win_reg;
  
   main top(
        .Clock(CLOCK_50),
        .switch_hit_stand(SW[0]),
        .switch_reset(SW[1]),
        .state_out_main(state_output_forHex),
		.card_output(card_output),
        .x_final(x_final),
        .y_final(y_final),
        .address_final(address_final),
        .winner_out(result),
        .show_winner_out(final_show_winner)
    );

    hex_decoder decoder(
        .c(state_output_forHex),
        .display(HEX0)
    );


    memory_mux mem_color(
        .address(address_final),
        .card(card_output),
        .Clock(CLOCK_50),
        .wren(1'b0),
        .q(color_out)
    );

endmodule

module hex_decoder (

    input [3:0] c,
    output [6:0] display
);
   
    assign display[0] = ~((c[3]|c[2]|c[1]|~c[0])&(c[3]|~c[2]|c[1]|c[0])&(~c[3]|c[2]|~c[1]|~c[0])&(c[1]|~c[3]|~c[2]|~c[0]));
    assign display[1] = ~((c[3]|c[1]|~c[2]|~c[0])&(c[3]|c[0]|~c[1]|~c[2])&(c[2]|~c[3]|~c[1]|~c[0])&(c[0]|c[1]|~c[2]|~c[3])&(c[0]|~c[1]|~c[2]|~c[3])&(~c[0]|~c[1]|~c[2]|~c[3]));
    assign display[2] = ~((~c[1]|c[0]|c[2]|c[3])&(~c[3]|~c[2]|c[1]|c[0])&(~c[3]|~c[2]|~c[1]|c[0])&(~c[3]|~c[2]|~c[1]|~c[0]));
    assign display[3] = ~((c[3]|c[2]|c[1]|~c[0])&(c[3]|~c[2]|c[1]|c[0])&(c[3]|~c[2]|~c[1]|~c[0])&(~c[3]|~c[1]|c[2]|c[0])&(~c[3]|~c[2]|~c[1]|~c[0]));
    assign display[4] = ~((c[3]|c[2]|c[1]|~c[0])&(c[3]|c[2]|~c[1]|~c[0])&(c[3]|c[1]|c[0]|~c[2])&(c[3]|c[1]|~c[2]|~c[0])&(c[3]|~c[2]|~c[1]|~c[0])&(~c[3]|~c[0]|c[1]|c[2]));
    assign display[5] = ~((c[3]|c[2]|c[1]|~c[0])&(c[3]|c[2]|~c[1]|c[0])&(c[3]|c[2]|~c[1]|~c[0])&(c[3]|~c[2]|~c[1]|~c[0])&(c[1]|~c[3]|~c[2]|~c[0]));
    assign display[6] = ~((c[3]|c[2]|c[1]|c[0])&(c[3]|c[2]|c[1]|~c[0])&(c[3]|~c[2]|~c[1]|~c[0])&(~c[3]|~c[1]|c[2]|c[0])&(~c[3]|~c[2]|c[1]|c[0]));
   
endmodule







module main #(parameter CLOCK_FREQUENCY = 50000000)(  
  input Clock,
  input switch_hit_stand,
  input switch_reset,

  output [3:0] state_out_main, //testing
  output [5:0] card_output,
  output [8:0] x_final,
  output [8:0] y_final,
  output [17:0] address_final,
  output winner_out,
  output show_winner_out
);
  wire [4:0] player_total;
  wire [4:0] CPU_total;
  wire player_turn_output;
  wire Reset;
  wire Enable;
  wire move; //CPU move



  wire whose_turn;

  wire [4:0] cur_total;
  wire move_choice;
  wire declare_winner;
  wire winner;

  wire add_new_card_to_cards;
  wire update_total;
  wire compare_totals_output;
  wire status_player_output;
  wire CPU_player_output;

  wire declare_winner_output;
  wire bust_true_output;
  wire [3:0] state_out_reg;


  wire whose_turn_out;
  wire [3:0] count_to_5_out;
  
  wire [5:0] mem_address;
  wire [3:0] mem_data;
  wire mem_wren;
  wire [3:0] q;
  
  wire draw_new; //input into LFSR
  wire [4:0] address; //input into memory
  wire [5:0] input_data; //input into memory
  wire write_enable; //input into memory
  wire [5:0] mem_output; //output of memory
  wire [5:0] LFSR_output; //output of LFSR
  
  wire [8:0] width;
  wire [8:0] height;
  wire [8:0] x_start;
  wire [8:0] y_start;
  wire done;
  wire start_print;
  wire [3:0] ram_out;


  FPGA_INPUTS u1 (.switch_hit_stand(switch_hit_stand), .switch_reset(switch_reset), .player_turn_output(player_turn_output), .reset(Reset));
  RateDivider u2 (.Clock(Clock), .Reset(Reset), .Enable(Enable));
  //LFSR_CPU_MOVE u3 (.Clock(Clock), .reset(Reset) , .Enable(Enable), .move(move));
  
  LFSR_CPU_MOVE u10 (.Clock(Clock), .reset(Reset), .Enable(Enable), .move(move), .mem_address(mem_address),
  .mem_data(mem_data), .mem_wren(mem_wren));
  ram u11 (.address(mem_address), .clock(Clock), .data(mem_data), .wren(mem_wren), .q(ram_out));


  FSM1 u4 (.Clock(Clock), .reset(Reset), .status_player(status_player_output), .whose_turn_output(whose_turn));

  Datapath1 u5 (.Clock(Clock), .reset(Reset), .LFSR_input_hit_stand(move), .FPGA_switch_input(player_turn_output), .player_total(player_total), .CPU_total(CPU_total),
  .whose_turn_input(whose_turn), .cur_total(cur_total), .move_choice_output(move_choice));
 
  FSM2 u6 (.Enable(Enable), .Clock(Clock), .reset(Reset), .whose_turn(whose_turn),
  .total(cur_total), .move_choice(move_choice), .status_player(status_player_output), .status_CPU(status_CPU_output),
  .add_new_card_to_cards(add_new_card_to_cards), .update_total(update_total), .compare_totals_output(compare_totals_output),
  .declare_winner_output(declare_winner_output), .bust_true_output(bust_true_output), .state_out(state_out_reg),
  .whose_turn_out(whose_turn_out));
  
      Datapath_2 u7 (
        .done(done), 
	      .switch_reset(switch_reset),
        .compare_totals_output(compare_totals_output),  //REDUNDANT INPUT from FSM 2
        .enable_out(Enable),                            //input given from rate divider
        .move_choice_output(move_choice),               //input given from FSM 2
        .add_new_card_to_cards(add_new_card_to_cards),  //input given from FSM 2
        .declare_winner_output(declare_winner_output),  //input from FSM 2
        .bust_true_output(bust_true_output),            //REDUNDANT INPUT, JUST ASSIGN from FSM 2
        .Clock(Clock),                                  //input from wherever Clock happens
        .whose_turn(whose_turn_out),                    //input from FSM 2
        .state_out(state_out_reg),                      //input from FSM 2
        .mem_output(mem_output),                        //input from MEMORY
        .LFSR_output(LFSR_output),                      //input from LFSR
        .status_player_output(status_player_output),    //output to FSM 1
        .status_CPU_output(status_CPU_output),          //output to FSM 1
        .player_total(player_total),                    //output to datapath 1
        .CPU_total(CPU_total),                          //output to datapath 1
        .winner_out(winner_out),                        //output to VGA
        .write_enable(write_enable),                    //output to MEMORY COMPARISON
        .address(address),                              //output to MEMORY COMPARISON
        .input_data(input_data),                        //output to MEMORY COMPARISON
        .draw_new(draw_new),                            //output to LFSR_output_card
        .start_print(start_print),
        .width(width),
        .height(height),
        .x_pos(x_start),
        .y_pos(y_start),
        .current_card(card_output),
        .show_winner(show_winner_out)
    );
	 
	 positional_iterator u8(
        .width(width),
        .height(height),
        .Clock(Clock), 
        .x_pos(x_start), 
        .y_pos(y_start), 
        .start_print(start_print), 
        .done(done), 
        .x_test(x_final), 
        .y_test(y_final),
        .address_out(address_final)
    );

    LFSR_output_card u80(
        .Clock(Clock),
        .make_new(draw_new),
        .Q(LFSR_output)
    );

    mem_block u9(
      .address(address),
      .wren(write_enable),
      .clock(Clock),
      .data(input_data),
      .q(mem_output)
    );



  assign state_out_main = state_out_reg;

endmodule

module RateDivider #(parameter CLOCK_FREQUENCY = 50000000) (
    input Clock,
    input Reset,
    output Enable//5 seconds
	
);
  reg [3:0] count_to_5;
  reg [25:0] seconds_count;
  reg enable_reg;

  always @(posedge Clock) begin
    if (Reset || (count_to_5==5 && seconds_count==1))  begin // Resetting on reset OR when 15seconds
      seconds_count <= 0;
      count_to_5 <= 0;
      enable_reg <= 0;
    end
    else begin
      if (seconds_count == CLOCK_FREQUENCY - 1) begin
        seconds_count <= 0;
        count_to_5 <= count_to_5 + 1;
      end
      else begin
        seconds_count <= seconds_count + 1;
      end

      if (count_to_5 == 5) begin
          enable_reg <= 1; // Set when 15 seconds have passed
      end
    end
  end

  assign Enable = enable_reg;
endmodule




module FPGA_INPUTS(
    input switch_hit_stand, //Hit is 1
    input switch_reset,
    output player_turn_output,
    output reset
);
  //switch_hit_stand -> is SW[0]
  //switch_reset -> is SW[1]
  assign player_turn_output = switch_hit_stand;
  assign reset = switch_reset;
endmodule

module FSM1(
    input Clock,
    input reset,
    input status_player, //0 -> not done turn yet
    output whose_turn_output
    //output [4:0] player_total,
    //output [4:0] CPU_total
);
    reg y_Q, Y_D;
    localparam A = 1'b0, B = 1'b1;
    //localparam max = 5'b10101; //21 in binary
    //reg [4:0] player_total_reg, CPU_total_reg;

    always @(*)
    begin: state_table
        case (y_Q)
            A: begin
              //Player turn
              if (~status_player)
                  Y_D <= A;
              else
                  Y_D <= B;
            end
            B: begin
              // CPU's turn
              Y_D <= B; //Stay in CPU turn till reset
            end
            default: Y_D <= A;
        endcase
    end

    always @(posedge Clock) begin
      if (reset) begin
        y_Q <= A; // Reset state to A
        //player_total_reg <= 0;
        //CPU_total_reg <= 0;
      end else begin
        y_Q <= Y_D;
      end
    end

    assign whose_turn_output = y_Q;
endmodule

module Datapath1(
  input Clock,
  input reset,
  input LFSR_input_hit_stand, //hit or stand for CPU
  input FPGA_switch_input,
  input [4:0] player_total,
  input [4:0] CPU_total,
  input whose_turn_input,
  output [4:0] cur_total,
  output move_choice_output
 
);
  // whose_turn = 0 -> Player's turn
  reg temp_move_choice;
  reg [4:0] total;

  always @(posedge Clock)
  begin
    if (whose_turn_input == 0)begin
        total <= player_total;
    end
    else begin
        total <= CPU_total;
    end

    if (whose_turn_input == 0)begin
        temp_move_choice <= FPGA_switch_input;
    end
    else begin
        temp_move_choice <= LFSR_input_hit_stand;
    end

  end

  assign cur_total = total;
  assign move_choice_output = temp_move_choice;

endmodule

module FSM2(
  input Enable, //From rate divder
  input Clock,
  input reset,
  input whose_turn,
  input [4:0] total,
  input move_choice,
  input status_player, //done or not
  input status_CPU, //done or not

  output add_new_card_to_cards, //0 --> No
  output update_total, //0 --> No
  output compare_totals_output, //0 --> No
  output declare_winner_output, //0 --> No
  output bust_true_output, //0 --> No
  output [3:0] state_out,
  output whose_turn_out

);
    reg [3:0] y_Q, Y_D;
    localparam A = 4'b0000, B = 4'b0001, C = 4'b0010, D = 4'b0011, E = 4'b0100, F = 4'b0101, G = 4'b0110,
    H = 4'b0111, I = 4'b1000, J = 4'b1001;
    localparam max = 5'b10101; //21 in binary

    //move_choice == 1'b1 -> hit

    always @(*)
    begin: state_table
        case (y_Q)
            A: begin //0 card --> force them to hit
                if (Enable) begin
                    Y_D <=B;
                end
                else begin
                    Y_D <=A;
                end
            end
            B: begin //1 card --> force them to hit
              if (Enable) begin
                if (total == max)
                  Y_D <= I;
                else
                    Y_D <= C;
               end
              else begin
                Y_D <= B;
              end
            end
            C: begin //2 card
              if (Enable) begin
                if (total == max)
                  Y_D <= I;
                else if (total > max)
                  Y_D <= J;
                else if (move_choice)
                  Y_D <= D;
                else
                  Y_D <= G;
              end
              else begin
                Y_D <= C;
              end
            end
            D: begin //3 card
              if (Enable) begin
                if (total == max)
                  Y_D <= I;
                else if (total > max)
                  Y_D <= J;
                else if (move_choice)
                  Y_D <= E;
                else
                  Y_D <= G;
              end
              else begin
                Y_D <=D;
              end
            end
            E: begin //4 card
              if (Enable) begin
                if (total == max)
                  Y_D <= I;
                else if (total > max)
                  Y_D <= J;
                else if (move_choice)
                  Y_D <= F;
                else
                  Y_D <= G;
              end
            else begin
                Y_D <= E;
              end
            end
            F: begin //5 card
              if (Enable) begin
                if (total == max)
                  Y_D <= I;
                else if (total > max)
                  Y_D <= J;
                else
                  Y_D <= I; //After reaching 5 cards automatically declares u winner
              end
            else begin
                Y_D <= F;
              end
            end
            G: begin //Stand
              if (Enable) begin
                if (status_player) //Both are done
                  Y_D <= H; //Compare totals
                else
                  Y_D <= A; //Switch turn
              end
            else begin
                Y_D <= G;
              end
            end
            H: begin //Compare totals
                if (Enable) begin
                    Y_D <= I;
                end
                else begin
                    Y_D <= H;
                end
            end
            I: begin //declare a winner
                if (Enable) begin
                    Y_D <= I;
                end
                else begin
                    Y_D <=I;
                end
            end
            J: begin //If Bust occurs
            if (Enable) begin
                Y_D <= I;
            end
            else begin
                Y_D<=J;
            end
            end
            default: Y_D <= A;
        endcase
    end

        //temp variables to serve as the output till assignment
        reg add_new_card_to_cards_reg;
        reg update_total_reg;
        reg compare_totals_output_reg;
        reg declare_winner_output_reg;
        reg bust_true_output_reg;

        always @(posedge Clock)
          begin: state_FFs
            if (reset) begin
              y_Q <= A; // Reset state to A
            end
            else

              y_Q <= Y_D;

            if(y_Q == A || y_Q == B || y_Q == C || y_Q == D || y_Q == E) begin//If in state of 0-4 cards we are adding a new card
              add_new_card_to_cards_reg <= 1'b1; //Add card to the array
              update_total_reg <= 1'b1; //update total
              compare_totals_output_reg <= 1'b0;
              declare_winner_output_reg <= 1'b0;
              bust_true_output_reg <= 1'b0;
            end

            if (y_Q == G) begin //Update stand status of the person who just stood

               add_new_card_to_cards_reg <= 1'b0;
               update_total_reg <= 1'b0;
               compare_totals_output_reg <= 1'b0;
               declare_winner_output_reg <= 1'b0;
               bust_true_output_reg <= 1'b0;
            end

            if (y_Q == H) begin
               compare_totals_output_reg <= 1'b1; //You need to compare the totals of both CPU and Player

               add_new_card_to_cards_reg <= 1'b0;
               update_total_reg <= 1'b0;
   
               declare_winner_output_reg <= 1'b0;
               bust_true_output_reg <= 1'b0;
            end

            if (y_Q == I) begin
               declare_winner_output_reg <= 1'b1; //Tell me who won and assign it to "declare_winner"

               add_new_card_to_cards_reg <= 1'b0;
               update_total_reg <= 1'b0;
               compare_totals_output_reg <= 1'b0;
               bust_true_output_reg <= 1'b0;
            end

            if (y_Q == J) begin
               declare_winner_output_reg <= 1'b1; //Tell me who won and assign it to "declare_winner"
               bust_true_output_reg <= 1'b1; //Someone just bust, delcare other person the winner

               add_new_card_to_cards_reg <= 1'b0;
               update_total_reg <= 1'b0;
               compare_totals_output_reg <= 1'b0;

            end
          end
    assign add_new_card_to_cards = add_new_card_to_cards_reg;
    assign update_total = update_total_reg;
    assign compare_totals_output = compare_totals_output_reg;

    assign declare_winner_output = declare_winner_output_reg;
    assign bust_true_output = bust_true_output_reg;
    assign state_out = y_Q;
    assign whose_turn_out = whose_turn;
endmodule

module ram (
  address,
  clock,
  data,
  wren,
  q);

  input [5:0]  address;
  input   clock;
  input [3:0]  data;
  input   wren;
  output  [3:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
  tri1    clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

  wire [3:0] sub_wire0;
  wire [3:0] q = sub_wire0[3:0];

  altsyncram  altsyncram_component (
        .address_a (address),
        .clock0 (clock),
        .data_a (data),
        .wren_a (wren),
        .q_a (sub_wire0),
        .aclr0 (1'b0),
        .aclr1 (1'b0),
        .address_b (1'b1),
        .addressstall_a (1'b0),
        .addressstall_b (1'b0),
        .byteena_a (1'b1),
        .byteena_b (1'b1),
        .clock1 (1'b1),
        .clocken0 (1'b1),
        .clocken1 (1'b1),
        .clocken2 (1'b1),
        .clocken3 (1'b1),
        .data_b (1'b1),
        .eccstatus (),
        .q_b (),
        .rden_a (1'b1),
        .rden_b (1'b1),
        .wren_b (1'b0));
  defparam
    altsyncram_component.clock_enable_input_a = "BYPASS",
    altsyncram_component.clock_enable_output_a = "BYPASS",
    altsyncram_component.intended_device_family = "Cyclone V",
    altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
    altsyncram_component.lpm_type = "altsyncram",
    altsyncram_component.numwords_a = 64,
    altsyncram_component.operation_mode = "SINGLE_PORT",
    altsyncram_component.outdata_aclr_a = "NONE",
    altsyncram_component.outdata_reg_a = "UNREGISTERED",
    altsyncram_component.power_up_uninitialized = "FALSE",
    altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
    altsyncram_component.widthad_a = 6,
    altsyncram_component.width_a = 4,
    altsyncram_component.width_byteena_a = 1;


endmodule

module LFSR_CPU_MOVE(
    input Clock,
    input reset,
    input Enable,
    output move,
    output [5:0] mem_address,
    output [3:0] mem_data,
    output mem_wren
);
    reg [3:0] lsfr;
    reg [5:0] address_counter; // Counter to keep track of the next free memory location

    // Initialize the LFSR and address counter
    always @(posedge Clock) begin
        if (reset) begin
            lsfr <= 4'b0001;
            address_counter <= 6'b000000; // Reset the address counter
        end
        else begin
          if (Enable) begin
            lsfr <= {lsfr[2:0], lsfr[3] ^ lsfr[2]}; // Update LFSR
            address_counter <= address_counter + 1'b1; // Increment address counter
          end
          else begin
            lsfr <= lsfr;
          end
        end
    end

    // Output assignments
    assign move = lsfr[3];
    assign mem_address = address_counter; // Memory address for writing
    assign mem_data = {3'b000, lsfr[3]}; // Data to be written to memory (extending lsfr[3] to 4 bits)
    assign mem_wren = Enable; // Write enable signal for memory (active when LFSR is enabled)

endmodule

module positional_iterator (
    input [8:0] width,
    input [8:0] height,
    input Clock,
    input [8:0] x_pos,
    input [8:0] y_pos,
    input start_print,
    output done,
    output [8:0] x_test,
    output [8:0] y_test,
    output [17:0] address_out
);


    reg [16:0] iterator = 17'b0;
    reg [16:0] address;
    reg done_reg = 1'b0;
    reg processing_r = 1'b0;
    reg read_send;
    reg read_recieve;
    reg [8:0] x_t;
    reg [8:0] y_t;

    always @(posedge Clock) begin

        if (start_print) begin
            iterator <= 17'b0;
            address <= 17'b0;
            processing_r <= 1'b1;
            y_t <= y_pos;
            x_t <= x_pos;
            read_send <= 1;
            read_recieve <= 0;
            done_reg <= 1'b0;
        end

        else if (processing_r) begin
            
            if (read_send) begin
                read_send <= 0;
                read_recieve <= 1;
                if (iterator == width) begin
                    iterator <= 17'b0;
                    if ((y_t - y_pos) == height-1) begin 
                        done_reg <= 1'b1;
                        iterator <= 17'b0;
                        processing_r <= 1'b0;
                    end
                    else begin
                        y_t <= y_t + 1;
                        x_t <= x_pos;
                    end
                end
                else begin
                    x_t <= x_pos + iterator;
                end

            end

            if (read_recieve) begin
                read_send <= 1;
                read_recieve <= 0;
                iterator <= iterator + 1;
                address <= address + 1;
            end  
        end

    end

    assign x_test = x_t;
    assign y_test = y_t;
    assign done = done_reg;
    assign address_out = address;

endmodule



module Datapath_2 (
    input done,
    input switch_reset,

    //from RateDivider
    input compare_totals_output,
    input enable_out,

    //from Datapath1
    input move_choice_output,

    //inputs from FSM2
    input add_new_card_to_cards,
    input declare_winner_output,                //WHEN ON RUN DISPLAY CODE
    input bust_true_output,
    input Clock,
    input whose_turn, //0 is player
    input [3:0] state_out,
   
    //input from memory
    input [5:0] mem_output,

    //input from LFSR
    input [5:0] LFSR_output,

    //outputs to FSM2
    output status_player_output, //done or not  //OUTPUT not added
    output status_CPU_output,                   //OUTPUT BASED ON STATE A-F and TURN
    output [4:0] player_total,                  //ASSIGN BOTH OUTPUTS AT ALL TIMES
    output [4:0] CPU_total,                     //CHANGED
    output winner_out,

    //outputs to memory
    output write_enable, //0 means read, 1 means writee
    output [4:0] address, //self explanatory
    output [5:0] input_data, //what goes into memory

    //output to LFSR
    output draw_new,


    //test output
    output start_print,
    output [8:0] width,
    output [8:0] height,
    output [8:0] x_pos,
    output [8:0] y_pos,
    output [5:0] current_card,
    output show_winner
);

    localparam max = 5'b10101; //21 in binary
    localparam A = 4'b0000, B = 4'b0001, C = 4'b0010, D = 4'b0011, E = 4'b0100, F = 4'b0101, G = 4'b0110,
    H = 4'b0111, I = 4'b1000, J = 4'b1001;

    reg [5:0] temp_card, temp_mem_output;
    reg write_enable_reg = 1'b0;
    reg [4:0] address_reg = 5'b0;
    reg draw_new_reg = 1'b1;
    reg [4:0] p_total_reg;
    reg [4:0] p_ace_reg;
    reg [4:0] c_total_reg;
    reg [4:0] c_ace_reg;
   
    reg add_new_card_to_cards_reg = 1'b0;

    reg [4:0] iterator = 5'b0;
    reg read_send = 1'b1;
    reg read_recieve = 1'b0;
    reg write_send = 1'b1;
    reg write_recieve = 1'b0;
    reg winner_out_reg;
    reg status_player_output_reg = 1'b0;
    reg status_CPU_output_reg = 1'b0;
    reg [17:0] arbitrary_wait_reg = 18'b0;
    reg start_screen, start_print_reg;
    reg print_state;
    reg [4:0] p_total_output, c_total_output;
    reg show_winner_reg;

    reg [8:0] width_reg, height_reg, x_pos_reg, y_pos_reg;

    always @(posedge Clock)
    begin


        if (state_out == I) begin
            show_winner_reg <= 1;
        end
        else begin
            show_winner_reg <= 0;
        end

        if (arbitrary_wait_reg != 18'd153603) begin
            p_total_reg <= 5'b0;
            p_ace_reg <= 5'b0;
            c_total_reg <= 5'b0;
            c_ace_reg <= 5'b0;
        end

        if (switch_reset) begin
            start_screen <= 1'b1;
            width_reg <= 18'd320;
            height_reg <= 18'd240;
            x_pos_reg <= 9'b0;
            y_pos_reg <= 9'b0;
        end

        if (print_state == 1) begin
            print_state <= 0;
            start_print_reg <= 1;
        end

        if (start_screen) begin
            if (arbitrary_wait_reg == 1) begin
                start_print_reg <= 1'b0;
                arbitrary_wait_reg <= arbitrary_wait_reg + 1;
            end
            else if (arbitrary_wait_reg == 18'd153603) begin 
                start_screen <= 0;
                x_pos_reg <= 9'd10;
                y_pos_reg <= 9'd19;
                width_reg <= 18'd54;
                height_reg <= 18'd85;
            end
            else if (arbitrary_wait_reg == 18'b0) begin
                start_print_reg <= 1'b1;
                arbitrary_wait_reg <= arbitrary_wait_reg + 1;
            end
            else begin
                arbitrary_wait_reg <= arbitrary_wait_reg + 1;
            end
        end

        if (declare_winner_output) begin
            if (c_total_reg >= p_total_reg) begin
                winner_out_reg <= 1'b1;
            end
            else begin 
                winner_out_reg <= 1'b0;
            end
        end
       
        temp_mem_output <= mem_output;
        if (arbitrary_wait_reg != 18'd153603) begin
          temp_card <= 6'b0;
        end
        else begin 
          temp_card <= LFSR_output;
        end
        

       
        if (~add_new_card_to_cards) begin
            add_new_card_to_cards_reg <= 1'b0;
        end

        if (enable_out && done) begin 
            add_new_card_to_cards_reg <= 0;
            iterator <= 5'b0;
        end
       
        else if (add_new_card_to_cards) begin
            if (state_out == A || state_out == B) begin
                add_new_card_to_cards_reg <= 1'b1;
            end
            else if (move_choice_output && (state_out == C || state_out == D || state_out == E)) begin
                add_new_card_to_cards_reg <= 1'b1;
            end
        end

        

        if (add_new_card_to_cards_reg && switch_reset == 0 && arbitrary_wait_reg == 18'd153603) begin
            
            if (iterator == 10) begin
                if (write_send) begin
                    if (~whose_turn) begin
                        if (temp_card[3:0] < 11 && temp_card[3:0] != 1) begin
                            p_total_reg <= p_total_reg + {1'b0, temp_card[3:0]};
                            p_ace_reg <= p_ace_reg + {1'b0, temp_card[3:0]};
                        end
                        else if (temp_card[3:0] == 1) begin
                            p_total_reg <= p_total_reg + 1;
                            p_ace_reg <= p_ace_reg + 11;
                        end
                        else begin
                            p_total_reg <= p_total_reg + 10;
                            p_ace_reg <= p_ace_reg + 10;
                        end
                        address_reg <= {1'b0, state_out};
                    end
                    else begin
                        if (temp_card[3:0] < 11 && temp_card[3:0] != 1) begin
                            c_total_reg <= c_total_reg + {1'b0, temp_card[3:0]};
                            c_ace_reg <= c_ace_reg + {1'b0, temp_card[3:0]};
                        end
                        else if (temp_card[3:0] == 1) begin
                            c_total_reg <= c_total_reg + 1;
                            c_ace_reg <= c_ace_reg + 11;
                        end
                        else begin
                            c_total_reg <= c_total_reg + 10;
                            c_ace_reg <= c_ace_reg + 10;
                        end
                        address_reg <= {1'b0, state_out + 5};
                    end
                    if (iterator < 11) begin
                        write_enable_reg <= 1;
                    end
                    write_send <= 1'b0;
                    write_recieve <= 1'b1;
                end
                else if (write_recieve) begin
                    iterator <= iterator + 1;
                    x_pos_reg <= 10 + (state_out * 61);
                    y_pos_reg <= 14 + (whose_turn * 120); 
                    print_state <= 1'b1;
                    write_send <= 1'b1;
                    write_recieve <= 1'b0;
                end
            end
            else if (read_send && iterator < 10 && !start_screen) begin
                address_reg <= iterator;
                write_enable_reg <= 0;
                read_send <= 0;
                read_recieve <= 1;
            end
            else if (read_recieve && iterator < 10 && !start_screen) begin
                read_send <= 1;
                read_recieve <= 0;
                if (mem_output != temp_card) begin
                    iterator <= iterator + 1;
                end
                else begin
                    iterator <= 5'b0;
                    draw_new_reg <= 1;
                end
            end
        end
        else if (iterator == 11) begin
            iterator <= 12;
            write_enable_reg <= 0;       
            //VGA
        end
        else if (iterator == 12) begin
            start_print_reg <= 1;
            iterator <= 13;
        end
        else if (iterator == 13) begin
            start_print_reg <= 0;
            iterator <= 13;
        end

        if (p_ace_reg > 21) begin
            p_total_output <= p_total_reg;
        end
        else if (p_ace_reg == 21) begin
            p_total_output <= p_ace_reg;
        end
        else begin
            p_total_output <= p_total_reg;
        end

       
       
        //IF STATEMENT FOR STATUS PLAYER BASED ON STATE
       
        if (state_out == G && enable_out) begin
            if (~whose_turn) begin
                status_player_output_reg <= 1'b1;
            end
            else if (whose_turn) begin
                status_CPU_output_reg <= 1'b1;
            end
        end

        if (c_ace_reg > 21) begin
            c_total_output <= c_total_reg;
        end
        else if (c_ace_reg == 21) begin
            c_total_output <= c_ace_reg;
        end
        else begin
            c_total_output <= c_total_reg;
        end


        if (draw_new_reg) begin
            draw_new_reg <= 0;
        end

        if (start_print_reg == 1) begin
            start_print_reg <= 1'b0;
        end
   
    end

    assign write_enable = write_enable_reg; //FOR MEMORY CARD CHECK
    assign address = address_reg; //FOR MEMORY CARD CHECK
    assign draw_new = draw_new_reg; //FOR LFSR
    assign status_player_output = status_player_output_reg; //FOR FSM 2
    assign status_CPU_output = status_CPU_output_reg; //FOR FSM 2
    assign CPU_total = c_total_reg; //FOR FSM 2
    assign player_total = p_total_reg; //FOR FSM 2
    assign winner_out = winner_out_reg; //FOR VGA
    assign input_data = temp_card; //FOR VGA
    assign x_pos = x_pos_reg;
    assign y_pos = y_pos_reg;
    assign width = width_reg;
    assign height = height_reg;
    assign start_print = start_print_reg;
    assign current_card = temp_card;
    assign show_winner = show_winner_reg;
    //for testing
   	

endmodule

module LFSR_output_card (
    input make_new,
    input Clock,
    output [5:0] Q
);


    wire [2:0] output_0to8, output_1to4;
    wire [1:0] output_suit;

    LFSR_0to8 u1(make_new, Clock, output_0to8);
    LFSR_1to4 u2(make_new, Clock, output_1to4);
    LFSR_suit u3(make_new, Clock, output_suit);

    assign Q = {output_suit, ({1'b0, output_0to8} + {1'b0, output_1to4})};


endmodule


module LFSR_0to8 (
    input make_new,
    input Clock,
    output [2:0] Q
);

    reg myVariable = 1'b1; // Define a 4-bit variable
    reg [10:0] Q_reg, Q_next;
    reg [2:0] Q_out;
    wire taps;

    // Initial block to set myVariable to 4'b1 at the beginning
   

    // Always block that initializes Q_reg at the beginning
    always @(posedge Clock) begin
        if (myVariable == 1'b1)
        begin
            Q_reg <= 11'b1;
            myVariable <= 1'b0;
        end 

        else 
        begin
            Q_reg <= Q_next;
        end

        if (make_new)
        begin
            Q_out <= {Q_reg[10], Q_reg[9], Q_reg[8]} + {2'b0, Q_reg[7]};
        end
    end

    //assigns Q_next
    always @(taps, Q_reg)
        Q_next = {taps, Q_reg[10:1]};

    assign taps = ~(Q_reg[0] ^ Q_reg[2]);
    assign Q = Q_out;

endmodule


module LFSR_1to4 (
    input make_new,
    input Clock,
    output [2:0] Q
);

    reg myVariable = 1'b1; // Define a 4-bit variable
    reg [10:0] Q_reg, Q_next;
    reg [2:0] Q_out;
    wire taps;

    // Initial block to set myVariable to 4'b1 at the beginning
   

    // Always block that initializes Q_reg at the beginning
    always @(posedge Clock) begin
        if (myVariable == 1'b1)
        begin
            Q_reg <= 11'b10110111101;
            myVariable <= 1'b0;
        end 

        else 
        begin
            Q_reg <= Q_next;
        end

        if (make_new)
        begin
            Q_out <= {1'b0, Q_reg[10], Q_reg[9]} + 3'b001;
        end
    end

    //assigns Q_next
    always @(taps, Q_reg)
        Q_next = {taps, Q_reg[10:1]};

    assign taps = ~(Q_reg[0] ^ Q_reg[2]);
    assign Q = Q_out;

endmodule

module LFSR_suit (
    input make_new,
    input Clock,
    output [1:0] Q
);

    reg myVariable = 1'b1; // Define a 4-bit variable
    reg [10:0] Q_reg, Q_next;
    reg [1:0] Q_out;
    wire taps;

    // Initial block to set myVariable to 4'b1 at the beginning
   

    // Always block that initializes Q_reg at the beginning
    always @(posedge Clock) begin
        if (myVariable == 1'b1)
        begin
            Q_reg <= 11'b10010100111;
            myVariable <= 1'b0;
        end 

        else 
        begin
            Q_reg <= Q_next;
        end

        if (make_new)
        begin
            Q_out <= {Q_reg[10], Q_reg[9]};
        end
    end

    //assigns Q_next
    always @(taps, Q_reg)
        Q_next = {taps, Q_reg[10:1]};

    assign taps = ~(Q_reg[0] ^ Q_reg[2]);
    assign Q = Q_out;

endmodule


`timescale 1 ps / 1 ps
// synopsys translate_on
module mem_block (
    address,
    clock,
    data,
    wren,
    q);

    input   [4:0]  address;
    input     clock;
    input   [5:0]  data;
    input     wren;
    output  [5:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
    tri1      clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

    wire [5:0] sub_wire0;
    wire [5:0] q = sub_wire0[5:0];

    altsyncram  altsyncram_component (
                .address_a (address),
                .clock0 (clock),
                .data_a (data),
                .wren_a (wren),
                .q_a (sub_wire0),
                .aclr0 (1'b0),
                .aclr1 (1'b0),
                .address_b (1'b1),
                .addressstall_a (1'b0),
                .addressstall_b (1'b0),
                .byteena_a (1'b1),
                .byteena_b (1'b1),
                .clock1 (1'b1),
                .clocken0 (1'b1),
                .clocken1 (1'b1),
                .clocken2 (1'b1),
                .clocken3 (1'b1),
                .data_b (1'b1),
                .eccstatus (),
                .q_b (),
                .rden_a (1'b1),
                .rden_b (1'b1),
                .wren_b (1'b0));
    defparam
        altsyncram_component.clock_enable_input_a = "BYPASS",
        altsyncram_component.clock_enable_output_a = "BYPASS",
        altsyncram_component.intended_device_family = "Cyclone V",
        altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
        altsyncram_component.lpm_type = "altsyncram",
        altsyncram_component.numwords_a = 32,
        altsyncram_component.operation_mode = "SINGLE_PORT",
        altsyncram_component.outdata_aclr_a = "NONE",
        altsyncram_component.outdata_reg_a = "UNREGISTERED",
        altsyncram_component.power_up_uninitialized = "FALSE",
        altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
        altsyncram_component.widthad_a = 5,
        altsyncram_component.width_a = 6,
        altsyncram_component.width_byteena_a = 1;


endmodule





module memory_mux(
    input [12:0] address,
    input [5:0] card,
    input Clock,
    input wren,
    output [2:0] q
);

    reg [2:0] mem_output_color;

    wire [2:0] mem_2C_w;
    wire [2:0] mem_2D_w;
    wire [2:0] mem_2H_w;
    wire [2:0] mem_2S_w;

    wire [2:0] mem_3C_w;
    wire [2:0] mem_3D_w;
    wire [2:0] mem_3H_w;
    wire [2:0] mem_3S_w;

    wire [2:0] mem_4C_w;
    wire [2:0] mem_4D_w;
    wire [2:0] mem_4H_w;
    wire [2:0] mem_4S_w;

    wire [2:0] mem_5C_w;
    wire [2:0] mem_5D_w;
    wire [2:0] mem_5H_w;
    wire [2:0] mem_5S_w;
    
    wire [2:0] mem_6C_w;
    wire [2:0] mem_6D_w;
    wire [2:0] mem_6H_w;
    wire [2:0] mem_6S_w;

    wire [2:0] mem_7C_w;
    wire [2:0] mem_7D_w;
    wire [2:0] mem_7H_w;
    wire [2:0] mem_7S_w;

    wire [2:0] mem_8C_w;
    wire [2:0] mem_8D_w;
    wire [2:0] mem_8H_w;
    wire [2:0] mem_8S_w;

    wire [2:0] mem_9C_w;
    wire [2:0] mem_9D_w;
    wire [2:0] mem_9H_w;
    wire [2:0] mem_9S_w;

    wire [2:0] mem_AC_w;
    wire [2:0] mem_AD_w;
    wire [2:0] mem_AH_w;
    wire [2:0] mem_AS_w;

    wire [2:0] mem_JC_w;
    wire [2:0] mem_JD_w;
    wire [2:0] mem_JH_w;
    wire [2:0] mem_JS_w;

    wire [2:0] mem_KC_w;
    wire [2:0] mem_KD_w;
    wire [2:0] mem_KH_w;
    wire [2:0] mem_KS_w;

    wire [2:0] mem_QC_w;
    wire [2:0] mem_QD_w;
    wire [2:0] mem_QH_w;
    wire [2:0] mem_QS_w;

    wire [2:0] mem_TC_w;
    wire [2:0] mem_TD_w;
    wire [2:0] mem_TH_w;
    wire [2:0] mem_TS_w;

    mem_2C u1(address, Clock, 3'b0, wren, mem_2C_w);
    mem_2D u2(address, Clock, 3'b0, wren, mem_2D_w);
    mem_2H u3(address, Clock, 3'b0, wren, mem_2H_w);
    mem_2S u4(address, Clock, 3'b0, wren, mem_2S_w);

    mem_3C u5(address, Clock, 3'b0, wren, mem_3C_w);
    mem_3D u6(address, Clock, 3'b0, wren, mem_3D_w);
    mem_3H u7(address, Clock, 3'b0, wren, mem_3H_w);
    mem_3S u8(address, Clock, 3'b0, wren, mem_3S_w);

    mem_4C u9(address, Clock, 3'b0, wren, mem_4C_w);
    mem_4D u10(address, Clock, 3'b0, wren, mem_4D_w);
    mem_4H u11(address, Clock, 3'b0, wren, mem_4H_w);
    mem_4S u12(address, Clock, 3'b0, wren, mem_4S_w);

    mem_5C u13(address, Clock, 3'b0, wren, mem_5C_w);
    mem_5D u14(address, Clock, 3'b0, wren, mem_5D_w);
    mem_5H u15(address, Clock, 3'b0, wren, mem_5H_w);
    mem_5S u16(address, Clock, 3'b0, wren, mem_5S_w);

    mem_6C u17(address, Clock, 3'b0, wren, mem_6C_w);
    mem_6D u18(address, Clock, 3'b0, wren, mem_6D_w);
    mem_6H u19(address, Clock, 3'b0, wren, mem_6H_w);
    mem_6S u20(address, Clock, 3'b0, wren, mem_6S_w);

    mem_7C u21(address, Clock, 3'b0, wren, mem_7C_w);
    mem_7D u22(address, Clock, 3'b0, wren, mem_7D_w);
    mem_7H u23(address, Clock, 3'b0, wren, mem_7H_w);
    mem_7S u24(address, Clock, 3'b0, wren, mem_7S_w);

    mem_8C u25(address, Clock, 3'b0, wren, mem_8C_w);
    mem_8D u26(address, Clock, 3'b0, wren, mem_8D_w);
    mem_8H u27(address, Clock, 3'b0, wren, mem_8H_w);
    mem_8S u28(address, Clock, 3'b0, wren, mem_8S_w);

    mem_9C u29(address, Clock, 3'b0, wren, mem_9C_w);
    mem_9D u30(address, Clock, 3'b0, wren, mem_9D_w);
    mem_9H u31(address, Clock, 3'b0, wren, mem_9H_w);
    mem_9S u32(address, Clock, 3'b0, wren, mem_9S_w);

    mem_AC u33(address, Clock, 3'b0, wren, mem_AC_w);
    mem_AD u34(address, Clock, 3'b0, wren, mem_AD_w);
    mem_AH u35(address, Clock, 3'b0, wren, mem_AH_w);
    mem_AS u36(address, Clock, 3'b0, wren, mem_AS_w);

    mem_JC u37(address, Clock, 3'b0, wren, mem_JC_w);
    mem_JD u38(address, Clock, 3'b0, wren, mem_JD_w);
    mem_JH u39(address, Clock, 3'b0, wren, mem_JH_w);
    mem_JS u40(address, Clock, 3'b0, wren, mem_JS_w);

    mem_KC u41(address, Clock, 3'b0, wren, mem_KC_w);
    mem_KD u42(address, Clock, 3'b0, wren, mem_KD_w);
    mem_KH u43(address, Clock, 3'b0, wren, mem_KH_w);
    mem_KS u44(address, Clock, 3'b0, wren, mem_KS_w);

    mem_QC u45(address, Clock, 3'b0, wren, mem_QC_w);
    mem_QD u46(address, Clock, 3'b0, wren, mem_QD_w);
    mem_QH u47(address, Clock, 3'b0, wren, mem_QH_w);
    mem_QS u48(address, Clock, 3'b0, wren, mem_QS_w);

    mem_TC u49(address, Clock, 3'b0, wren, mem_TC_w);
    mem_TD u50(address, Clock, 3'b0, wren, mem_TD_w);
    mem_TH u51(address, Clock, 3'b0, wren, mem_TH_w);
    mem_TS u52(address, Clock, 3'b0, wren, mem_TS_w);





    always @(posedge Clock) begin

        if (card == 6'b0) begin
            mem_output_color <= 3'b010;
        end
        else begin
            if (card[5:4] == 2'b00) begin
                if (card[3:0] == 4'd1) begin
                    mem_output_color <= mem_AC_w;
                end
                if (card[3:0] == 4'd2) begin
                    mem_output_color <= mem_2C_w;
                end
                if (card[3:0] == 4'd3) begin
                    mem_output_color <= mem_3C_w;
                end
                if (card[3:0] == 4'd4) begin
                    mem_output_color <= mem_4C_w;
                end
                if (card[3:0] == 4'd5) begin
                    mem_output_color <= mem_5C_w;
                end
                if (card[3:0] == 4'd6) begin
                    mem_output_color <= mem_6C_w;
                end
                if (card[3:0] == 4'd7) begin
                    mem_output_color <= mem_7C_w;
                end
                if (card[3:0] == 4'd8) begin
                    mem_output_color <= mem_8C_w;
                end
                if (card[3:0] == 4'd9) begin
                    mem_output_color <= mem_9C_w;
                end
                if (card[3:0] == 4'd10) begin
                    mem_output_color <= mem_TC_w;
                end
                if (card[3:0] == 4'd11) begin
                    mem_output_color <= mem_JC_w;
                end
                if (card[3:0] == 4'd12) begin
                    mem_output_color <= mem_QC_w;
                end
                if (card[3:0] == 4'd13) begin
                    mem_output_color <= mem_KC_w;
                end
            end

            if (card[5:4] == 2'b01) begin
                
                if (card[3:0] == 4'd1) begin
                    mem_output_color <= mem_AD_w;
                end
                if (card[3:0] == 4'd2) begin
                    mem_output_color <= mem_2D_w;
                end
                if (card[3:0] == 4'd3) begin
                    mem_output_color <= mem_3D_w;
                end
                if (card[3:0] == 4'd4) begin
                    mem_output_color <= mem_4D_w;
                end
                if (card[3:0] == 4'd5) begin
                    mem_output_color <= mem_5D_w;
                end
                if (card[3:0] == 4'd6) begin
                    mem_output_color <= mem_6D_w;
                end
                if (card[3:0] == 4'd7) begin
                    mem_output_color <= mem_7D_w;
                end
                if (card[3:0] == 4'd8) begin
                    mem_output_color <= mem_8D_w;
                end
                if (card[3:0] == 4'd9) begin
                    mem_output_color <= mem_9D_w;
                end
                if (card[3:0] == 4'd10) begin
                    mem_output_color <= mem_TD_w;
                end
                if (card[3:0] == 4'd11) begin
                    mem_output_color <= mem_JD_w;
                end
                if (card[3:0] == 4'd12) begin
                    mem_output_color <= mem_QD_w;
                end
                if (card[3:0] == 4'd13) begin
                    mem_output_color <= mem_KD_w;
                end
                
            end

            if (card[5:4] == 2'b10) begin
                
                if (card[3:0] == 4'd1) begin
                    mem_output_color <= mem_AH_w;
                end
                if (card[3:0] == 4'd2) begin
                    mem_output_color <= mem_2H_w;
                end
                if (card[3:0] == 4'd3) begin
                    mem_output_color <= mem_3H_w;
                end
                if (card[3:0] == 4'd4) begin
                    mem_output_color <= mem_4H_w;
                end
                if (card[3:0] == 4'd5) begin
                    mem_output_color <= mem_5H_w;
                end
                if (card[3:0] == 4'd6) begin
                    mem_output_color <= mem_6H_w;
                end
                if (card[3:0] == 4'd7) begin
                    mem_output_color <= mem_7H_w;
                end
                if (card[3:0] == 4'd8) begin
                    mem_output_color <= mem_8H_w;
                end
                if (card[3:0] == 4'd9) begin
                    mem_output_color <= mem_9H_w;
                end
                if (card[3:0] == 4'd10) begin
                    mem_output_color <= mem_TH_w;
                end
                if (card[3:0] == 4'd11) begin
                    mem_output_color <= mem_JH_w;
                end
                if (card[3:0] == 4'd12) begin
                    mem_output_color <= mem_QH_w;
                end
                if (card[3:0] == 4'd13) begin
                    mem_output_color <= mem_KH_w;
                end
                
            end

            if (card[5:4] == 2'b11) begin
                
                if (card[3:0] == 4'd1) begin
                    mem_output_color <= mem_AS_w;
                end
                if (card[3:0] == 4'd2) begin
                    mem_output_color <= mem_2S_w;
                end
                if (card[3:0] == 4'd3) begin
                    mem_output_color <= mem_3S_w;
                end
                if (card[3:0] == 4'd4) begin
                    mem_output_color <= mem_4S_w;
                end
                if (card[3:0] == 4'd5) begin
                    mem_output_color <= mem_5S_w;
                end
                if (card[3:0] == 4'd6) begin
                    mem_output_color <= mem_6S_w;
                end
                if (card[3:0] == 4'd7) begin
                    mem_output_color <= mem_7S_w;
                end
                if (card[3:0] == 4'd8) begin
                    mem_output_color <= mem_8S_w;
                end
                if (card[3:0] == 4'd9) begin
                    mem_output_color <= mem_9S_w;
                end
                if (card[3:0] == 4'd10) begin
                    mem_output_color <= mem_TS_w;
                end
                if (card[3:0] == 4'd11) begin
                    mem_output_color <= mem_JS_w;
                end
                if (card[3:0] == 4'd12) begin
                    mem_output_color <= mem_QS_w;
                end
                if (card[3:0] == 4'd13) begin
                    mem_output_color <= mem_KS_w;
                end

            end
        end
    end

    assign q = mem_output_color;

endmodule