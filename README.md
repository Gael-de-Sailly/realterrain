# realterrain v.0.0.9
A Minetest mod that brings real world Terrain into the game (using freely available DEM tiles). Any image can actually be used.

use any image any bit-depth (suggested to convert to greyscale first):

![screenshot_126233205](https://cloud.githubusercontent.com/assets/12679496/8270171/b98d0144-178e-11e5-9a21-ddea2624fdb6.png)

Supplied heightmap and landcover files:

![dem](https://cloud.githubusercontent.com/assets/12679496/10683910/00078544-78fc-11e5-9806-1c0786b3fa4e.png)
![biomes](https://cloud.githubusercontent.com/assets/12679496/10683908/fffbac4c-78fb-11e5-8190-4f0c0561b4b1.png)

Settings tool (Realterrain Remote)

![screenshot_20151201_190737](https://cloud.githubusercontent.com/assets/12679496/11521234/48a2749e-985f-11e5-9d22-9ee3b33c529c.png)

Biomes tool:

![screenshot_20151128_181814](https://cloud.githubusercontent.com/assets/12679496/11455022/87e1833a-95fc-11e5-81d8-d2f65cadf1a4.png)

Trees and shrubs:

![screenshot_20151128_180108](https://cloud.githubusercontent.com/assets/12679496/11454976/44c755b8-95fa-11e5-98d4-16329f5981ee.png)

Slope analysis:

![screenshot_20151031_115437](https://cloud.githubusercontent.com/assets/12679496/10865362/512e2128-7fc6-11e5-9c40-e214fa738e40.png)

Aspect analysis:

![screenshot_20151031_114215](https://cloud.githubusercontent.com/assets/12679496/10865364/58dbd988-7fc6-11e5-8a7e-75abc31f378d.png)

3D Euclidean Distance analysis (based on input raster):

![screenshot_20151124_201516](https://cloud.githubusercontent.com/assets/12679496/11388193/31d764d0-92e8-11e5-8c92-d34ff733dc56.png)

Overlay a color image or raster bands for false-color mapping of landsat imagery:

![screenshot_20151129_200807](https://cloud.githubusercontent.com/assets/12679496/11463363/2ecb5c24-96d5-11e5-8cf3-2b305198eac3.png)

### Dependencies:
- this mod works out of the box with no libraries when using color BMP source rasters
- otherwise you must have imageMagick and MagickWand , OR imlib2 (8-bit limit) installed on your system
- and Mod Security disabled
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
- note windows users may have to edit line 162 (or so) of magick/init.lua from "MagickWand" to "C:/Program Files/ImageMagick-6.9.2-Q16/CORE_RL_wand_" or whatever the version and location of your MagickWand install might be.

### Upgrading:
- delete the realterrain.settings file in the world folder, or just create a new world

### Next steps:

- allow for placement of buildings and other structures via .mts import
- allow DEMs to tile according to standard naming conventions, or explicitly
- pull DEMs directly from the internet
- pull landcover directly from the internet
- allow output of heightmap and land cover to image files
- admin priv for using the settings tool
- add more raster analysis modes
- allow the placement of structures, saving of schems located to the map

### Changelog

#### 0.0.9
- got graphicsmagick library working and bit depth detection in other modes
- added support for graphicsmagick and imagemagick commandline interface (no libs required)
- fixed bugs with alignment of pixels to map and scaling / offsets
- form only shows options relevant to the current selected mode
- form validation for all numeric inputs
- "teleport to surface" button
- "set time to morning" button
- set the search limit and value range, as well as 2D/3D distance in distance mode
- performance improvements including obtaining pixel ranges where possible

#### 0.0.8
- expanded biome editor
- overlay color image onto map
- overlay color bands individually (landsat false-color)
- some code refactoring and performance improvements
- easter eggs mandelbrot and polynomial explorers

#### 0.0.7
- performance improvements to distance analysis mode, new default (demo) raster for distance mode ("points.tif")
- refactoring of some code: performance improvements where empty mapchunks are not processed
- compare two dems
- compare two biome files (or any other raster)
- customize raster output symbology
- bug fixes

#### 0.0.6
- biome cover uses absolute values AND ranges which equate exactly to USGS tier system (makes hand painting easier too)
- small bugfixes and windows compatability
- early stages of integrating python calls for GDAL and GRASS using lunatic-python (commented out - must be built per install)
- added some more raster modes, raster symbology nicer and fills in below steep areas
- experimental code for using imagemagick / graphicsmagick command line interface to reduce dependencies (commented out)
- some improvements to form validation, in-game raster selection doesn't require a restart

#### 0.0.5![screenshot_20151130_195859](https://cloud.githubusercontent.com/assets/12679496/11492217/d0813f6a-979e-11e5-872c-c7d68b964ade.png)
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