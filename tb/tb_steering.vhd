library ieee;
use ieee.std_logic_1164.all;
use work.elastic_pkg.all;

entity tb_steering is
end entity;

architecture sim of tb_steering is
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  -- merge test
  signal m_ins             : data_array(1 downto 0)(31 downto 0);
  signal m_ins_v, m_ins_r  : std_logic_vector(1 downto 0);
  signal m_out             : std_logic_vector(31 downto 0);
  signal m_out_v, m_out_r  : std_logic;
  signal m_a_done, m_b_rst : std_logic;
  signal m_done            : std_logic;
  -- mux test
  signal x_idx             : std_logic_vector(0 downto 0);
  signal x_idx_v, x_idx_r  : std_logic;
  signal x_ins             : data_array(1 downto 0)(31 downto 0);
  signal x_ins_v, x_ins_r  : std_logic_vector(1 downto 0);
  signal x_out             : std_logic_vector(31 downto 0);
  signal x_out_v, x_out_r  : std_logic;
  signal x_done            : std_logic;
  -- cond_br test
  signal c_cond              : std_logic_vector(0 downto 0);
  signal c_cond_v, c_cond_r  : std_logic;
  signal c_data              : std_logic_vector(31 downto 0);
  signal c_data_v, c_data_r  : std_logic;
  signal c_t, c_f            : std_logic_vector(31 downto 0);
  signal c_t_v, c_t_r        : std_logic;
  signal c_f_v, c_f_r        : std_logic;
  signal c_t_done, c_f_done  : std_logic;
begin
  clk <= not clk after 5 ns;
  rst <= '0' after 22 ns;

  -- Merge: (1,2,3) arrive first, then (4,5,6)
  m_b_rst <= rst or not m_a_done;
  m_src_a: entity work.stim_source
    generic map (VALUES => (1, 2, 3), VALID_PERCENT => 60, SEED => 61)
    port map (clk => clk, rst => rst, outs => m_ins(0), outs_valid => m_ins_v(0),
              outs_ready => m_ins_r(0), done => m_a_done);
  m_src_b: entity work.stim_source
    generic map (VALUES => (4, 5, 6), VALID_PERCENT => 60, SEED => 62)
    port map (clk => clk, rst => m_b_rst, outs => m_ins(1), outs_valid => m_ins_v(1),
              outs_ready => m_ins_r(1), done => open);
  m_dut: entity work.merge
    port map (clk => clk, rst => rst, ins => m_ins, ins_valid => m_ins_v, ins_ready => m_ins_r,
              outs => m_out, outs_valid => m_out_v, outs_ready => m_out_r);
  m_snk: entity work.check_sink
    generic map (NAME => "merge", EXPECTED => (1, 2, 3, 4, 5, 6), READY_PERCENT => 60, SEED => 63)
    port map (clk => clk, rst => rst, ins => m_out, ins_valid => m_out_v,
              ins_ready => m_out_r, done => m_done);

  -- Mux: the index sequence 0,1,1,0,1,0 interleaves the two inputs
  x_src_idx: entity work.stim_source
    generic map (DATA_WIDTH => 1, VALUES => (0, 1, 1, 0, 1, 0), VALID_PERCENT => 50, SEED => 71)
    port map (clk => clk, rst => rst, outs => x_idx, outs_valid => x_idx_v,
              outs_ready => x_idx_r, done => open);
  x_src_0: entity work.stim_source
    generic map (VALUES => (10, 20, 30), VALID_PERCENT => 70, SEED => 72)
    port map (clk => clk, rst => rst, outs => x_ins(0), outs_valid => x_ins_v(0),
              outs_ready => x_ins_r(0), done => open);
  x_src_1: entity work.stim_source
    generic map (VALUES => (100, 200, 300), VALID_PERCENT => 70, SEED => 73)
    port map (clk => clk, rst => rst, outs => x_ins(1), outs_valid => x_ins_v(1),
              outs_ready => x_ins_r(1), done => open);
  x_dut: entity work.mux
    port map (clk => clk, rst => rst, index => x_idx, index_valid => x_idx_v,
              index_ready => x_idx_r, ins => x_ins, ins_valid => x_ins_v,
              ins_ready => x_ins_r, outs => x_out, outs_valid => x_out_v,
              outs_ready => x_out_r);
  x_snk: entity work.check_sink
    generic map (NAME => "mux", EXPECTED => (10, 100, 200, 20, 300, 30),
                 READY_PERCENT => 60, SEED => 74)
    port map (clk => clk, rst => rst, ins => x_out, ins_valid => x_out_v,
              ins_ready => x_out_r, done => x_done);

  -- cond_br: conditions 1,0,0,1,1,0 split data 1..6
  c_src_cond: entity work.stim_source
    generic map (DATA_WIDTH => 1, VALUES => (1, 0, 0, 1, 1, 0), VALID_PERCENT => 50, SEED => 81)
    port map (clk => clk, rst => rst, outs => c_cond, outs_valid => c_cond_v,
              outs_ready => c_cond_r, done => open);
  c_src_data: entity work.stim_source
    generic map (VALUES => (1, 2, 3, 4, 5, 6), VALID_PERCENT => 70, SEED => 82)
    port map (clk => clk, rst => rst, outs => c_data, outs_valid => c_data_v,
              outs_ready => c_data_r, done => open);
  c_dut: entity work.cond_br
    port map (clk => clk, rst => rst,
              condition => c_cond, condition_valid => c_cond_v, condition_ready => c_cond_r,
              data => c_data, data_valid => c_data_v, data_ready => c_data_r,
              trueOut => c_t, trueOut_valid => c_t_v, trueOut_ready => c_t_r,
              falseOut => c_f, falseOut_valid => c_f_v, falseOut_ready => c_f_r);
  c_snk_t: entity work.check_sink
    generic map (NAME => "cond_br_true", EXPECTED => (1, 4, 5), READY_PERCENT => 50, SEED => 83)
    port map (clk => clk, rst => rst, ins => c_t, ins_valid => c_t_v,
              ins_ready => c_t_r, done => c_t_done);
  c_snk_f: entity work.check_sink
    generic map (NAME => "cond_br_false", EXPECTED => (2, 3, 6), READY_PERCENT => 50, SEED => 84)
    port map (clk => clk, rst => rst, ins => c_f, ins_valid => c_f_v,
              ins_ready => c_f_r, done => c_f_done);

  finish: process
    variable all_done : std_logic;
  begin
    wait until (m_done and x_done and c_t_done and c_f_done) = '1' for 20 us;
    all_done := m_done and x_done and c_t_done and c_f_done;
    assert all_done = '1' report "TIMEOUT" severity failure;
    report "tb_steering PASSED";
    std.env.finish;
  end process;
end architecture;
