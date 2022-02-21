-- Design Title - OLED_CONTROLLER_IP_v1_0 (ZED Board OLED Controller)
-- Designer - Will Kirby
--
-- Controller for the OLED Display on the ZED board. 
-- The Controller takes inputs through an AXI interface from the ZYNQ PS.
-- The inputs are then processed within the controller, 
--  and are then sent to the OLED display through an SPI interface. 
--
-- This is the top level of the IP, with it holding the interfaces for AXI and SPI, 
--  and also the main control logic block.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OLED_CONTROLLER_IP_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
		-- Users to add ports here
		
		-- Ports for controling the OLED display. 
		-- The Clock for this component should be 5MHz. 
		GCLK      : in  std_logic;
		rst       : in  std_logic;
        OLED_DC   : out std_logic;
        OLED_RES  : out std_logic;
        OLED_SCLK : out std_logic;
        OLED_SDIN : out std_logic;
        OLED_VBAT : out std_logic;
        OLED_VDD  : out std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end OLED_CONTROLLER_IP_v1_0;

architecture arch_imp of OLED_CONTROLLER_IP_v1_0 is
    
    -- Signals/I/Os for from the AXI interface.
    signal READY_FLAG : std_logic;
    signal AXI_DATA : std_logic_vector(7 downto 0);
    signal CLEAR_FLAG : std_logic;
    signal WR_EN_FLAG : std_logic;

    -- Signal from the SPI output interface that is has completed the current data write.
    signal WR_DONE : std_logic;
    
    -- Copies for the OLED signals from the OLED_CONTROLLER_INT, 
    --  to be send to the output interface to be sent out from the component. 
    signal OLED_SDIN_int : std_logic_vector(7 downto 0);
    signal OLED_DC_int, 
           OLED_RES_int, 
           OLED_VBAT_int, 
           OLED_VDD_int : std_logic;
    
    -- Signal for the SPI output interface enable signal.
    signal SPI_en : std_logic;
    
	-- component declaration
	component OLED_CONTROLLER_IP_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 8;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
		
		READY_FLAG : in std_logic;
		AXI_DATA   : out std_logic_vector(7 downto 0);
		CLEAR_FLAG : out std_logic;
		WR_EN_FLAG : out std_logic;
		
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component OLED_CONTROLLER_IP_v1_0_S00_AXI;

begin

-- Instantiation of Axi Bus Interface S00_AXI
OLED_CONTROLLER_IP_v1_0_S00_AXI_inst : OLED_CONTROLLER_IP_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	    
	    READY_FLAG => READY_FLAG,
	    AXI_DATA => AXI_DATA,
	    CLEAR_FLAG => CLEAR_FLAG,
	    WR_EN_FLAG => WR_EN_FLAG,
	
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here
    SPI_Controller : entity work.OLED_CONTROLLER_IP_v1_0_SPI_INT
    port map (
        clk => gclk,
        rst => rst,
        READY_FLAG => READY_FLAG,
        WR_DONE => WR_DONE,
        SPI_en => SPI_en,
        AXI_DATA_in => AXI_DATA,
        WR_EN_FLAG => WR_EN_FLAG,
        OLED_SDIN => OLED_SDIN_int,
        OLED_DC   => OLED_DC,
        OLED_RES  => OLED_RES,
        OLED_VBAT => OLED_VBAT,
        OLED_VDD  => OLED_VDD );
    
    
    SPI_Interface : entity work.OLED_CONTROLLER_IP_v1_0_SPI_INTERFACE
    port map (
        clk => gclk, 
        rst => rst, 
        en  => SPI_en,
        WR_DONE => WR_DONE,
        OLED_SDIN_int => OLED_SDIN_int,
        OLED_SDIN => OLED_SDIN,
        OLED_SCLK => OLED_SCLK );

	-- User logic ends

end arch_imp;
