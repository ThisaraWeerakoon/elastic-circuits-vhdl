library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Elastic comparator: result is "1" when (lhs PREDICATE rhs) is true.
-- PREDICATE: "slt" = signed less than, "sgt" = signed greater than, "eq" = equal.
entity cmp is
  generic (
    DATA_WIDTH : natural := 32;
    PREDICATE  : string  := "slt"
  );
  port (
    clk, rst     : in  std_logic;
    lhs          : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    lhs_valid    : in  std_logic;
    lhs_ready    : out std_logic;
    rhs          : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    rhs_valid    : in  std_logic;
    rhs_ready    : out std_logic;
    result       : out std_logic_vector(0 downto 0);
    result_valid : out std_logic;
    result_ready : in  std_logic
  );
end entity;

architecture rtl of cmp is
  signal operands_valid : std_logic_vector(1 downto 0);
  signal operands_ready : std_logic_vector(1 downto 0);
begin
  assert PREDICATE = "slt" or PREDICATE = "sgt" or PREDICATE = "eq"
    report "cmp: unknown PREDICATE " & PREDICATE severity failure;

  operands_valid <= rhs_valid & lhs_valid;
  lhs_ready      <= operands_ready(0);
  rhs_ready      <= operands_ready(1);

  j: entity work.join
    generic map (SIZE => 2)
    port map (ins_valid => operands_valid, ins_ready => operands_ready,
              outs_valid => result_valid, outs_ready => result_ready);

  process (all)
    variable holds : boolean;
  begin
    if PREDICATE = "slt" then
      holds := signed(lhs) < signed(rhs);
    elsif PREDICATE = "sgt" then
      holds := signed(lhs) > signed(rhs);
    else
      holds := lhs = rhs;
    end if;
    if holds then
      result <= "1";
    else
      result <= "0";
    end if;
  end process;
end architecture;
