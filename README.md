# CorePort

CorePort is a FuseSoC core which provides a Wishbone GPIO port with interrupt capability.

The data width can be specified using the `WIDTH` parameter.

### Registers

All registers are `WIDTH` bits wide, and each bit represents a port pin.

| Register | Offset  | Description                          |
|----------|---------|--------------------------------------|
| DATAR    | 0x00    | Data Register                        |
| DDR      | 0x04    | Direction Register                   |
| IMR      | 0x08    | Interrupt Mask                       |
| IFR      | 0x0C    | Interrupt Flag                       |
| IER      | 0x10    | Interrupt Edge (not implemented yet) |
| DIR      | 0x14    | Data Inversion Register              |

#### DATAR

Data Register. Read/write.

For input pins, reading DATAR returns the current state of the pin.
For output pins, reading DATAR returns the value being driven on the pin.

#### DDR

Data Direction Register. Read/write.

0: Input
1: Output

#### IMR

Interrupt mask register

0: Interrupt disabled
1: Interrupt enabled

#### IFR

Interrupt flag register. This register is used to determine which pin in the port raised the interrupt line.

This register is latched on interrupt generation per pin. If the pin that generated the interrupt falls, the bit in the IFR register remains set until it is explicitly cleared by a Wishbone master.

The single IRQ output line from the core will remain high as long as IFR has a set bit.

#### DIR

Data Inversion Register

0: Data lines not inverted
1: Data lines are inverted


