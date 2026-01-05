@echo off
if exist rawnand.bin del rawnand.bin
copy /b rawnand.bin.* rawnand.bin
echo Merge complete: rawnand.bin