library ieee;
use ieee.std_logic_1164.all;

entity tb_toolkit is
end entity;

architecture sim of tb_toolkit is
  constant VALUES : integer_vector := (5, -3, 0, 42, 7, 100, -1000);
  signal clk          : std_logic := '0';
  signal rst          : std_logic := '1';
  signal data         : std_logic_vector(31 downto 0);
  signal valid, ready : std_logic;
  signal src_done     : std_logic;
  signal snk_done     : std_logic;
begin
  clk <= not clk after 5 ns;
  rst <= '0' after 22 ns;          -- released between clock edges, never on one

  src: entity work.stim_source
    generic map (VALUES => VALUES, VALID_PERCENT => 60, SEED => 3)
    port map (clk => clk, rst => rst, outs => data, outs_valid => valid,
              outs_ready => ready, done => src_done);

  snk: entity work.check_sink
    generic map (NAME => "toolkit", EXPECTED => VALUES, READY_PERCENT => 50, SEED => 9)
    port map (clk => clk, rst => rst, ins => data, ins_valid => valid,
              ins_ready => ready, done => snk_done);

  finish: process
  begin
    wait until snk_done = '1' for 10 us;
    assert snk_done = '1' report "TIMEOUT: not all tokens arrived" severity failure;
    report "tb_toolkit PASSED";
    std.env.finish;
  end process;
end architecture;
