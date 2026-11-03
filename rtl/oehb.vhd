library ieee;
use ieee.std_logic_1164.all;

-- Opaque elastic half buffer: one slot. Outputs come straight from
-- registers (cuts the valid/data path); ready passes through.
entity oehb is
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

architecture rtl of oehb is
  signal valid_r : std_logic;
  signal data_r  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal ready_i : std_logic;
begin
  -- Room for a new token: empty, or the current token leaves this cycle.
  ready_i <= (not valid_r) or outs_ready;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        valid_r <= '0';
      elsif ready_i = '1' then
        valid_r <= ins_valid;
        if ins_valid = '1' then
          data_r <= ins;
        end if;
      end if;
    end if;
  end process;

  ins_ready  <= ready_i;
  outs       <= data_r;
  outs_valid <= valid_r;
end architecture;
