# realterrain v.0.0.7
A Minetest mod that brings real world Terrain into the game (using freely available DEM tiles). Any image can actually be used.

use any image any bit-depth (suggested to convert to greyscale first):

![screenshot_126233205](https://cloud.githubusercontent.com/assets/12679496/8270171/b98d0144-178e-11e5-9a21-ddea2624fdb6.png)

Supplied heightmap and landcover files:

![dem](https://cloud.githubusercontent.com/assets/12679496/10683910/00078544-78fc-11e5-9806-1c0786b3fa4e.png)
![biomes](https://cloud.githubusercontent.com/assets/12679496/10683908/fffbac4c-78fb-11e5-8190-4f0c0561b4b1.png)

Rock strata:

![screenshot_20151022_202823](https://cloud.githubusercontent.com/assets/12679496/10683866/771561ac-78fb-11e5-8fb4-6e9d876fcc67.png)

Settings tool (Realterrain Remote)

![screenshot_20151111_171901](https://cloud.githubusercontent.com/assets/12679496/11108071/9a0804ec-8898-11e5-8341-ad211e94f6fc.png)

Biomes tool:

![screenshot_20151031_093508](https://cloud.githubusercontent.com/assets/12679496/10864655/bf992306-7fb2-11e5-80b8-236d0440f72b.png)

Trees and shrubs:

![screenshot_20151025_140009](https://cloud.githubusercontent.com/assets/12679496/10717817/c79e4608-7b20-11e5-97e5-63c6116f480a.png)

Slope analysis:

![screenshot_20151031_115437](https://cloud.githubusercontent.com/assets/12679496/10865362/512e2128-7fc6-11e5-9c40-e214fa738e40.png)

Aspect analysis:

![screenshot_20151031_114215](https://cloud.githubusercontent.com/assets/12679496/10865364/58dbd988-7fc6-11e5-8a7e-75abc31f378d.png)

3D Euclidean Distance analysis (based on input raster):

![screenshot_20151124_201516](https://cloud.githubusercontent.com/assets/12679496/11388193/31d764d0-92e8-11e5-8c92-d34ff733dc56.png)

### Dependencies:
- You must have imageMagick and MagickWand , OR imlib2 (8-bit limit) installed on your system
- Mod security disabled
-optional dependencies include lunatic-python, python, graphicsmagick (experimental, commented-out-features)

### Instructions
- install the dependencies and the mod as usual (luarocks can be activated if needed)
- launch the game with mod enabled, default settings should work
- use the Realterrain Remote to change the settings, or
- edit the mod defaults section (better to use the remote)
- create greyscale images for heightmap and biomes (only heightmap is required) these should be the same length and width.
The Biomes layer uses USGS landcover classifications and collapses tier two or three to tier one,
which means that values from 10-19 are equivalent to 1, 20-29 are equivalent to 2, etc upt to 99.
The biome file is assumed to be 8-bit. pixel values that equate to 1 (or 10-19) will paint as roads, and pixel values that equate to biome 5 () will paint as water.
A color image can be used for elevation and landcover but only the red channel is used.
Read the defaults to see what the other biomes equate to in the USGS system, or redefine them in the in-game biome settings tool.
Using a graphics editor that doesn't do anti-aliasing and preserves exact red channel values is recommended. Also if using the experimental python image handling, greyscale is required.
- OR download DEM and USGS landcover/landuse tiles for same the same extent. Note, for true 16-bit DEMs you must use magick, not imlib2
- after you change settings exit the world and delete the map.sqlite in the world folder
- relaunch the map and enjoy!

### Upgrading:
- delete the realterrain.settings file in the world folder, or just create a new world

### Next steps:

- allow for placement of buildings and other structures via .mts import
- allow DEMs to tile according to standard naming conventions, or explicitly
- allow output of heightmap and land cover to image files
- admin priv for using the settings tool
- add more raster analysis modes
- allow raster symbology to be customized in-game

### Changelog
#### 0.0.7
- performance improvements to distance analysis mode, new default (demo) raster for distance mode ("points.tif")
- refactoring of some code: performance improvements where empty mapchunks are not processed
- bug fixes

#### 0.0.6
- biome cover uses absolute values AND ranges which equate exactly to USGS tier system (makes hand painting easier too)
- small bugfixes and windows compatability
- early stages of integrating python calls for GDAL and GRASS using lunatic-python (commented out - must be built per install)
- added some more raster modes, raster symbology nicer and fills in below steep areas
- experimental code for using imagemagick / graphicsmagick command line interface to reduce dependencies (commented out)
- some improvements to form validation, in-game raster selection doesn't require a restart

#### 0.0.5
- improved raster modes symbology and added "aspect"
- made the biome form fully clickable (image buttons and dropdowns)
- added a static water node
- removed dependency on luarocks
- biome cover image pixel values are used directly, not in brightness ranges (8-bit assumed)

#### 0.0.4
- select layer files in game from a dropdown
- vertical, east, and north offsets
- in-game biome settings
- trees and shrubs in biomes

#### 0.0.3
- switched to luarocks "magick" library
- included a biome painting layer, broke the "cover" layer into roads and water layers
- added the files used to the settings tool
- added strata for under the ground
- in game map reset, kicks all players on reset, deletes map.sqlite file

#### 0.0.2
- switched to lua-imlib2 for support of all filetypes and bit depths
- supports downloaded GeoTIFF DEM tiles
- improved landcover
- added a tool, Realterrain Remote, which allows for:
- in game settings for initial tweaking (still requires deleting map.sqlite in world folder for full refresh of map)
- changed orientation of map to top left corner
- code cleanup, smaller supplied image files, screenshot and description for mod screen

#### 0.0.1
- direct file reading of 8 bit tifs