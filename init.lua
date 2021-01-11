
appliances = {};

local modpath = minetest.get_modpath(minetest.get_current_modname());

appliances.have_mesecons = minetest.get_modpath("mesecons")~=nil;
appliances.have_pipeworks = minetest.get_modpath("pipeworks")~=nil;
appliances.have_technic = minetest.get_modpath("technic")~=nil;

dofile(modpath.."/api.lua");
dofile(modpath.."/appliance.lua");

