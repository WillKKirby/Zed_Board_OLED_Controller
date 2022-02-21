# Zed_Board_OLED_Controller (WIP)

This project IP allows the OLED Display on the Zedboard to be utilised.

The IP is used in conjuntion with the ZYNQ7 processing system. It takes inputs from the ZYNQ7 through an AXI interface, 
then the Controller uses an SPI interface to interact with the display routing the output to the Zedboard pins. 

On boot, the system will run through a FSM to initalise the display the display before use. 
The controller wont accept any data before the initalise is complete.
Once the inital setup is complete, it will take data to the display through the AXI interface.
The controller uses flags through the AXI interface to signal when the data sent, has been written. 
