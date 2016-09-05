@echo off
echo Creating a list of all dumped graphs
cd %VIRTUOSO_HOME%\dumps
setlocal enableDelayedExpansion
echo Graphs > ..\graphlist.txt
for %%x in (*.graph) do (
	copy /b ..\graphlist.txt + %%x ..\graphlist.txt > nul
	set "tekst=|%%x"
	echo !%tekst! >> ..\graphlist.txt
)
pause
