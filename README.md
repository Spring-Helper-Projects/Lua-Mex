# Credits

* CarRepairer for EasyMetal, the widget precursor to lua mexes
* Google Frog for expanding it to a gadget
* Sprung for abstracting lua-mex so that it can work with any spring game

# Lua-Mex

This is a spinoff of luamex that was originally created for Complete Annihilation and then later expanded for use in Zero-K. We wanted a system that could be dropped into any Spring Game which would immediately replace hardcoded engine metal extraction points with lua controlled points. An added benefit of this method is that the gamedev can create lua mexmap configs that will override the hardcoded ones in the map. Therefore, you can make each map specifically cater to your needs.

# How it functions

There are 4 main components to luamex itself:

* gadgets/mex_placement.lua
* gadgets/mex_spot_finder.lua
* widgets/api_mexspot_fetcher.lua
* widgets/cmd_mex_placement.lua

Luamex first uses the finder to find all of the mex spots on a map, them puts them in a table that is then made available to other gadgets and to widgets via the fetcher. From this, mex placement can then place mexes directly on the mex spots. Additionally, it will display the amount of metal that the mex spot will yield on the map itself. Mexspots are drawn directly on the map and on the minimap as well. Neutral metal spots will be displayed in grey, and captured ones will be displayed in the owner team's teamcolor.

Each mex needs a customparam defining extraction, which is a multiplier for the base spot value:
`metal_extractor = 2`

For each builder a customparam can be added to that builder. This customparam is:
`area_mex_def = "UnitDefNameOfYourMex",`

Every builder with this customparam will receive a button on their orders menu that says "Mex". Clicking on this button and drawing a circle will cause mexes to be queued up (or replaced, if of different type) everywhere within that circle. This customparam controls which mex is automatically queued for each builder.

# Custom Mexmap Configs

Maps without a config have one generated dynamically from the engine metal map. A manual config can be provided either in the game or the map.

Game-side configs are to be placed here:
`LuaRules/Configs/MetalSpots/(mapname).lua`

If you are a mapper and wish to include a lua mexmap config (a far more modern solution than hardcoding the metalmap), you can place your config here:
`mapconfig/map_metal_layout.lua`

The config consists of a table with the following fields:

`spots` is an array of mex spots, and is mandatory for map-side configs. Each mex spot is a table which has to contain `x` and `z` number fields (spot co-ordinates) and an optional `metal` number field (spot value).

`metalValueOverride` is an optional number field. If used in a game-side config without the `spots` table, this will be the value of all spots detected through the engine metalmap. If used alongside a `spots` table, it acts as a fallback when the value is not explicitly set for that spot.

By default, if the override is not present, spots without an explicit value will use extraction based on the engine metalmap at given spot, and if there is no metal there, the last fallback value is 2 (configurable).

## Config examples
Browse through actual configs: https://github.com/Spring-Helper-Projects/Lua-Mex/tree/master/luarules/configs/MetalSpots

Note that the config is regular Lua code so it can also have dynamically created content. For an example on what you can do, see 
https://github.com/Spring-Helper-Projects/Lua-Mex/blob/master/luarules/configs/MetalSpots/example.lua
# AI

Mex spots are available for AI to read as game rules params.
`mex_count` denotes the number of mexes- free placement maps (like speedmetal) have this set to -1.
Then, each mex has three parameters with names `mex_x#`, `mex_z#` and `mex_metal#` which are the coordinates and extraction respectively for the #th mex (indexed from 1).

# Report bugs!

Please be sure to report any bugs found on the project bug tracker, located here: https://github.com/Spring-Helper-Projects/Lua-Mex/issues
