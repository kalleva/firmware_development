# Tools you need to install:

1. [VSCode](https://code.visualstudio.com/)
2. Several VSCode extensions:
    - [C/C++](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools) - Intellisense
    - [Cortex-Debug](https://marketplace.visualstudio.com/items?itemName=marus25.cortex-debug) - Debugging
    - [ARM](https://marketplace.visualstudio.com/items?itemName=dan-c-underwood.arm) - Coloring for assembler files
    - [Intel HEX format](https://marketplace.visualstudio.com/items?itemName=keroc.hex-fmt) - Coloring and checksum checking for .hex files
    - [Binary Viewer](https://marketplace.visualstudio.com/items?itemName=qiaojie.binary-viewer)
    - [LinkerScript](https://marketplace.visualstudio.com/items?itemName=ZixuanWang.linkerscript) - Coloring for linker files
3. [GNU Arm Embedded Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) - Compiler
4. [MinGW](https://sourceforge.net/projects/mingw/) - For mingw32-make.exe
5. [OpenOCD](https://github.com/xpack-dev-tools/openocd-xpack/releases) - Debugging
6. [Termite](https://www.compuphase.com/software_termite.htm#:~:text=Termite%20is%20an%20easy%20to,typing%20in%20strings%20to%20transmit.) - UART Terminal
7. [STM32CubeProgrammer](https://www.st.com/en/development-tools/stm32cubeprog.html) Installs all drivers you need to communicate with STM MC.
8. [STM32CubeMX](https://www.st.com/en/development-tools/stm32cubemx.html) Helps you initialise your STM Project


# Build

STM32CubeMX allows you to initialize your project and on the page "Project Manager" > "Toolchain/IDE" you need to choose Makefile. This will generate makefile for you project. It will contain DEBUG configuration of a project.
To create RELEASE I usually modify Makefile, I pass ```DEBUG``` to the build command and configure Makefile to work based on this:
1. Selects build optimisation. Og - for debug, Os - for firmware size
```
ifeq ($(DEBUG), 1)
OPT = -Og
endif
ifeq ($(DEBUG), 0)
OPT = -Os
endif
```
2. Default clean section of Makefile doesn't work on Windows I change it to:
```
clean:
	del /f /q $(BUILD_DIR)
```


# Load firmware to device

This depends on the additional hardware available to you.

## Flashing via UART
If you have UART-USB you need to switch device into bootloader mode by connecting BOOT0 pin to VDD and performing Reset.
After that you can flash firmware via UART with STM32CubeProgrammer GUI or with cmd (if you added STM32CubeProgrammer installation folder to the EnvironmentVariables > Path).
```stm32_programmer_cli.exe -c port=com7 -d "firmware.hex" -v``` 

## Flashing via SWD
If you have stlink.
```STM32_Programmer_CLI.exe -c port=SWD reset=HWrst -d ./build/firmware.hex -v -hardRst```

If you have NUCLEO lying around you can use its ST-Link on CN11 SWD connector.
1. You need to switch CN4 jumpers OFF to configure board to use ST-Link.
2. CN11 header pinout:
    1. VDD_TARGET - VDD from the application
    2. SWCLK - SWD clock
    3. GND - Ground
    4. SWDIO - SWD data input/output
    5. NRST - RESET of target MCU
    6. SWO - Reserved

# Debug
You need to configure Cortex-Debug extension in global settings.json
```
    "cortex-debug.armToolchainPath": "C:/Program Files (x86)/GNU Arm Embedded Toolchain/10 2021.10/bin/",
    "cortex-debug.enableTelemetry": false,
    "cortex-debug.openocdPath": "C:/OpenOCD_0110-04/bin/openocd.exe",
    "cortex-debug.stm32cubeprogrammer": "C:/Program Files/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin/STM32CubeProgrammer.exe"
```

Create launch.json in .vscode folder.
Add configuration that is specific to your board:
```
        {
            "name": "cortex-debug",
            "cwd": "${workspaceRoot}",
            "executable": "build/${workspaceFolderBasename}.elf",
            "request": "launch",
            "type": "cortex-debug",
            "servertype": "openocd",
            "svdFile": "STM32L0x1.svd",
            "configFiles": ["stm32_l071cbt6.cfg"],
            "preLaunchTask": "build debug"
        }
```
I usually place .svd and .cfg files in root of the project.
You can find .svd file at MC page on STM site under CAD Resourses menu.
The easiest way to create tailored to your MCU .cfg file is to create STM32CubeIDE project for the same MCU and configure OpenOCD debug configuration and just copy it to your project.
Example of working .cfg file for STM32L072CT6:
```
source [find interface/stlink-dap.cfg]


set WORKAREASIZE 0x1000

transport select "dapdirect_swd"

set CHIPNAME STM32L072CZTx
set BOARDNAME genericBoard

# Enable debug when in low power modes
set ENABLE_LOW_POWER 1

# Stop Watchdog counters when halt
set STOP_WATCHDOG 1

# STlink Debug clock frequency
set CLOCK_FREQ 8000

# Reset configuration
# use hardware reset, connect under reset
# connect_assert_srst needed if low power mode application running (WFI...)
reset_config none
set CONNECT_UNDER_RESET 0
set CORE_RESET 0

# ACCESS PORT NUMBER
set AP_NUM 0
# GDB PORT
set GDB_PORT 5000



# BCTM CPU variables

source [find target/stm32l0.cfg] ```


# Build process

I create ```Debug``` and ```Release``` folders inside root of the project. 
All build are done via .bat file from the ```scripts``` folder.