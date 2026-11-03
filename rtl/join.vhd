library ieee;
use ieee.std_logic_1164.all;

-- Join: waits until every input has a token, then passes on one
-- combined (dataless) token. Pure combinational logic.
entity join is
  generic (
    SIZE : positive := 2
  );
  port (
    ins_valid  : in  std_logic_vector(SIZE - 1 downto 0);
    ins_ready  : out std_logic_vector(SIZE - 1 downto 0);
    outs_valid : out std_logic;
    outs_ready : in  std_logic
  );
end entity;

architecture rtl of join is
begin
  outs_valid <= and ins_valid;

  process (all)
    variable others_valid : std_logic;
  begin
    for i in 0 to SIZE - 1 loop
      others_valid := '1';
      for j in 0 to SIZE - 1 loop
        if j /= i then
          others_valid := others_valid and ins_valid(j);
        end if;
      end loop;
      ins_ready(i) <= others_valid and outs_ready;
    end loop;
  end process;
end architecture;
