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
  parameter INITIAL_DDR = 0
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

/* Tristate pin logic */
genvar                    i;
generate
  for (i = 0; i < WIDTH; i = i+1) begin: coreport_tristate
    assign gpio_io[i] = (ddr[i] && !wb_rst) ? datar[i] : 1'bz;
  end
endgenerate

/* Interrupt signal generation */
assign irq = (ifr == 0) ? 1'b0 : 1'b1;

/* Register Writes */
always @(posedge wb_clk) begin
  if (wb_rst) begin
    datar <= `WIDTH'd0;
    dir <= `WIDTH'd0;
    ddr <= `WIDTH'd0;
    imr <= `WIDTH'd0;
    ifr <= `WIDTH'd0; 
    ier <= `WIDTH'd0; 
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
    ifr <= (imr & ~ddr) & (gpio_io | ifr);
  end
end

/* Register Reads */
always @(posedge wb_clk) begin
  if (wb_cyc_i & wb_stb_i & !wb_we_i) begin
    case(wb_adr_i[7:0])
      8'h00 : wb_dat_o <= gpio_io ^ dir;
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
