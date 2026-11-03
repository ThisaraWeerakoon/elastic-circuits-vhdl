library ieee;
use ieee.std_logic_1164.all;
use work.elastic_pkg.all;

entity tb_basic is
end entity;

architecture sim of tb_basic is
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  -- Test A: stim_source -> const(42) -> check_sink
  signal a_tok                    : std_logic_vector(0 downto 0);
  signal a_tok_valid, a_tok_ready : std_logic;
  signal a_out                    : std_logic_vector(31 downto 0);
  signal a_out_valid, a_out_ready : std_logic;
  signal a_done                   : std_logic;
  -- Test B: source -> const(-7) -> sink
  signal b_valid, b_ready         : std_logic;
  signal b_out                    : std_logic_vector(31 downto 0);
  signal b_out_valid, b_out_ready : std_logic;
  -- Test C: stim_source -> sink (every token must be consumed)
  signal c_data                   : std_logic_vector(31 downto 0);
  signal c_valid, c_ready         : std_logic;
  signal c_done                   : std_logic;
begin
  clk <= not clk after 5 ns;
  rst <= '0' after 22 ns;

  -- Test A: four control tokens in, four 42s out
  a_src: entity work.stim_source
    generic map (DATA_WIDTH => 1, VALUES => (0, 0, 0, 0), VALID_PERCENT => 50, SEED => 1)
    port map (clk => clk, rst => rst, outs => a_tok, outs_valid => a_tok_valid,
              outs_ready => a_tok_ready, done => open);
  a_dut: entity work.const
    generic map (VALUE => 42)
    port map (clk => clk, rst => rst, ctrl_valid => a_tok_valid, ctrl_ready => a_tok_ready,
              outs => a_out, outs_valid => a_out_valid, outs_ready => a_out_ready);
  a_snk: entity work.check_sink
    generic map (NAME => "const42", EXPECTED => (42, 42, 42, 42), READY_PERCENT => 50, SEED => 2)
    port map (clk => clk, rst => rst, ins => a_out, ins_valid => a_out_valid,
              ins_ready => a_out_ready, done => a_done);

  -- Test B: an always-valid -7
  b_src: entity work.source
    port map (clk => clk, rst => rst, outs_valid => b_valid, outs_ready => b_ready);
  b_dut: entity work.const
    generic map (VALUE => -7)
    port map (clk => clk, rst => rst, ctrl_valid => b_valid, ctrl_ready => b_ready,
              outs => b_out, outs_valid => b_out_valid, outs_ready => b_out_ready);
  b_snk: entity work.sink
    port map (clk => clk, rst => rst, ins => b_out, ins_valid => b_out_valid,
              ins_ready => b_out_ready);

  -- Test C: the sink must swallow all three tokens
  c_src: entity work.stim_source
    generic map (VALUES => (1, 2, 3), VALID_PERCENT => 50, SEED => 4)
    port map (clk => clk, rst => rst, outs => c_data, outs_valid => c_valid,
              outs_ready => c_ready, done => c_done);
  c_dut: entity work.sink
    port map (clk => clk, rst => rst, ins => c_data, ins_valid => c_valid, ins_ready => c_ready);

  finish: process
  begin
    wait until (a_done and c_done) = '1' for 10 us;
    assert (a_done and c_done) = '1' report "TIMEOUT" severity failure;
    assert b_out_valid = '1' and b_out = to_slv(-7, 32)
      report "source + const(-7) is wrong" severity error;
    report "tb_basic PASSED";
    std.env.finish;
  end process;
end architecture;
