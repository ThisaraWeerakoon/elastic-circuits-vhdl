library ieee;
use ieee.std_logic_1164.all;

-- Transparent elastic half buffer: one spare slot, used only under
-- backpressure. ins_ready comes from a register (cuts the ready path).
entity tehb is
  generic (
    DATA_WIDTH : natural := 32
  );
  port (
    clk, rst   : in  std_logic;
    ins        : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    ins_valid  : in  std_logic;
    ins_ready  : out std_logic;
    outs       : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    outs_valid : out std_logic;
    outs_ready : in  std_logic
  );
end entity;

architecture rtl of tehb is
  signal full_r : std_logic;
  signal data_r : std_logic_vector(DATA_WIDTH - 1 downto 0);
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        full_r <= '0';
      else
        -- Become (or stay) full when a token is present but can't leave.
        full_r <= (full_r or ins_valid) and not outs_ready;
      end if;
      if full_r = '0' then
        data_r <= ins;               -- keep a copy of whatever passes by
      end if;
    end if;
  end process;

  ins_ready  <= not full_r;
  outs_valid <= ins_valid or full_r;
  outs       <= data_r when full_r = '1' else ins;
end architecture;
