/*
 * CorePort - A simple Wishbone GPIO port peripheral
 *
 * Matt Thompson <matt@extent3d.com>
 *
 * The peripheral has the following registers:
 *
 * | Register | Offset  | Description                          |
 * |----------|---------|--------------------------------------|
 * | DATAR    | 0x00    | Data Register                        |
 * | DDR      | 0x04    | Direction Register                   |
 * | IMR      | 0x08    | Interrupt Mask                       |
 * | IFR      | 0x0C    | Interrupt Flag                       |
 * | IER      | 0x10    | Interrupt Edge (not implemented yet) |
 * | DIR      | 0x14    | Data Inversion Register              |
 */

module coreport #(
  parameter WIDTH = 8,
  parameter INITIAL_DDR = 0,
  parameter INITIAL_DATAR = 0,
  parameter INITIAL_DIR = 0,
  parameter TRISTATE = "GENERIC"
)(
  /* Wishbone Interface */
  input                       wb_clk,
  input                       wb_rst,
  input         [31:0]        wb_adr_i,
  input         [WIDTH-1:0]   wb_dat_i,
  input                       wb_we_i,
  input                       wb_cyc_i,
  input                       wb_stb_i,
  input         [2:0]         wb_cti_i,
  input         [1:0]         wb_bte_i,
  output reg    [WIDTH-1:0]   wb_dat_o,
  output                      wb_ack_o,
  output                      wb_err_o,
  output                      wb_rty_o,
 
  /* Physical pin interface */ 
  inout         [WIDTH-1:0]   gpio_io,

  /* Interrupt Output */
  output                      irq
);

/* Data Register */
reg   [WIDTH-1:0]   datar;

/* Data Invert Register */
reg   [WIDTH-1:0]   dir;

/* Data Direction Register */
reg   [WIDTH-1:0]   ddr;

/* Interrupt Mask Register */
reg   [WIDTH-1:0]   imr;

/* Interrupt Flag Register */
reg   [WIDTH-1:0]   ifr;

/* Interrupt Edge Register */
reg   [WIDTH-1:0]   ier;

wire  [WIDTH-1:0]   gpio_in;

/* Tristate pin logic */
genvar i;
generate
  if(TRISTATE=="ICESTORM") begin : icestorm_tristate
    // Instantiate an SB_IO primitive for each IO port
    for (i = 0; i < WIDTH; i = i+1) begin: coreport_tristate
      SB_IO #( 
        .PIN_TYPE(6'b 1010_01), 
        .PULLUP(1'b0) 
      ) io_buf ( 
        .PACKAGE_PIN(gpio_io[i]), 
        .OUTPUT_ENABLE(ddr[i]), 
        .D_OUT_0(datar[i]),
        .D_IN_0(gpio_in[i])
      ); 
    end
  end else if(TRISTATE=="TRELLIS") begin : trellis_tristate
    // Instantiate a TRELLIS_IO primitive for each IO port
    for (i = 0; i < WIDTH; i = i+1) begin: coreport_tristate
      TRELLIS_IO #(
        .DIR("BIDIR")
      ) io_buf (
        .B(gpio_io[i]),
        .O(gpio_in[i]),
        .I(datar[i]),
        .T(~ddr[i])
      );
    end
  end else begin
    for (i = 0; i < WIDTH; i = i+1) begin: coreport_tristate
      assign gpio_io[i] = (ddr[i] && !wb_rst) ? datar[i] : 1'bz;
      assign gpio_in[i] = ~ddr[i] ? gpio_io[i] : 1'bz;
    end
  end
endgenerate

/* Interrupt signal generation */
assign irq = (ifr == 0) ? 1'b0 : 1'b1;

/* Register Writes */
always @(posedge wb_clk) begin
  if (wb_rst) begin
    datar <= INITIAL_DATAR;
    dir <= INITIAL_DIR;
    ddr <= INITIAL_DDR;
    imr <= {WIDTH{1'b0}};
    ifr <= {WIDTH{1'b0}}; 
    ier <= {WIDTH{1'b0}}; 
  end

  else if (wb_cyc_i & wb_stb_i && wb_we_i) begin
    case(wb_adr_i[7:0])
      8'h00 : datar <= wb_dat_i ^ dir;
      8'h04 : ddr <= wb_dat_i;
      8'h08 : imr <= wb_dat_i;
      8'h0C : ifr <= wb_dat_i;
      8'h10 : ier <= wb_dat_i;
      8'h14 : dir <= wb_dat_i;
    endcase
  end
  else begin
    //ifr <= (imr & ~ddr) & (gpio_in | ifr);
  end
end

/* Register Reads */
always @(posedge wb_clk) begin
  if (wb_cyc_i & wb_stb_i & !wb_we_i) begin
    case(wb_adr_i[7:0])
      8'h00 : wb_dat_o <= gpio_in ^ dir;
      8'h04 : wb_dat_o <= ddr;
      8'h08 : wb_dat_o <= imr;
      8'h0C : wb_dat_o <= ifr;
      8'h10 : wb_dat_o <= ier;
      8'h14 : wb_dat_o <= dir;
    endcase
  end
end

// Ack generation
/*
always @(posedge wb_clk)
  if (wb_rst)
    wb_ack_o <= 0;
  else if (wb_cyc_i & wb_stb_i & !wb_ack_o)
    wb_ack_o <= 1;
  else
    wb_ack_o <= 0;
*/

assign wb_ack_o = (wb_stb_i);

assign wb_err_o = 0;
assign wb_rty_o = 0;

endmodule
