library ieee;
use ieee.std_logic_1164.all;

-- First-in first-out queue with DEPTH slots. Both valid and ready come
-- from registers, so it cuts both paths.
entity fifo is
  generic (
    DATA_WIDTH : natural  := 32;
    DEPTH      : positive := 2
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

architecture rtl of fifo is
  type mem_t is array (0 to DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal mem   : mem_t;
  signal head  : natural range 0 to DEPTH - 1;   -- next slot to read
  signal tail  : natural range 0 to DEPTH - 1;   -- next slot to write
  signal count : natural range 0 to DEPTH;       -- tokens stored
begin
  ins_ready  <= '1' when count < DEPTH else '0';
  outs_valid <= '1' when count > 0 else '0';
  outs       <= mem(head);

  process (clk)
    variable push, pop : boolean;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        head  <= 0;
        tail  <= 0;
        count <= 0;
      else
        push := ins_valid = '1' and count < DEPTH;
        pop  := outs_ready = '1' and count > 0;
        if push then
          mem(tail) <= ins;
          tail <= (tail + 1) mod DEPTH;
        end if;
        if pop then
          head <= (head + 1) mod DEPTH;
        end if;
        if push and not pop then
          count <= count + 1;
        elsif pop and not push then
          count <= count - 1;
        end if;
      end if;
    end if;
  end process;
end architecture;
