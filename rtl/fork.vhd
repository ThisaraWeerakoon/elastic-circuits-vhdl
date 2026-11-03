library ieee;
use ieee.std_logic_1164.all;
use work.elastic_pkg.all;

-- Eager fork: copies each input token to SIZE outputs. Each output may
-- take its copy in a different cycle; the input token is released once
-- every output has taken it.
entity fork is
  generic (
    SIZE       : positive := 2;
    DATA_WIDTH : natural  := 32
  );
  port (
    clk, rst   : in  std_logic;
    ins        : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    ins_valid  : in  std_logic;
    ins_ready  : out std_logic;
    outs       : out data_array(SIZE - 1 downto 0)(DATA_WIDTH - 1 downto 0);
    outs_valid : out std_logic_vector(SIZE - 1 downto 0);
    outs_ready : in  std_logic_vector(SIZE - 1 downto 0)
  );
end entity;

architecture rtl of fork is
  signal sent_r    : std_logic_vector(SIZE - 1 downto 0);  -- output i already has this token
  signal taken     : std_logic_vector(SIZE - 1 downto 0);  -- output i has it or takes it now
  signal all_taken : std_logic;
begin
  gen_outputs: for i in 0 to SIZE - 1 generate
    outs(i)       <= ins;
    outs_valid(i) <= ins_valid and not sent_r(i);
    taken(i)      <= sent_r(i) or outs_ready(i);
  end generate;

  all_taken <= and taken;
  ins_ready <= all_taken;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        sent_r <= (others => '0');
      elsif ins_valid = '1' and all_taken = '1' then
        sent_r <= (others => '0');          -- token fully delivered: start fresh
      else
        for i in 0 to SIZE - 1 loop
          if ins_valid = '1' and outs_ready(i) = '1' then
            sent_r(i) <= '1';               -- output i got its copy this cycle
          end if;
        end loop;
      end if;
    end if;
  end process;
end architecture;
