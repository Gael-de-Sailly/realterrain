# realterrain v.0.0.5
A Minetest mod that brings real world Terrain into the game (using freely available DEM tiles). Any image can actually be used.

use any image any bit-depth (suggested to convert to greyscale first):

![screenshot_126233205](https://cloud.githubusercontent.com/assets/12679496/8270171/b98d0144-178e-11e5-9a21-ddea2624fdb6.png)

Supplied heightmap and landcover files:

![dem](https://cloud.githubusercontent.com/assets/12679496/10683910/00078544-78fc-11e5-9806-1c0786b3fa4e.png)
![biomes](https://cloud.githubusercontent.com/assets/12679496/10683908/fffbac4c-78fb-11e5-8190-4f0c0561b4b1.png)
![roads](https://cloud.githubusercontent.com/assets/12679496/10683909/fffec6b6-78fb-11e5-9947-37de7a21d770.png)
![water](https://cloud.githubusercontent.com/assets/12679496/10683911/000b474c-78fc-11e5-93f8-0aeb228446be.png)

Rock strata:

![screenshot_20151022_202823](https://cloud.githubusercontent.com/assets/12679496/10683866/771561ac-78fb-11e5-8fb4-6e9d876fcc67.png)

Settings tool (Realterrain Remote)

![screenshot_20151025_071817](https://cloud.githubusercontent.com/assets/12679496/10716053/98fdf0ec-7ae8-11e5-8da7-470b839fdf40.png)

Biomes tool:

![screenshot_20151031_093508](https://cloud.githubusercontent.com/assets/12679496/10864655/bf992306-7fb2-11e5-80b8-236d0440f72b.png)

Trees and shrubs:

![screenshot_20151025_140009](https://cloud.githubusercontent.com/assets/12679496/10717817/c79e4608-7b20-11e5-97e5-63c6116f480a.png)

Slope analysis:

![screenshot_20151031_115437](https://cloud.githubusercontent.com/assets/12679496/10865362/512e2128-7fc6-11e5-9c40-e214fa738e40.png)

Aspect analysis:

![screenshot_20151031_114215](https://cloud.githubusercontent.com/assets/12679496/10865364/58dbd988-7fc6-11e5-8a7e-75abc31f378d.png)

### Dependencies:
- You must have imageMagick and MagickWand installed on your system
- Mod security disabled

### Instructions
- install the dependencies and the mod as usual
- launch the game with mod enabled, default settings should work
- use the Realterrain Remote to change the settings, or
- edit the mod defaults section
- create greyscale images for heightmap, biomes, rivers and roads if desired (heightmap is required) these should be the same length and width. Biomes image should be 8-bit and use pixel values from 0-9 to match the biome numbers, which makes it hard to paint them visually (working on this issue), roads and rivers can be any non-zero value. 
- after you change settings exit the world and delete the map.sqlite in the world folder (the Delete button is experimental)
- enjoy!

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