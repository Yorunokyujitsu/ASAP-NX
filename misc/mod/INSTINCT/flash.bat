@BootloaderUpdater.exe bootloader.bin
@echo Waiting 3s!!!
@%WINDIR%\System32\timeout.exe /t 3 /nobreak > NUL
@FirmwareUpdater.exe firmware.bin
@echo !!!DONE!!!
@pause