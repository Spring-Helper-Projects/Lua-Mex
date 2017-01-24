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

For upgrading mexes, there are two subcomponents. They are:
* gadgets/unit_mex_upgrader.lua
* widgets/cmd_mex_upgrade_helper.lua

Luamex first uses the finder to find all of the mex spots on a map, them puts them in a table that is then made available to other gadgets and to widgets via the fetcher. From this, mex placement can then place mexes directly on the mex spots. Additionally, it will display the amount of metal that the mex spot will yield on the map itself. Mexspots are drawn directly on the map and on the minimap as well. Neutral metal spots will be displayed in grey, and captured ones will be displayed in the owner team's teamcolor.

For each builder a customparam can be added to that builder. This customparam is:
`area_mex_def = "UnitDefNameOfYourMex",`

Every builder with this customparam will receive a button on their orders menu that says "Mex". Clicking on this button and drawing a circle will cause mexes to be queued up everywhere within that circle. This customparam controls which mex is automatically queued for each builder.

## Upgrading mexes

For your convenience, the old mex upgrader script has been revitalized and altered to work for pretty much any spring game. It uses the extract's metal amount to compare unitdefs, and if a builder can build a mex with a larger extraction rate, it is given an upgrade mex button. This works exactly like the mex button previously mentioned. The builder will travel to the mex spot, reclaim the previous mex and build the appropriate upgraded one. By default, mexes with weapons, stealth, cloaked, etc will attempt to build into advanced mexes with those attributes. For this reason, in Balanced Annihilation, a basic exploiter mex with the llt will be upgraded into the moho exploiter with the large cannon.

This behavior can be toggled on lines 13 and 14 in gadgets/unit_mex_upgrader.lua (ignoreWeapons/ignoreStealth = true/false). Additionally, behavior can be fine tuned in function processMexData().

# Custom Mexmap Configs

Custom mexmap configs are to be placed here:
`LuaRules/Configs/MetalSpots/(mapname).lua`

If you are a mapper and wish to include a lua mexmap config (a far better solution than hardcoding the metalmap), you can place your config here:
`mapconfig/map_metal_layout.lua`

# Report bugs!

Please be sure to report any bugs found on the project bug tracker, located here: https://github.com/Spring-Helper-Projects/Lua-Mex/issues
