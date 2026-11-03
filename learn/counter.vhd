library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;        -- unsigned, signed, to_integer, ...

entity counter is
  generic (
    WIDTH : natural := 4         -- default value, can be overridden
  );
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    enable : in  std_logic;
    count  : out std_logic_vector(WIDTH - 1 downto 0)
  );
end entity;

architecture rtl of counter is
  signal count_r : unsigned(WIDTH - 1 downto 0);   -- "_r" marks a register
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        count_r <= (others => '0');    -- all bits '0', whatever WIDTH is
      elsif enable = '1' then
        count_r <= count_r + 1;        -- wraps around at 2**WIDTH
      end if;
    end if;
  end process;

  count <= std_logic_vector(count_r);  -- convert at the port
end architecture;
