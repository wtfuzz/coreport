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
 */

module coreport(
  /* Wishbone Interface */
  input                   wb_clk,
  input                   wb_rst,

  input         [31:0]    wb_adr_i,
  input         [31:0]    wb_dat_i,
  input                   wb_we_i,
  input                   wb_cyc_i,
  input                   wb_stb_i,
  input         [2:0]     wb_cti_i,
  input         [1:0]     wb_bte_i,
  output reg    [31:0]    wb_dat_o,
  output reg              wb_ack_o,
  output                  wb_err_o,
  output                  wb_rty_o,
 
  /* Physical pin interface */ 
  inout         [31:0]    gpio_io,

  /* Interrupt Output */
  output                  irq
);

/* Data Register */
reg   [31:0]    datar;

/* Data Direction Register */
reg   [31:0]    ddr;

/* Interrupt Mask Register */
reg   [31:0]    imr;

/* Interrupt Flag Register */
reg   [31:0]    ifr;
reg   [31:0]    icr;

/* Interrupt Edge Register */
reg   [31:0]    ier;

/* Tristate pin logic */
genvar                    i;
generate
  for (i = 0; i < 32; i = i+1) begin: coreport_tristate
    assign gpio_io[i] = ddr[i] ? datar[i] : 1'bz;
  end
endgenerate

/* Interrupt signal generation */
assign irq = (ifr == 0) ? 1'b0 : 1'b1;

/* Register Writes */
always @(posedge wb_clk)
  if (wb_rst) begin
    datar <= 32'd0;
    ddr <= 32'd0;
    imr <= 32'd0;
    ifr <= 32'd0; 
    ier <= 32'd0; 
  end
  else if (wb_cyc_i && wb_stb_i && wb_we_i) begin
    if (wb_adr_i[7:0] == 8'h0) begin
      datar <= wb_dat_i;
    end
    else if (wb_adr_i[7:0] == 8'h4) begin
      ddr <= wb_dat_i;
    end
    else if (wb_adr_i[7:0] == 8'h8) begin
      imr <= wb_dat_i;
    end
    else if (wb_adr_i[7:0] == 8'hc) begin
      ifr <= wb_dat_i;
    end
    else if (wb_adr_i[7:0] == 8'h10) begin
      ier <= wb_dat_i;
    end
  end
  else begin
    ifr <= (imr & ~ddr) & (gpio_io | ifr);
  end

/* Register Reads */
always @(posedge wb_clk) begin
  if (wb_cyc_i & wb_stb_i & !wb_we_i) begin
    if (wb_adr_i[7:0] == 8'h0) begin
      wb_dat_o <= gpio_io;
    end

    if (wb_adr_i[7:0] == 8'h4) begin
      wb_dat_o <= ddr;
    end

    if (wb_adr_i[7:0] == 8'h8) begin
      wb_dat_o <= imr;
    end

    if (wb_adr_i[7:0] == 8'hc) begin
      wb_dat_o <= ifr;
    end

    if (wb_adr_i[7:0] == 8'h10) begin
      wb_dat_o <= ier;
    end
  end
end

// Ack generation
always @(posedge wb_clk)
  if (wb_rst)
    wb_ack_o <= 0;
  else if (wb_ack_o)
    wb_ack_o <= 0;
  else if (wb_cyc_i & wb_stb_i & !wb_ack_o)
    wb_ack_o <= 1;

assign wb_err_o = 0;
assign wb_rty_o = 0;

endmodule
