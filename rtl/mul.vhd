library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Pipelined elastic multiplier with LATENCY register stages.
-- The pipeline advances when its last stage is empty or being emptied,
-- and freezes otherwise.
entity mul is
  generic (
    DATA_WIDTH : natural  := 32;
    LATENCY    : positive := 4
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

architecture rtl of mul is
  type stage_data_t is array (1 to LATENCY) of std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal stage_data     : stage_data_t;
  signal stage_valid    : std_logic_vector(1 to LATENCY);
  signal advance        : std_logic;
  signal join_valid     : std_logic;
  signal operands_valid : std_logic_vector(1 downto 0);
  signal operands_ready : std_logic_vector(1 downto 0);
begin
  advance <= (not stage_valid(LATENCY)) or result_ready;

  operands_valid <= rhs_valid & lhs_valid;
  lhs_ready      <= operands_ready(0);
  rhs_ready      <= operands_ready(1);

  j: entity work.join
    generic map (SIZE => 2)
    port map (ins_valid => operands_valid, ins_ready => operands_ready,
              outs_valid => join_valid, outs_ready => advance);

  process (clk)
    variable product : signed(2 * DATA_WIDTH - 1 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        stage_valid <= (others => '0');
      elsif advance = '1' then
        product        := signed(lhs) * signed(rhs);
        stage_valid(1) <= join_valid;
        stage_data(1)  <= std_logic_vector(product(DATA_WIDTH - 1 downto 0));  -- low half, as in C
        for k in 2 to LATENCY loop
          stage_valid(k) <= stage_valid(k - 1);
          stage_data(k)  <= stage_data(k - 1);
        end loop;
      end if;
    end if;
  end process;

  result       <= stage_data(LATENCY);
  result_valid <= stage_valid(LATENCY);
end architecture;
