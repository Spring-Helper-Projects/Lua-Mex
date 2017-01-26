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

Custom mexmap configs are to be placed here:
`LuaRules/Configs/MetalSpots/(mapname).lua`

If you are a mapper and wish to include a lua mexmap config (a far more modern solution than hardcoding the metalmap), you can place your config here:
`mapconfig/map_metal_layout.lua`

Maps without a config have one generated dynamically from the engine metal map. The reference extraction value (in same units as engine extraction) is controllable through the `base_extraction` game rules param (found in `LuaRules\Gadgets\mex_spot_finder.lua`). Generally it's a bad idea to touch this because it won't affect maps that do have a config provided, creating a discrepancy.

# AI

Mex spots are available for AI to read as game rules params.
`mex_count` denotes the number of mexes- free placement maps (like speedmetal) have this set to -1.
Then, each mex has three parameters with names `mex_x#`, `mex_z#` and `mex_metal#` which are the coordinates and extraction respectively for the #th mex (indexed from 1).

# Report bugs!

Please be sure to report any bugs found on the project bug tracker, located here: https://github.com/Spring-Helper-Projects/Lua-Mex/issues
