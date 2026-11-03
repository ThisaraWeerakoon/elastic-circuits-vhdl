library ieee;
use ieee.std_logic_1164.all;

-- Conditional branch: takes one data token and one condition token
-- together, and sends the data to trueOut if the condition is '1',
-- otherwise to falseOut.
entity cond_br is
  generic (
    DATA_WIDTH : natural := 32
  );
  port (
    clk, rst        : in  std_logic;
    condition       : in  std_logic_vector(0 downto 0);
    condition_valid : in  std_logic;
    condition_ready : out std_logic;
    data            : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    data_valid      : in  std_logic;
    data_ready      : out std_logic;
    trueOut         : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    trueOut_valid   : out std_logic;
    trueOut_ready   : in  std_logic;
    falseOut        : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    falseOut_valid  : out std_logic;
    falseOut_ready  : in  std_logic
  );
end entity;

architecture rtl of cond_br is
  signal both_valid   : std_logic;   -- a data token AND a condition token
  signal chosen_ready : std_logic;   -- the selected output can take it
begin
  both_valid   <= data_valid and condition_valid;
  chosen_ready <= trueOut_ready when condition(0) = '1' else falseOut_ready;

  trueOut        <= data;
  falseOut       <= data;
  trueOut_valid  <= both_valid and condition(0);
  falseOut_valid <= both_valid and not condition(0);

  -- Join logic: each input is ready if the other is valid and the
  -- chosen output is ready.
  data_ready      <= condition_valid and chosen_ready;
  condition_ready <= data_valid and chosen_ready;
end architecture;
