library ieee;
use ieee.std_logic_1164.all;
use work.elastic_pkg.all;

-- Hand-built dynamically scheduled circuit for:
--
--   int s = 1;
--   for (int i = 0; i < N; i++) {
--     if (x[i] > 0) s = s * x[i];
--     else          s = s + x[i];
--   }
--   return s;
--
-- x[] arrives as a stream, one element per iteration.
entity kernel_dynamic is
  generic (
    N           : positive := 16;
    MUL_LATENCY : positive := 4
  );
  port (
    clk, rst     : in  std_logic;
    start_valid  : in  std_logic;           -- one control token starts the loop
    start_ready  : out std_logic;
    x            : in  std_logic_vector(31 downto 0);
    x_valid      : in  std_logic;
    x_ready      : out std_logic;
    result       : out std_logic_vector(31 downto 0);
    result_valid : out std_logic;
    result_ready : in  std_logic
  );
end entity;

architecture rtl of kernel_dynamic is
  -- Every channel <name> has <name>_v (valid) and <name>_r (ready).
  -- start
  signal start_fk                 : data_array(1 downto 0)(0 downto 0);
  signal start_fk_v, start_fk_r   : std_logic_vector(1 downto 0);
  -- i loop
  signal i_mrg_in                 : data_array(1 downto 0)(31 downto 0);  -- 0: initial 0, 1: i + 1
  signal i_mrg_in_v, i_mrg_in_r   : std_logic_vector(1 downto 0);
  signal i_mrg, i_ob, i_buf       : std_logic_vector(31 downto 0);
  signal i_mrg_v, i_mrg_r         : std_logic;
  signal i_ob_v, i_ob_r           : std_logic;
  signal i_buf_v, i_buf_r         : std_logic;
  signal i_fk                     : data_array(1 downto 0)(31 downto 0);
  signal i_fk_v, i_fk_r           : std_logic_vector(1 downto 0);
  signal n_tok_v, n_tok_r         : std_logic;
  signal n_c                      : std_logic_vector(31 downto 0);
  signal n_c_v, n_c_r             : std_logic;
  signal lc                       : std_logic_vector(0 downto 0);        -- i < N
  signal lc_v, lc_r               : std_logic;
  signal lc_fk                    : data_array(1 downto 0)(0 downto 0);
  signal lc_fk_v, lc_fk_r         : std_logic_vector(1 downto 0);
  signal i_cont, i_exit           : std_logic_vector(31 downto 0);
  signal i_cont_v, i_cont_r       : std_logic;
  signal i_exit_v, i_exit_r       : std_logic;
  signal one_tok_v, one_tok_r     : std_logic;
  signal one_c                    : std_logic_vector(31 downto 0);
  signal one_c_v, one_c_r         : std_logic;
  -- s loop
  signal s_mrg_in                 : data_array(1 downto 0)(31 downto 0);  -- 0: initial 1, 1: new s
  signal s_mrg_in_v, s_mrg_in_r   : std_logic_vector(1 downto 0);
  signal s_mrg, s_ob, s_buf       : std_logic_vector(31 downto 0);
  signal s_mrg_v, s_mrg_r         : std_logic;
  signal s_ob_v, s_ob_r           : std_logic;
  signal s_buf_v, s_buf_r         : std_logic;
  signal s_body                   : std_logic_vector(31 downto 0);
  signal s_body_v, s_body_r       : std_logic;
  -- loop body
  signal x_fk                     : data_array(1 downto 0)(31 downto 0);
  signal x_fk_v, x_fk_r           : std_logic_vector(1 downto 0);
  signal zero_tok_v, zero_tok_r   : std_logic;
  signal zero_c                   : std_logic_vector(31 downto 0);
  signal zero_c_v, zero_c_r       : std_logic;
  signal pc                       : std_logic_vector(0 downto 0);        -- x > 0
  signal pc_v, pc_r               : std_logic;
  signal pc_fk                    : data_array(1 downto 0)(0 downto 0);
  signal pc_fk_v, pc_fk_r         : std_logic_vector(1 downto 0);
  signal s_mul, s_add             : std_logic_vector(31 downto 0);
  signal s_mul_v, s_mul_r         : std_logic;
  signal s_add_v, s_add_r         : std_logic;
  signal x_mul, x_add             : std_logic_vector(31 downto 0);
  signal x_mul_v, x_mul_r         : std_logic;
  signal x_add_v, x_add_r         : std_logic;
  signal body_in                  : data_array(1 downto 0)(31 downto 0);  -- 0: product, 1: sum
  signal body_in_v, body_in_r     : std_logic_vector(1 downto 0);
