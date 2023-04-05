@echo off
  setlocal
  set alias=Reg query "HKLM\Software\Microsoft\NET Framework Setup\NDP"
  FOR /F "TOKENS=6 DELIMS=\." %%A IN ('%alias%') DO set .NetVer=%%A
  ECHO The most current version of Net in use is %.NetVer%