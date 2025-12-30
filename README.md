# AGS to MiSTer
Builds HD image(s) of AGS 3.0 to be used on MiSTer.
Wanted to build most complete version of AGS even with content that might not work on MiSTer currently.

Patches add to AGS:
- RTG modes for cool display 
- SHARE for game saves
- TBD: Toccata 16bit AHI sound card support 

## How to use
1. Clone this repository or download and extract [zip](https://github.com/gljubojevic/AGStoMiSTer/archive/refs/heads/main.zip)
2. Download and extract AGS UAE 3.0 from https://www.amigagameselector.co.uk/
3. Open powershell and start `AGS30toMiSTer.ps1`
4. Copy A1200 kickstart as `KICK.ROM` to `build/games/AmigaGameSelector30`
5. Copy content of `build` folder to MiSTer SD card

When you copy content of build folder you should have "Amiga Game Selector 3.0" inside "Computer" menu.  
Run it and enjoy!

Note: It takes a long time to build HDD images it is recommended to use SSD disk.

## Project structure
- [AmigaFiles](./AmigaFiles/) (Files for patching AGS)
- [build](./build/) (Files to copy on MiSTer SD card, HDD files are built here)
- [Functions](./Functions/) (Collection of powershell functions for building image)
- [Tools](./Tools/) (Tools like HST-Imager are downloaded here)

## References
- https://www.amigagameselector.co.uk/
- Inspiration and some borrowed code from https://github.com/mja65/Emu68-Imager-Software
- Cool tool to build Amiga HDF https://github.com/henrikstengaard/hst-imager
