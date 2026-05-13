![banner](misc/res/repo/banner.png?raw=true)

## ASAP-NX

**Personalized custom all-in-one package creation tool.**
* **[ASAP](https://raw.githubusercontent.com/Yorunokyujitsu/ASAP-NX/main/output/ASAP.zip)** - Korean-only Aio package for personal use.
* **[ASAP-Installer](https://raw.githubusercontent.com/Yorunokyujitsu/ASAP-NX/main/output/tools/ASAP_Installer.zip)** - One-click easy CFW installer.
* **[IMG2BMP](https://raw.githubusercontent.com/Yorunokyujitsu/ASAP-NX/main/output/tools/BMP_Converter.zip)** - BMP image converter for Hekate.
<br>

> [!IMPORTANT]
> This project was forked from **[Asa's Switch All-in-one Package](https://github.com/Asadayot/archive_aio)**.<br>
> Repository is maintained **solely for personal use**.<br>
> As it is not intended for distribution, feature requests and issue reports are not accepted.<br>
> No responsibility is assumed for any issues arising from use that disregards these conditions.

<br>

## Snapshots
<p align="center">
  <img src="misc/res/repo/snapshot_01.png?raw=true" width="48%" />
  <img src="misc/res/repo/snapshot_02.png?raw=true" width="48%" />
</p>
<p align="center">
  <img src="misc/res/repo/snapshot_03.png?raw=true" width="48%" />
  <img src="misc/res/repo/snapshot_04.png?raw=true" width="48%" />
</p>
<br>

## Build
**ASAP is built in a CI environment using GitHub Actions**.<br>
The build runs on an ubuntu-latest runner and executes bash-based build scripts to compile the project.<br>
During the process, required tools are automatically set up and the outputs are packaged.<br>
Final build artifacts and logs are uploaded as GitHub Actions Artifacts.<br><br>

**A custom all-in-one package can be configured for personal use.**
> [!TIP]
> Modify the [REPOS](https://github.com/Yorunokyujitsu/ASAP-NX/blob/main/misc/scripts/repos.sh#L55) entries to match the desired setup.<br>
> Adjust [package_origin](https://github.com/Yorunokyujitsu/ASAP-NX/blob/main/misc/scripts/package.sh#L313) to collect build outputs from the customized repos.<br>
> In the [Actions tab](https://github.com/Yorunokyujitsu/ASAP-NX/actions/workflows/build.yml), set only `Main Build` to true, then run `Run workflow`.

<br>

## Credits
**The authors of the excellent projects included in this all-in-one package.**<br>
> **Asadayot** - Upstream [ASAP](https://github.com/Asadayot/archive_aio) build tools.<br>
> **CTCaer** - Custom [bootloader and GUI](https://github.com/CTCaer/hekate).<br>
> **Atmosphere-NX** - [Custom firmware](https://github.com/Atmosphere-NX/Atmosphere) for Nintendo Switch.<br>
> **switchbrew** - [Loader](https://github.com/switchbrew/nx-hbloader) for running homebrew applications.<br>
> **ITotalJustice** - [Homebrew menu](https://github.com/ITotalJustice/sphaira) for Atmosphère.<br>
> **suchmememanyskill** - Payload-based [file manager](https://github.com/suchmememanyskill/TegraExplorer).<br>
> **shchmue** - Device encryption keys dumper.<br>
> **hwfly-nx**, **sthetix** and **rehius** - Arduino flashing management toolboxes.<br>
> **ndeadly** - System module that supports for [third-party Bluetooth controllers](https://github.com/ndeadly/MissionControl).<br>
> **o0Zz** - System module that supports for [third-party USB controllers](https://github.com/o0Zz/sys-con).<br>
> **Zathawo** - System module to control the [fan curve](https://github.com/Zathawo/NX-FanControl).<br>
> **proferabg** - System module for [managing user cheats](https://github.com/proferabg/EdiZon-Overlay).<br>
> **masagrator** - Tools and a [supporting module](https://github.com/masagrator/SaltyNX) for [FPS customization](https://github.com/masagrator/FPSLocker) and [mode switching](https://github.com/masagrator/ReverseNX-RT).<br>
> **Horizon-OC** - Clock-patched [loader.kip and sys-clk](https://github.com/Horizon-OC/Horizon-OC).<br>
> **ppkantorski** - [Overlay menu](https://github.com/ppkantorski/Ultrahand-Overlay), [loader](https://github.com/ppkantorski/nx-ovlloader), and various forked apps [[1]](https://github.com/ppkantorski/nx-ovlreloader), [[2]](https://github.com/ppkantorski/ovl-sysmodules), [[3]](https://github.com/ppkantorski/Status-Monitor-Overlay), [[4]](https://github.com/ppkantorski/FPSLocker).<br>
> **XorTroll** and **yusufakg** - [Homebrew](https://github.com/yusufakg/AmiiboGenerator) and [system module](https://github.com/XorTroll/emuiibo) for managing virtual amiibo.<br>
> **rdmrocha**, **impeeza** - Tool for managing NNID linking and unlinking.<br>
> **duckbill**, **Morce3232** and **rashevskyv** - DBI and [translation patch tools](https://github.com/rashevskyv/DBIPatcher).<br>
> **HamletDuFromage** - Homebrew for [updating CFW, Cheats, L4T, and Firmware](https://github.com/HamletDuFromage/aio-switch-updater).<br>
> **Google Fonts** - [NotoSans KR](https://fonts.google.com/noto/specimen/Noto+Sans+KR), [Cascadia Mono](https://fonts.google.com/specimen/Cascadia+Mono).
