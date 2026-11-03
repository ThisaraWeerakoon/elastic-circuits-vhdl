library ieee;
use ieee.std_logic_1164.all;

entity tb_checker_demo is
end entity;

architecture sim of tb_checker_demo is
  signal clk   : std_logic := '0';
  signal rst   : std_logic := '1';
  signal valid : std_logic := '0';
  signal ready : std_logic := '0';               -- consumer is never ready
  signal data  : std_logic_vector(7 downto 0) := x"00";
begin
  clk <= not clk after 5 ns;

  chk: entity work.handshake_checker
    generic map (NAME => "demo", DATA_WIDTH => 8)
    port map (clk => clk, rst => rst, valid => valid, ready => ready, data => data);

  process
  begin
    wait until rising_edge(clk);
    rst   <= '0';
    valid <= '1';
    data  <= x"AA";                 -- offer token AA
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    data  <= x"BB";                 -- BUG: change data while still waiting
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    std.env.finish;
  end process;
end architecture;
