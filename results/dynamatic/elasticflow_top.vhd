library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity elasticflow is
  port (
    x_loadData : in std_logic_vector(31 downto 0);
    x_start_valid : in std_logic;
    start_valid : in std_logic;
    clk : in std_logic;
    rst : in std_logic;
    out0_ready : in std_logic;
    x_end_ready : in std_logic;
    end_ready : in std_logic;
    x_start_ready : out std_logic;
    start_ready : out std_logic;
    out0 : out std_logic_vector(31 downto 0);
    out0_valid : out std_logic;
    x_end_valid : out std_logic;
    end_valid : out std_logic;
    x_loadEn : out std_logic;
    x_loadAddr : out std_logic_vector(5 downto 0);
    x_storeEn : out std_logic;
    x_storeAddr : out std_logic_vector(5 downto 0);
    x_storeData : out std_logic_vector(31 downto 0)
  );
end entity;

architecture behavioral of elasticflow is

  signal fork0_outs_0_valid : std_logic;
  signal fork0_outs_0_ready : std_logic;
  signal fork0_outs_1_valid : std_logic;
  signal fork0_outs_1_ready : std_logic;
  signal fork0_outs_2_valid : std_logic;
  signal fork0_outs_2_ready : std_logic;
  signal fork0_outs_3_valid : std_logic;
  signal fork0_outs_3_ready : std_logic;
  signal mem_controller1_ldData_0 : std_logic_vector(31 downto 0);
  signal mem_controller1_ldData_0_valid : std_logic;
  signal mem_controller1_ldData_0_ready : std_logic;
  signal mem_controller1_memEnd_valid : std_logic;
  signal mem_controller1_memEnd_ready : std_logic;
  signal mem_controller1_loadEn : std_logic;
  signal mem_controller1_loadAddr : std_logic_vector(5 downto 0);
  signal mem_controller1_storeEn : std_logic;
  signal mem_controller1_storeAddr : std_logic_vector(5 downto 0);
  signal mem_controller1_storeData : std_logic_vector(31 downto 0);
  signal constant5_outs : std_logic_vector(0 downto 0);
  signal constant5_outs_valid : std_logic;
  signal constant5_outs_ready : std_logic;
  signal extui1_outs : std_logic_vector(5 downto 0);
  signal extui1_outs_valid : std_logic;
  signal extui1_outs_ready : std_logic;
  signal constant6_outs : std_logic_vector(0 downto 0);
  signal constant6_outs_valid : std_logic;
  signal constant6_outs_ready : std_logic;
  signal extui2_outs : std_logic_vector(31 downto 0);
  signal extui2_outs_valid : std_logic;
  signal extui2_outs_ready : std_logic;
  signal mux0_outs : std_logic_vector(5 downto 0);
  signal mux0_outs_valid : std_logic;
  signal mux0_outs_ready : std_logic;
  signal buffer0_outs : std_logic_vector(5 downto 0);
  signal buffer0_outs_valid : std_logic;
  signal buffer0_outs_ready : std_logic;
  signal buffer1_outs : std_logic_vector(5 downto 0);
  signal buffer1_outs_valid : std_logic;
  signal buffer1_outs_ready : std_logic;
  signal fork1_outs_0 : std_logic_vector(5 downto 0);
  signal fork1_outs_0_valid : std_logic;
  signal fork1_outs_0_ready : std_logic;
  signal fork1_outs_1 : std_logic_vector(5 downto 0);
  signal fork1_outs_1_valid : std_logic;
  signal fork1_outs_1_ready : std_logic;
  signal extui3_outs : std_logic_vector(6 downto 0);
  signal extui3_outs_valid : std_logic;
  signal extui3_outs_ready : std_logic;
  signal constant7_outs : std_logic_vector(6 downto 0);
  signal constant7_outs_valid : std_logic;
  signal constant7_outs_ready : std_logic;
  signal buffer5_outs : std_logic_vector(0 downto 0);
  signal buffer5_outs_valid : std_logic;
  signal buffer5_outs_ready : std_logic;
  signal mux1_outs : std_logic_vector(31 downto 0);
  signal mux1_outs_valid : std_logic;
  signal mux1_outs_ready : std_logic;
  signal buffer2_outs : std_logic_vector(31 downto 0);
  signal buffer2_outs_valid : std_logic;
  signal buffer2_outs_ready : std_logic;
  signal fork2_outs_0 : std_logic_vector(31 downto 0);
  signal fork2_outs_0_valid : std_logic;
  signal fork2_outs_0_ready : std_logic;
  signal fork2_outs_1 : std_logic_vector(31 downto 0);
  signal fork2_outs_1_valid : std_logic;
  signal fork2_outs_1_ready : std_logic;
  signal control_merge0_outs_valid : std_logic;
  signal control_merge0_outs_ready : std_logic;
  signal control_merge0_index : std_logic_vector(0 downto 0);
  signal control_merge0_index_valid : std_logic;
  signal control_merge0_index_ready : std_logic;
  signal fork3_outs_0 : std_logic_vector(0 downto 0);
  signal fork3_outs_0_valid : std_logic;
  signal fork3_outs_0_ready : std_logic;
  signal fork3_outs_1 : std_logic_vector(0 downto 0);
  signal fork3_outs_1_valid : std_logic;
  signal fork3_outs_1_ready : std_logic;
  signal source0_outs_valid : std_logic;
  signal source0_outs_ready : std_logic;
  signal source1_outs_valid : std_logic;
  signal source1_outs_ready : std_logic;
  signal source2_outs_valid : std_logic;
  signal source2_outs_ready : std_logic;
  signal constant4_outs : std_logic_vector(31 downto 0);
  signal constant4_outs_valid : std_logic;
  signal constant4_outs_ready : std_logic;
  signal load0_addrOut : std_logic_vector(5 downto 0);
  signal load0_addrOut_valid : std_logic;
  signal load0_addrOut_ready : std_logic;
  signal load0_dataOut : std_logic_vector(31 downto 0);
  signal load0_dataOut_valid : std_logic;
  signal load0_dataOut_ready : std_logic;
  signal fork4_outs_0 : std_logic_vector(31 downto 0);
  signal fork4_outs_0_valid : std_logic;
  signal fork4_outs_0_ready : std_logic;
  signal fork4_outs_1 : std_logic_vector(31 downto 0);
  signal fork4_outs_1_valid : std_logic;
  signal fork4_outs_1_ready : std_logic;
  signal fork4_outs_2 : std_logic_vector(31 downto 0);
  signal fork4_outs_2_valid : std_logic;
  signal fork4_outs_2_ready : std_logic;
  signal cmpi0_result : std_logic_vector(0 downto 0);
  signal cmpi0_result_valid : std_logic;
  signal cmpi0_result_ready : std_logic;
  signal muli0_result : std_logic_vector(31 downto 0);
  signal muli0_result_valid : std_logic;
  signal muli0_result_ready : std_logic;
  signal buffer3_outs : std_logic_vector(31 downto 0);
  signal buffer3_outs_valid : std_logic;
  signal buffer3_outs_ready : std_logic;
  signal buffer6_outs : std_logic_vector(31 downto 0);
  signal buffer6_outs_valid : std_logic;
  signal buffer6_outs_ready : std_logic;
  signal addi0_result : std_logic_vector(31 downto 0);
  signal addi0_result_valid : std_logic;
  signal addi0_result_ready : std_logic;
  signal buffer7_outs : std_logic_vector(0 downto 0);
  signal buffer7_outs_valid : std_logic;
  signal buffer7_outs_ready : std_logic;
  signal buffer8_outs : std_logic_vector(31 downto 0);
  signal buffer8_outs_valid : std_logic;
  signal buffer8_outs_ready : std_logic;
  signal select0_result : std_logic_vector(31 downto 0);
  signal select0_result_valid : std_logic;
  signal select0_result_ready : std_logic;
  signal addi1_result : std_logic_vector(6 downto 0);
  signal addi1_result_valid : std_logic;
  signal addi1_result_ready : std_logic;
  signal buffer9_outs : std_logic_vector(6 downto 0);
  signal buffer9_outs_valid : std_logic;
  signal buffer9_outs_ready : std_logic;
  signal fork5_outs_0 : std_logic_vector(6 downto 0);
  signal fork5_outs_0_valid : std_logic;
  signal fork5_outs_0_ready : std_logic;
  signal fork5_outs_1 : std_logic_vector(6 downto 0);
  signal fork5_outs_1_valid : std_logic;
  signal fork5_outs_1_ready : std_logic;
  signal trunci1_outs : std_logic_vector(5 downto 0);
  signal trunci1_outs_valid : std_logic;
  signal trunci1_outs_ready : std_logic;
  signal constant8_outs : std_logic_vector(6 downto 0);
  signal constant8_outs_valid : std_logic;
  signal constant8_outs_ready : std_logic;
  signal cmpi1_result : std_logic_vector(0 downto 0);
  signal cmpi1_result_valid : std_logic;
  signal cmpi1_result_ready : std_logic;
  signal fork6_outs_0 : std_logic_vector(0 downto 0);
  signal fork6_outs_0_valid : std_logic;
  signal fork6_outs_0_ready : std_logic;
  signal fork6_outs_1 : std_logic_vector(0 downto 0);
  signal fork6_outs_1_valid : std_logic;
  signal fork6_outs_1_ready : std_logic;
  signal fork6_outs_2 : std_logic_vector(0 downto 0);
  signal fork6_outs_2_valid : std_logic;
  signal fork6_outs_2_ready : std_logic;
  signal cond_br0_trueOut : std_logic_vector(5 downto 0);
  signal cond_br0_trueOut_valid : std_logic;
  signal cond_br0_trueOut_ready : std_logic;
  signal cond_br0_falseOut : std_logic_vector(5 downto 0);
  signal cond_br0_falseOut_valid : std_logic;
  signal cond_br0_falseOut_ready : std_logic;
  signal buffer10_outs : std_logic_vector(0 downto 0);
  signal buffer10_outs_valid : std_logic;
  signal buffer10_outs_ready : std_logic;
  signal cond_br1_trueOut : std_logic_vector(31 downto 0);
  signal cond_br1_trueOut_valid : std_logic;
  signal cond_br1_trueOut_ready : std_logic;
  signal cond_br1_falseOut : std_logic_vector(31 downto 0);
  signal cond_br1_falseOut_valid : std_logic;
  signal cond_br1_falseOut_ready : std_logic;
  signal buffer4_outs_valid : std_logic;
  signal buffer4_outs_ready : std_logic;
  signal cond_br2_trueOut_valid : std_logic;
  signal cond_br2_trueOut_ready : std_logic;
  signal cond_br2_falseOut_valid : std_logic;
  signal cond_br2_falseOut_ready : std_logic;

