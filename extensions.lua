
local modpath = minetest.get_modpath(minetest.get_current_modname());

appliances.all_extensions = {}

dofile(modpath.."/power_supply.lua");
dofile(modpath.."/liquid_supply.lua");
dofile(modpath.."/item_supply.lua");
dofile(modpath.."/control.lua");