begin
  ------------------------------------------------------------------ start
  -- One start token becomes the initial values i = 0 and s = 1.
  fork_start: entity work.fork
    generic map (SIZE => 2, DATA_WIDTH => 1)
    port map (clk => clk, rst => rst, ins => "0", ins_valid => start_valid,
              ins_ready => start_ready, outs => start_fk, outs_valid => start_fk_v,
              outs_ready => start_fk_r);
  const_i0: entity work.const
    generic map (VALUE => 0)
    port map (clk => clk, rst => rst, ctrl_valid => start_fk_v(0), ctrl_ready => start_fk_r(0),
              outs => i_mrg_in(0), outs_valid => i_mrg_in_v(0), outs_ready => i_mrg_in_r(0));
  const_s1: entity work.const
    generic map (VALUE => 1)
    port map (clk => clk, rst => rst, ctrl_valid => start_fk_v(1), ctrl_ready => start_fk_r(1),
              outs => s_mrg_in(0), outs_valid => s_mrg_in_v(0), outs_ready => s_mrg_in_r(0));

  ------------------------------------------------------------------ i loop
  merge_i: entity work.merge
    port map (clk => clk, rst => rst, ins => i_mrg_in, ins_valid => i_mrg_in_v,
              ins_ready => i_mrg_in_r, outs => i_mrg, outs_valid => i_mrg_v, outs_ready => i_mrg_r);
  oehb_i: entity work.oehb                          -- cuts the valid path of the loop
    port map (clk => clk, rst => rst, ins => i_mrg, ins_valid => i_mrg_v, ins_ready => i_mrg_r,
              outs => i_ob, outs_valid => i_ob_v, outs_ready => i_ob_r);
  tehb_i: entity work.tehb                          -- cuts the ready path of the loop
    port map (clk => clk, rst => rst, ins => i_ob, ins_valid => i_ob_v, ins_ready => i_ob_r,
              outs => i_buf, outs_valid => i_buf_v, outs_ready => i_buf_r);
  fork_i: entity work.fork
    generic map (SIZE => 2)
    port map (clk => clk, rst => rst, ins => i_buf, ins_valid => i_buf_v, ins_ready => i_buf_r,
              outs => i_fk, outs_valid => i_fk_v, outs_ready => i_fk_r);
  source_n: entity work.source
    port map (clk => clk, rst => rst, outs_valid => n_tok_v, outs_ready => n_tok_r);
  const_n: entity work.const
    generic map (VALUE => N)
    port map (clk => clk, rst => rst, ctrl_valid => n_tok_v, ctrl_ready => n_tok_r,
              outs => n_c, outs_valid => n_c_v, outs_ready => n_c_r);
  cmp_lt: entity work.cmp                           -- lc = (i < N)
    generic map (PREDICATE => "slt")
    port map (clk => clk, rst => rst,
              lhs => i_fk(0), lhs_valid => i_fk_v(0), lhs_ready => i_fk_r(0),
              rhs => n_c, rhs_valid => n_c_v, rhs_ready => n_c_r,
              result => lc, result_valid => lc_v, result_ready => lc_r);
  fork_lc: entity work.fork
    generic map (SIZE => 2, DATA_WIDTH => 1)
    port map (clk => clk, rst => rst, ins => lc, ins_valid => lc_v, ins_ready => lc_r,
              outs => lc_fk, outs_valid => lc_fk_v, outs_ready => lc_fk_r);
  cond_br_i: entity work.cond_br
    port map (clk => clk, rst => rst,
              condition => lc_fk(0), condition_valid => lc_fk_v(0), condition_ready => lc_fk_r(0),
              data => i_fk(1), data_valid => i_fk_v(1), data_ready => i_fk_r(1),
              trueOut => i_cont, trueOut_valid => i_cont_v, trueOut_ready => i_cont_r,
              falseOut => i_exit, falseOut_valid => i_exit_v, falseOut_ready => i_exit_r);
  sink_i: entity work.sink                          -- i is not needed after the loop
    port map (clk => clk, rst => rst, ins => i_exit, ins_valid => i_exit_v, ins_ready => i_exit_r);
  source_1: entity work.source
    port map (clk => clk, rst => rst, outs_valid => one_tok_v, outs_ready => one_tok_r);
  const_1: entity work.const
    generic map (VALUE => 1)
    port map (clk => clk, rst => rst, ctrl_valid => one_tok_v, ctrl_ready => one_tok_r,
              outs => one_c, outs_valid => one_c_v, outs_ready => one_c_r);
  add_i: entity work.add                            -- i + 1, back to the top of the loop
    port map (clk => clk, rst => rst,
              lhs => i_cont, lhs_valid => i_cont_v, lhs_ready => i_cont_r,
              rhs => one_c, rhs_valid => one_c_v, rhs_ready => one_c_r,
              result => i_mrg_in(1), result_valid => i_mrg_in_v(1), result_ready => i_mrg_in_r(1));

  ------------------------------------------------------------------ s loop
  merge_s: entity work.merge
    port map (clk => clk, rst => rst, ins => s_mrg_in, ins_valid => s_mrg_in_v,
              ins_ready => s_mrg_in_r, outs => s_mrg, outs_valid => s_mrg_v, outs_ready => s_mrg_r);
  oehb_s: entity work.oehb
    port map (clk => clk, rst => rst, ins => s_mrg, ins_valid => s_mrg_v, ins_ready => s_mrg_r,
              outs => s_ob, outs_valid => s_ob_v, outs_ready => s_ob_r);
  tehb_s: entity work.tehb
    port map (clk => clk, rst => rst, ins => s_ob, ins_valid => s_ob_v, ins_ready => s_ob_r,
              outs => s_buf, outs_valid => s_buf_v, outs_ready => s_buf_r);
  cond_br_s: entity work.cond_br                    -- loop done? s leaves as the result
    port map (clk => clk, rst => rst,
              condition => lc_fk(1), condition_valid => lc_fk_v(1), condition_ready => lc_fk_r(1),
              data => s_buf, data_valid => s_buf_v, data_ready => s_buf_r,
              trueOut => s_body, trueOut_valid => s_body_v, trueOut_ready => s_body_r,
              falseOut => result, falseOut_valid => result_valid, falseOut_ready => result_ready);

  ------------------------------------------------------------------ loop body
  fork_x: entity work.fork
    generic map (SIZE => 2)
    port map (clk => clk, rst => rst, ins => x, ins_valid => x_valid, ins_ready => x_ready,
              outs => x_fk, outs_valid => x_fk_v, outs_ready => x_fk_r);
  source_0: entity work.source
    port map (clk => clk, rst => rst, outs_valid => zero_tok_v, outs_ready => zero_tok_r);
  const_0: entity work.const
    generic map (VALUE => 0)
    port map (clk => clk, rst => rst, ctrl_valid => zero_tok_v, ctrl_ready => zero_tok_r,
              outs => zero_c, outs_valid => zero_c_v, outs_ready => zero_c_r);
  cmp_pos: entity work.cmp                          -- pc = (x > 0)
    generic map (PREDICATE => "sgt")
    port map (clk => clk, rst => rst,
              lhs => x_fk(0), lhs_valid => x_fk_v(0), lhs_ready => x_fk_r(0),
              rhs => zero_c, rhs_valid => zero_c_v, rhs_ready => zero_c_r,
              result => pc, result_valid => pc_v, result_ready => pc_r);
  fork_pc: entity work.fork
    generic map (SIZE => 2, DATA_WIDTH => 1)
    port map (clk => clk, rst => rst, ins => pc, ins_valid => pc_v, ins_ready => pc_r,
              outs => pc_fk, outs_valid => pc_fk_v, outs_ready => pc_fk_r);
  cond_br_sb: entity work.cond_br                   -- steer s to mul or add
    port map (clk => clk, rst => rst,
              condition => pc_fk(0), condition_valid => pc_fk_v(0), condition_ready => pc_fk_r(0),
              data => s_body, data_valid => s_body_v, data_ready => s_body_r,
              trueOut => s_mul, trueOut_valid => s_mul_v, trueOut_ready => s_mul_r,
              falseOut => s_add, falseOut_valid => s_add_v, falseOut_ready => s_add_r);
  cond_br_x: entity work.cond_br                    -- steer x the same way
    port map (clk => clk, rst => rst,
              condition => pc_fk(1), condition_valid => pc_fk_v(1), condition_ready => pc_fk_r(1),
              data => x_fk(1), data_valid => x_fk_v(1), data_ready => x_fk_r(1),
              trueOut => x_mul, trueOut_valid => x_mul_v, trueOut_ready => x_mul_r,
              falseOut => x_add, falseOut_valid => x_add_v, falseOut_ready => x_add_r);
  mul_s: entity work.mul                            -- s * x, MUL_LATENCY cycles
    generic map (LATENCY => MUL_LATENCY)
    port map (clk => clk, rst => rst,
              lhs => s_mul, lhs_valid => s_mul_v, lhs_ready => s_mul_r,
              rhs => x_mul, rhs_valid => x_mul_v, rhs_ready => x_mul_r,
              result => body_in(0), result_valid => body_in_v(0), result_ready => body_in_r(0));
  add_s: entity work.add                            -- s + x, same cycle
    port map (clk => clk, rst => rst,
              lhs => s_add, lhs_valid => s_add_v, lhs_ready => s_add_r,
              rhs => x_add, rhs_valid => x_add_v, rhs_ready => x_add_r,
              result => body_in(1), result_valid => body_in_v(1), result_ready => body_in_r(1));
  merge_body: entity work.merge                     -- end of the if: new s goes back to merge_s
    port map (clk => clk, rst => rst, ins => body_in, ins_valid => body_in_v,
              ins_ready => body_in_r, outs => s_mrg_in(1), outs_valid => s_mrg_in_v(1),
              outs_ready => s_mrg_in_r(1));
end architecture;