begin

  out0 <= cond_br1_falseOut;
  out0_valid <= cond_br1_falseOut_valid;
  cond_br1_falseOut_ready <= out0_ready;
  x_end_valid <= mem_controller1_memEnd_valid;
  mem_controller1_memEnd_ready <= x_end_ready;
  end_valid <= fork0_outs_2_valid;
  fork0_outs_2_ready <= end_ready;
  x_loadEn <= mem_controller1_loadEn;
  x_loadAddr <= mem_controller1_loadAddr;
  x_storeEn <= mem_controller1_storeEn;
  x_storeAddr <= mem_controller1_storeAddr;
  x_storeData <= mem_controller1_storeData;

  fork0 : entity work.handshake_fork_0(arch)
    port map(
      ins_valid => start_valid,
      ins_ready => start_ready,
      clk => clk,
      rst => rst,
      outs_valid(0) => fork0_outs_0_valid,
      outs_valid(1) => fork0_outs_1_valid,
      outs_valid(2) => fork0_outs_2_valid,
      outs_valid(3) => fork0_outs_3_valid,
      outs_ready(0) => fork0_outs_0_ready,
      outs_ready(1) => fork0_outs_1_ready,
      outs_ready(2) => fork0_outs_2_ready,
      outs_ready(3) => fork0_outs_3_ready
    );

  mem_controller1 : entity work.handshake_mem_controller_0(arch)
    port map(
      loadData => x_loadData,
      memStart_valid => x_start_valid,
      memStart_ready => x_start_ready,
      ldAddr(0) => load0_addrOut,
      ldAddr_valid(0) => load0_addrOut_valid,
      ldAddr_ready(0) => load0_addrOut_ready,
      ctrlEnd_valid => cond_br2_falseOut_valid,
      ctrlEnd_ready => cond_br2_falseOut_ready,
      clk => clk,
      rst => rst,
      ldData(0) => mem_controller1_ldData_0,
      ldData_valid(0) => mem_controller1_ldData_0_valid,
      ldData_ready(0) => mem_controller1_ldData_0_ready,
      memEnd_valid => mem_controller1_memEnd_valid,
      memEnd_ready => mem_controller1_memEnd_ready,
      loadEn => mem_controller1_loadEn,
      loadAddr => mem_controller1_loadAddr,
      storeEn => mem_controller1_storeEn,
      storeAddr => mem_controller1_storeAddr,
      storeData => mem_controller1_storeData
    );

  constant5 : entity work.handshake_constant_0(arch)
    port map(
      ctrl_valid => fork0_outs_0_valid,
      ctrl_ready => fork0_outs_0_ready,
      clk => clk,
      rst => rst,
      outs => constant5_outs,
      outs_valid => constant5_outs_valid,
      outs_ready => constant5_outs_ready
    );

  extui1 : entity work.handshake_extui_0(arch)
    port map(
      ins => constant5_outs,
      ins_valid => constant5_outs_valid,
      ins_ready => constant5_outs_ready,
      clk => clk,
      rst => rst,
      outs => extui1_outs,
      outs_valid => extui1_outs_valid,
      outs_ready => extui1_outs_ready
    );

  constant6 : entity work.handshake_constant_1(arch)
    port map(
      ctrl_valid => fork0_outs_1_valid,
      ctrl_ready => fork0_outs_1_ready,
      clk => clk,
      rst => rst,
      outs => constant6_outs,
      outs_valid => constant6_outs_valid,
      outs_ready => constant6_outs_ready
    );

  extui2 : entity work.handshake_extui_1(arch)
    port map(
      ins => constant6_outs,
      ins_valid => constant6_outs_valid,
      ins_ready => constant6_outs_ready,
      clk => clk,
      rst => rst,
      outs => extui2_outs,
      outs_valid => extui2_outs_valid,
      outs_ready => extui2_outs_ready
    );

  mux0 : entity work.handshake_mux_0(arch)
    port map(
      index => fork3_outs_0,
      index_valid => fork3_outs_0_valid,
      index_ready => fork3_outs_0_ready,
      ins(0) => extui1_outs,
      ins(1) => cond_br0_trueOut,
      ins_valid(0) => extui1_outs_valid,
      ins_valid(1) => cond_br0_trueOut_valid,
      ins_ready(0) => extui1_outs_ready,
      ins_ready(1) => cond_br0_trueOut_ready,
      clk => clk,
      rst => rst,
      outs => mux0_outs,
      outs_valid => mux0_outs_valid,
      outs_ready => mux0_outs_ready
    );

  buffer0 : entity work.handshake_buffer_0(arch)
    port map(
      ins => mux0_outs,
      ins_valid => mux0_outs_valid,
      ins_ready => mux0_outs_ready,
      clk => clk,
      rst => rst,
      outs => buffer0_outs,
      outs_valid => buffer0_outs_valid,
      outs_ready => buffer0_outs_ready
    );

  buffer1 : entity work.handshake_buffer_1(arch)
    port map(
      ins => buffer0_outs,
      ins_valid => buffer0_outs_valid,
      ins_ready => buffer0_outs_ready,
      clk => clk,
      rst => rst,
      outs => buffer1_outs,
      outs_valid => buffer1_outs_valid,
      outs_ready => buffer1_outs_ready
    );

  fork1 : entity work.handshake_fork_1(arch)
    port map(
      ins => buffer1_outs,
      ins_valid => buffer1_outs_valid,
      ins_ready => buffer1_outs_ready,
      clk => clk,
      rst => rst,
      outs(0) => fork1_outs_0,
      outs(1) => fork1_outs_1,
      outs_valid(0) => fork1_outs_0_valid,
      outs_valid(1) => fork1_outs_1_valid,
      outs_ready(0) => fork1_outs_0_ready,
      outs_ready(1) => fork1_outs_1_ready
    );

  extui3 : entity work.handshake_extui_2(arch)
    port map(
      ins => fork1_outs_1,
      ins_valid => fork1_outs_1_valid,
      ins_ready => fork1_outs_1_ready,
      clk => clk,
      rst => rst,
      outs => extui3_outs,
      outs_valid => extui3_outs_valid,
      outs_ready => extui3_outs_ready
    );

  constant7 : entity work.handshake_constant_2(arch)
    port map(
      ctrl_valid => source1_outs_valid,
      ctrl_ready => source1_outs_ready,
      clk => clk,
      rst => rst,
      outs => constant7_outs,
      outs_valid => constant7_outs_valid,
      outs_ready => constant7_outs_ready
    );

  buffer5 : entity work.handshake_buffer_2(arch)
    port map(
      ins => fork3_outs_1,
      ins_valid => fork3_outs_1_valid,
      ins_ready => fork3_outs_1_ready,
      clk => clk,
      rst => rst,
      outs => buffer5_outs,
      outs_valid => buffer5_outs_valid,
      outs_ready => buffer5_outs_ready
    );

  mux1 : entity work.handshake_mux_1(arch)
    port map(
      index => buffer5_outs,
      index_valid => buffer5_outs_valid,
      index_ready => buffer5_outs_ready,
      ins(0) => extui2_outs,
      ins(1) => cond_br1_trueOut,
      ins_valid(0) => extui2_outs_valid,
      ins_valid(1) => cond_br1_trueOut_valid,
      ins_ready(0) => extui2_outs_ready,
      ins_ready(1) => cond_br1_trueOut_ready,
      clk => clk,
      rst => rst,
      outs => mux1_outs,
      outs_valid => mux1_outs_valid,
      outs_ready => mux1_outs_ready
    );

  buffer2 : entity work.handshake_buffer_3(arch)
    port map(
      ins => mux1_outs,
      ins_valid => mux1_outs_valid,
      ins_ready => mux1_outs_ready,
      clk => clk,
      rst => rst,
      outs => buffer2_outs,
      outs_valid => buffer2_outs_valid,
      outs_ready => buffer2_outs_ready
    );

  fork2 : entity work.handshake_fork_2(arch)
    port map(
      ins => buffer2_outs,
      ins_valid => buffer2_outs_valid,
      ins_ready => buffer2_outs_ready,
      clk => clk,
      rst => rst,
      outs(0) => fork2_outs_0,
      outs(1) => fork2_outs_1,
      outs_valid(0) => fork2_outs_0_valid,
      outs_valid(1) => fork2_outs_1_valid,
      outs_ready(0) => fork2_outs_0_ready,
      outs_ready(1) => fork2_outs_1_ready
    );

  control_merge0 : entity work.handshake_control_merge_0(arch)
    port map(
      ins_valid(0) => fork0_outs_3_valid,
      ins_valid(1) => cond_br2_trueOut_valid,
      ins_ready(0) => fork0_outs_3_ready,
      ins_ready(1) => cond_br2_trueOut_ready,
      clk => clk,
      rst => rst,
      outs_valid => control_merge0_outs_valid,
      outs_ready => control_merge0_outs_ready,
      index => control_merge0_index,
      index_valid => control_merge0_index_valid,
      index_ready => control_merge0_index_ready
    );

  fork3 : entity work.handshake_fork_3(arch)
    port map(
      ins => control_merge0_index,
      ins_valid => control_merge0_index_valid,
      ins_ready => control_merge0_index_ready,
      clk => clk,
      rst => rst,
      outs(0) => fork3_outs_0,
      outs(1) => fork3_outs_1,
      outs_valid(0) => fork3_outs_0_valid,
      outs_valid(1) => fork3_outs_1_valid,
      outs_ready(0) => fork3_outs_0_ready,
      outs_ready(1) => fork3_outs_1_ready
    );

  source0 : entity work.handshake_source_0(arch)
    port map(
      clk => clk,
      rst => rst,
      outs_valid => source0_outs_valid,
      outs_ready => source0_outs_ready
    );

  source1 : entity work.handshake_source_0(arch)
    port map(
      clk => clk,
      rst => rst,
      outs_valid => source1_outs_valid,
      outs_ready => source1_outs_ready
    );

  source2 : entity work.handshake_source_0(arch)
    port map(
      clk => clk,
      rst => rst,
      outs_valid => source2_outs_valid,
      outs_ready => source2_outs_ready
    );

  constant4 : entity work.handshake_constant_3(arch)
    port map(
      ctrl_valid => source2_outs_valid,
      ctrl_ready => source2_outs_ready,
      clk => clk,
      rst => rst,
      outs => constant4_outs,
      outs_valid => constant4_outs_valid,
      outs_ready => constant4_outs_ready
    );

  load0 : entity work.handshake_load_0(arch)
    port map(
      addrIn => fork1_outs_0,
      addrIn_valid => fork1_outs_0_valid,
      addrIn_ready => fork1_outs_0_ready,
      dataFromMem => mem_controller1_ldData_0,
      dataFromMem_valid => mem_controller1_ldData_0_valid,
      dataFromMem_ready => mem_controller1_ldData_0_ready,
      clk => clk,
      rst => rst,
      addrOut => load0_addrOut,
      addrOut_valid => load0_addrOut_valid,
      addrOut_ready => load0_addrOut_ready,
      dataOut => load0_dataOut,
      dataOut_valid => load0_dataOut_valid,
      dataOut_ready => load0_dataOut_ready
    );

  fork4 : entity work.handshake_fork_4(arch)
    port map(
      ins => load0_dataOut,
      ins_valid => load0_dataOut_valid,
      ins_ready => load0_dataOut_ready,
      clk => clk,
      rst => rst,
      outs(0) => fork4_outs_0,
      outs(1) => fork4_outs_1,
      outs(2) => fork4_outs_2,
      outs_valid(0) => fork4_outs_0_valid,
      outs_valid(1) => fork4_outs_1_valid,
      outs_valid(2) => fork4_outs_2_valid,
      outs_ready(0) => fork4_outs_0_ready,
      outs_ready(1) => fork4_outs_1_ready,
      outs_ready(2) => fork4_outs_2_ready
    );

  cmpi0 : entity work.handshake_cmpi_0(arch)
    port map(
      lhs => fork4_outs_0,
      lhs_valid => fork4_outs_0_valid,
      lhs_ready => fork4_outs_0_ready,
      rhs => constant4_outs,
      rhs_valid => constant4_outs_valid,
      rhs_ready => constant4_outs_ready,
      clk => clk,
      rst => rst,
      result => cmpi0_result,
      result_valid => cmpi0_result_valid,
      result_ready => cmpi0_result_ready
    );

  muli0 : entity work.handshake_muli_0(arch)
    port map(
      lhs => fork2_outs_1,
      lhs_valid => fork2_outs_1_valid,
      lhs_ready => fork2_outs_1_ready,
      rhs => fork4_outs_1,
      rhs_valid => fork4_outs_1_valid,
      rhs_ready => fork4_outs_1_ready,
      clk => clk,
      rst => rst,
      result => muli0_result,
      result_valid => muli0_result_valid,
      result_ready => muli0_result_ready
    );

  buffer3 : entity work.handshake_buffer_4(arch)
    port map(
      ins => fork2_outs_0,
      ins_valid => fork2_outs_0_valid,
      ins_ready => fork2_outs_0_ready,
      clk => clk,
      rst => rst,
      outs => buffer3_outs,
      outs_valid => buffer3_outs_valid,
      outs_ready => buffer3_outs_ready
    );

  buffer6 : entity work.handshake_buffer_5(arch)
    port map(
      ins => fork4_outs_2,
      ins_valid => fork4_outs_2_valid,
      ins_ready => fork4_outs_2_ready,
      clk => clk,
      rst => rst,
      outs => buffer6_outs,
      outs_valid => buffer6_outs_valid,
      outs_ready => buffer6_outs_ready
    );

  addi0 : entity work.handshake_addi_0(arch)
    port map(
      lhs => buffer3_outs,
      lhs_valid => buffer3_outs_valid,
      lhs_ready => buffer3_outs_ready,
      rhs => buffer6_outs,
      rhs_valid => buffer6_outs_valid,
      rhs_ready => buffer6_outs_ready,
      clk => clk,
      rst => rst,
      result => addi0_result,
      result_valid => addi0_result_valid,
      result_ready => addi0_result_ready
    );

  buffer7 : entity work.handshake_buffer_2(arch)
    port map(
      ins => cmpi0_result,
      ins_valid => cmpi0_result_valid,
      ins_ready => cmpi0_result_ready,
      clk => clk,
      rst => rst,
      outs => buffer7_outs,
      outs_valid => buffer7_outs_valid,
      outs_ready => buffer7_outs_ready
    );

  buffer8 : entity work.handshake_buffer_4(arch)
    port map(
      ins => addi0_result,
      ins_valid => addi0_result_valid,
      ins_ready => addi0_result_ready,
      clk => clk,
      rst => rst,
      outs => buffer8_outs,
      outs_valid => buffer8_outs_valid,
      outs_ready => buffer8_outs_ready
    );

  select0 : entity work.handshake_select_0(arch)
    port map(
      condition => buffer7_outs,
      condition_valid => buffer7_outs_valid,
      condition_ready => buffer7_outs_ready,
      trueValue => muli0_result,
      trueValue_valid => muli0_result_valid,
      trueValue_ready => muli0_result_ready,
      falseValue => buffer8_outs,
      falseValue_valid => buffer8_outs_valid,
      falseValue_ready => buffer8_outs_ready,
      clk => clk,
      rst => rst,
      result => select0_result,
      result_valid => select0_result_valid,
      result_ready => select0_result_ready
    );

  addi1 : entity work.handshake_addi_1(arch)
    port map(
      lhs => extui3_outs,
      lhs_valid => extui3_outs_valid,
      lhs_ready => extui3_outs_ready,
      rhs => constant7_outs,
      rhs_valid => constant7_outs_valid,
      rhs_ready => constant7_outs_ready,
      clk => clk,
      rst => rst,
      result => addi1_result,
      result_valid => addi1_result_valid,
      result_ready => addi1_result_ready
    );

  buffer9 : entity work.handshake_buffer_6(arch)
    port map(
      ins => addi1_result,
      ins_valid => addi1_result_valid,
      ins_ready => addi1_result_ready,
      clk => clk,
      rst => rst,
      outs => buffer9_outs,
      outs_valid => buffer9_outs_valid,
      outs_ready => buffer9_outs_ready
    );

  fork5 : entity work.handshake_fork_5(arch)
    port map(
      ins => buffer9_outs,
      ins_valid => buffer9_outs_valid,
      ins_ready => buffer9_outs_ready,
      clk => clk,
      rst => rst,
      outs(0) => fork5_outs_0,
      outs(1) => fork5_outs_1,
      outs_valid(0) => fork5_outs_0_valid,
      outs_valid(1) => fork5_outs_1_valid,
      outs_ready(0) => fork5_outs_0_ready,
      outs_ready(1) => fork5_outs_1_ready
    );

  trunci1 : entity work.handshake_trunci_0(arch)
    port map(
      ins => fork5_outs_0,
      ins_valid => fork5_outs_0_valid,
      ins_ready => fork5_outs_0_ready,
      clk => clk,
      rst => rst,
      outs => trunci1_outs,
      outs_valid => trunci1_outs_valid,
      outs_ready => trunci1_outs_ready
    );

  constant8 : entity work.handshake_constant_4(arch)
    port map(
      ctrl_valid => source0_outs_valid,
      ctrl_ready => source0_outs_ready,
      clk => clk,
      rst => rst,
      outs => constant8_outs,
      outs_valid => constant8_outs_valid,
      outs_ready => constant8_outs_ready
    );

  cmpi1 : entity work.handshake_cmpi_1(arch)
    port map(
      lhs => fork5_outs_1,
      lhs_valid => fork5_outs_1_valid,
      lhs_ready => fork5_outs_1_ready,
      rhs => constant8_outs,
      rhs_valid => constant8_outs_valid,
      rhs_ready => constant8_outs_ready,
      clk => clk,
      rst => rst,
      result => cmpi1_result,
      result_valid => cmpi1_result_valid,
      result_ready => cmpi1_result_ready
    );

  fork6 : entity work.handshake_fork_6(arch)
    port map(
      ins => cmpi1_result,
      ins_valid => cmpi1_result_valid,
      ins_ready => cmpi1_result_ready,
      clk => clk,
      rst => rst,
      outs(0) => fork6_outs_0,
      outs(1) => fork6_outs_1,
      outs(2) => fork6_outs_2,
      outs_valid(0) => fork6_outs_0_valid,
      outs_valid(1) => fork6_outs_1_valid,
      outs_valid(2) => fork6_outs_2_valid,
      outs_ready(0) => fork6_outs_0_ready,
      outs_ready(1) => fork6_outs_1_ready,
      outs_ready(2) => fork6_outs_2_ready
    );

  cond_br0 : entity work.handshake_cond_br_0(arch)
    port map(
      condition => fork6_outs_0,
      condition_valid => fork6_outs_0_valid,
      condition_ready => fork6_outs_0_ready,
      data => trunci1_outs,
      data_valid => trunci1_outs_valid,
      data_ready => trunci1_outs_ready,
      clk => clk,
      rst => rst,
      trueOut => cond_br0_trueOut,
      trueOut_valid => cond_br0_trueOut_valid,
      trueOut_ready => cond_br0_trueOut_ready,
      falseOut => cond_br0_falseOut,
      falseOut_valid => cond_br0_falseOut_valid,
      falseOut_ready => cond_br0_falseOut_ready
    );

  sink0 : entity work.handshake_sink_0(arch)
    port map(
      ins => cond_br0_falseOut,
      ins_valid => cond_br0_falseOut_valid,
      ins_ready => cond_br0_falseOut_ready,
      clk => clk,
      rst => rst
    );

  buffer10 : entity work.handshake_buffer_7(arch)
    port map(
      ins => fork6_outs_1,
      ins_valid => fork6_outs_1_valid,
      ins_ready => fork6_outs_1_ready,
      clk => clk,
      rst => rst,
      outs => buffer10_outs,
      outs_valid => buffer10_outs_valid,
      outs_ready => buffer10_outs_ready
    );

  cond_br1 : entity work.handshake_cond_br_1(arch)
    port map(
      condition => buffer10_outs,
      condition_valid => buffer10_outs_valid,
      condition_ready => buffer10_outs_ready,
      data => select0_result,
      data_valid => select0_result_valid,
      data_ready => select0_result_ready,
      clk => clk,
      rst => rst,
      trueOut => cond_br1_trueOut,
      trueOut_valid => cond_br1_trueOut_valid,
      trueOut_ready => cond_br1_trueOut_ready,
      falseOut => cond_br1_falseOut,
      falseOut_valid => cond_br1_falseOut_valid,
      falseOut_ready => cond_br1_falseOut_ready
    );

  buffer4 : entity work.handshake_buffer_8(arch)
    port map(
      ins_valid => control_merge0_outs_valid,
      ins_ready => control_merge0_outs_ready,
      clk => clk,
      rst => rst,
      outs_valid => buffer4_outs_valid,
      outs_ready => buffer4_outs_ready
    );

  cond_br2 : entity work.handshake_cond_br_2(arch)
    port map(
      condition => fork6_outs_2,
      condition_valid => fork6_outs_2_valid,
      condition_ready => fork6_outs_2_ready,
      data_valid => buffer4_outs_valid,
      data_ready => buffer4_outs_ready,
      clk => clk,
      rst => rst,
      trueOut_valid => cond_br2_trueOut_valid,
      trueOut_ready => cond_br2_trueOut_ready,
      falseOut_valid => cond_br2_falseOut_valid,
      falseOut_ready => cond_br2_falseOut_ready
    );

end architecture;
