CD ..
mingw32-make.exe clean
mingw32-make.exe -j 6 DEBUG=1

STM32_Programmer_CLI.exe -c port=swd freq=8000 reset=HWrst -d .\build\%current_directory%.hex -v -hardRst