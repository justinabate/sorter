library ieee;
use ieee.std_logic_1164.all;
 
entity sorter_tb is end sorter_tb;
 
architecture behav of sorter_tb is 

    -- tb
    constant C_CLK_PER : time    := 10 ns;
    constant C_RST_LEN : integer := 4; -- cycles
    constant C_DATA_WIDTH : integer := 64;
 
    -- components --------------------------------------------------------
    
    component axi_stream_mst is 
    generic	(
        DATA_WIDTH  : integer := C_DATA_WIDTH);
    port (
        -- ctrl
        clk  : in  std_logic ; --                     
        rst  : in  std_logic ; -- active lo
        stream_trig : in std_logic; -- input  wire
        -- axi stream i/f
        dout : out std_logic_vector (C_DATA_WIDTH  -1 downto 0);
        vld  : out std_logic; -- output wire                     
        sof  : out std_logic; -- output wire                     
        eof  : out std_logic  -- output wire                     
    ); end component;
    
    component sorter is 
    generic	(
        DATA_WIDTH  : integer := C_DATA_WIDTH);
    port (
        -- ctrl inputs
        clk     : in  std_logic;
        rst     : in  std_logic;
        -- AXI stream
        din  : in  std_logic_vector (C_DATA_WIDTH  -1 downto 0);
        vld  : in  std_logic; 
        sof  : in  std_logic; 
        eof  : in  std_logic; 
		-- output ports
        lvl1  : out  std_logic_vector (C_DATA_WIDTH  -1 downto 0);
        lvl2  : out  std_logic_vector (C_DATA_WIDTH  -1 downto 0);
        lvl3  : out  std_logic_vector (C_DATA_WIDTH  -1 downto 0);
        lvl4  : out  std_logic_vector (C_DATA_WIDTH  -1 downto 0);
        done  : out  std_logic 
    ); end component;

    -- signals -----------------------------------------------------------   

    -- ctrl
    signal clk         : std_logic := '1';
    signal rst         : std_logic := '1'; -- active lo
    signal stream_trig : std_logic := '0'; -- active hi
    
    -- axi
    signal data : std_logic_vector (C_DATA_WIDTH -1 downto 0); -- := (others => '0');
    signal vld  : std_logic; -- := '0';
    signal sof  : std_logic; -- := '0';
    signal eof  : std_logic; -- := '0';
    
    -- outputs
    signal lvl1 : std_logic_vector (C_DATA_WIDTH -1 downto 0); -- := (others => '0');
    signal lvl2 : std_logic_vector (C_DATA_WIDTH -1 downto 0); -- := (others => '0');
    signal lvl3 : std_logic_vector (C_DATA_WIDTH -1 downto 0); -- := (others => '0');
    signal lvl4 : std_logic_vector (C_DATA_WIDTH -1 downto 0); -- := (others => '0');
    signal done : std_logic; -- := '0';

    -- procedures --------------------------------------------------------   

    procedure rst_n (signal rst : out std_logic) is begin
        rst <= '0';
            wait for C_CLK_PER*C_RST_LEN;
		rst <= '1';
	end rst_n;

    procedure trigger (signal trig : out std_logic) is begin
        trig <= '1';
            wait for C_CLK_PER*1;
		trig <= '0';
	end trigger;

    -- begin -------------------------------------------------------------   

begin

    -- clock driver ------------------------------------------------------   

    clk <= not clk after C_CLK_PER/2;

    -- axi stream master functional model --------------------------------   

    inst_axi_mst : axi_stream_mst 
    generic map (
        DATA_WIDTH => C_DATA_WIDTH)
    port map (
        -- ctrl inputs
        clk  => clk,  -- i 
        rst  => rst,  -- i; active lo
        stream_trig => stream_trig,
        -- AXI stream        
        dout => data, -- o
        vld  => vld,  -- o    
        sof  => sof,  -- o
        eof  => eof   -- o
    );

    -- sorter: device under test -----------------------------------------   
 
    sorter_dut : sorter
    generic map (
        DATA_WIDTH  => C_DATA_WIDTH)
    port map (
        -- ctrl inputs
        clk => clk,      -- i; 
        rst => rst,      -- i; active lo
        -- AXI stream        
        din  => data, -- i; input wire [DATA_WIDTH-1:0]  TDATA, nominally [63:0]
        vld  => vld,  -- i; TVALID
        sof  => sof,  -- i; TUSER, start of frame
        eof  => eof,  -- i; TLAST, packet boundary
        -- output ports
        lvl1 => lvl1,
        lvl2 => lvl2,
        lvl3 => lvl3,
        lvl4 => lvl4,
        done => done
    ); 

    -- runtime process ---------------------------------------------------   

    proc_run : process begin		
        wait for C_CLK_PER*2;
        rst_n(rst); -- drive active lo reset
        wait for C_CLK_PER*10;
        trigger(stream_trig); -- active hi
        wait for C_CLK_PER*6; -- back to back frames
        trigger(stream_trig); -- active hi
        wait for C_CLK_PER*6; -- back to back frames
        trigger(stream_trig); -- active hi
        wait;
    end process;

end;