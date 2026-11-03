library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Elastic adder: waits for both operands, adds them in the same cycle.
entity add is
  generic (
    DATA_WIDTH : natural := 32
  );
  port (
    clk, rst     : in  std_logic;
    lhs          : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    lhs_valid    : in  std_logic;
    lhs_ready    : out std_logic;
    rhs          : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    rhs_valid    : in  std_logic;
    rhs_ready    : out std_logic;
    result       : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    result_valid : out std_logic;
    result_ready : in  std_logic
  );
end entity;

architecture rtl of add is
  signal operands_valid : std_logic_vector(1 downto 0);   -- bit 0 = lhs, bit 1 = rhs
  signal operands_ready : std_logic_vector(1 downto 0);
begin
  operands_valid <= rhs_valid & lhs_valid;
  lhs_ready      <= operands_ready(0);
  rhs_ready      <= operands_ready(1);

  j: entity work.join
    generic map (SIZE => 2)
    port map (ins_valid => operands_valid, ins_ready => operands_ready,
              outs_valid => result_valid, outs_ready => result_ready);

  result <= std_logic_vector(signed(lhs) + signed(rhs));
end architecture;
