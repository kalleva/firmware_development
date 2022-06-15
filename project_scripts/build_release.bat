@ECHO OFF
CD ..
mingw32-make.exe clean
mingw32-make.exe -j 6 DEBUG=0

FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --abbrev-ref HEAD`) DO (
SET branch=%%F
)

FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse HEAD`) DO (
SET commit=%%F
)

FOR %%I IN (.) DO SET current_directory=%%~nxI

copy .\build\%current_directory%.hex .\Release\%current_directory%_%branch%_%commit%_release.hex