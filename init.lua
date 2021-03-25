
appliances = {};

local modpath = minetest.get_modpath(minetest.get_current_modname());

appliances.have_mesecons = minetest.get_modpath("mesecons")~=nil;
appliances.have_pipeworks = minetest.get_modpath("pipeworks")~=nil;
appliances.have_technic = minetest.get_modpath("hades_technic")~=nil;
--appliances.have_unified = minetest.get_modpath("unified_inventory")~=nil;

dofile(modpath.."/functions.lua");
dofile(modpath.."/appliance.lua");

