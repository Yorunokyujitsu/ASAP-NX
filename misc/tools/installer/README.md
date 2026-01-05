# ASAP INSTALLER
One-Click Easy CFW Installer

## install librarys
```
pip install pyinstaller requests beautifulsoup4 Pillow psutil pywin32 py7zr packaging bs4
```

## build packaging

- **Build Windows Powershell**
```
pyinstaller -F -w -n ASAP --noupx --clean `
    --version-file=./source/scripts/detail_info.py `
    --icon "../../res/icons/installer_256x256.ico" `
    --add-data "./source/scripts/log.py;./source/scripts" `
    --add-data "./source/base64;./source/base64" `
    --add-data "./source/scripts/fat32format.exe;." `
    --add-data "./LICENSE;./" `
    ./main.py
```

- **Build Mingw64, Git bash**
```
pyinstaller -F -w -n ASAP --noupx --clean \
    --version-file=./source/scripts/detail_info.py \
    --icon "./resource/title_icon/icon_256x256.ico" \
    --add-data "./source/scripts/log.py:./source/scripts" \
    --add-data "./source/base64:./source/base64" \
    --add-data "./source/scripts/fat32format.exe:." \
    --add-data "./LICENSE:./" \
    ./main.py
```