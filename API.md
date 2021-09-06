# Appliance API


See example folder for appliance examples.

## Appliances API functions (common)

### appliances.swap_node(pos, name)

* Function swap node by using minetest.swap_node fucntion.
* Metadata of node isn't affected.
* pos - node position
* name - new node name

### appliances.register_craft_type(type_name, type_def)

* Register craft type.
* type_name - Unique name of crafting type
* type_def - table with definition of crafting type
  * description - description of crafting type
  * icon - icon picture name
  * width - width of recipe
  * height - height of recipe
  * dynamic_display_size - unified_inventory callback only

### appliances.register_craft(craft_def)

* Register craft recipe.
* craft_def - table with craft recipe definition
  * type - type of recipe
  * output - recipe product
  * items - input items

## Appliance recipes

## Appliance power supply

Some power supply should be always registered.

## Appliance object fields

### Field sounds

Usable 

	sounds = {
		running = {
			sound = <SimpleSoundSpec>,
			sound_param = {},
			repeat_timer = 5,
		},
		waiting = {
			sound = <SimpleSoundSpec>,
			sound_param = {}.
		},
		activate = {
			sound = <SimpleSoundSpec>,
			sound_param = {}.
			repeat_timer = 0,
		},
		
	}

## Appliance object functions

Methods of object appliances.appliance.

### appliance:new(def)

### appliance:power_data_register(power_data)

* Take only useful power_data

## Appliance table parameters

appliance.input\_stack = "input"; -- input stack name, can be nil, can be same as output\_stack
appliance.input\_stack\_size = 1; -- zero value will disable stack creation 
appliance.input\_stack\_width = nil; -- use value to generate valid recipes for craftguide when using input stack with more then 1 stack items.
appliance.use\_stack = "use\_in"; -- use stack name, can be nil, can be same as input\_stack
appliance.use\_stack\_size = 1; -- zero value will disable stack creation
appliance.output\_stack = "output"; -- output stack name, cannot be nil
appliance.output\_stack\_size = 4; -- zero value will disable stack creation

appliance.power\_data = nil; -- nil mean, power is not required
appliance.meta\_infotext = "infotext";

-- recipe format
-- recipes automatizations
appliance.recipes = {
    inputs = {},
    usages = nil,
  }
appliance.stoppable\_production = true; -- when false, production is interruptable
appliance.stoppable\_consumption = true; -- when false, consumptio is interrutable

Power data
----------

### Keys - ordered by priority:
  "LV", "MV", "HV" -> powered by technic LV, MV or HV
  "mesecons" -> powered by messecons
  "punch" -> powered by punching
  "time" -> only time is need to create output
  
  
### Power definition
  {
    -- run speed when node is powered by this caterogy
    run_speed = 1.0,
    -- demand in EU, used by technic mod (keys "LV", "MV", "HV")
    demand = 100,
    -- list of power_data keys for disable, when this one is usable
    disable = {}
  }

Example:
 -- only one of data will stay
  {
    -- stay only if technic mod is enabled
    ["LV"] = {
        demand = 100,
        run_speed = 1,
        disable = {"mesecons","time"},
      },
    -- stau only when technic mod is disabled and mesecons mod is enabled
    ["mesecons"] = {
        run_speed = 1,
        disable = {"LV","time"},
      },
    -- stay only when technic and mesecons mod are disabled
    ["time"] = {
        run_speed = 1,
        disable = {"LV","mesecons"},
      },
    }

Recipes inputs
--------------

appliance:recipe\_register\_input(
  "input\_item", -- ignored if more then one inputs is used
  {
    inputs = 1,
    inputs = {"",""}, -- list of inputs, if more then one input is used, list length same as input inventory size
    outputs = {"output_item", {"multi_output1", "multi_output2"}}, -- list of one or more outputs, if more outputs, one record is selected
    losts = {}, -- output when production is interrupted
    require_usage = {["item"]=true}, -- nil, if every usage item can be used
    production_time = 160, -- time to product outputs
    consumption_step_size = 1, -- change usage consumption
  })

Recipes usages
--------------

appliance:recipe\_register\_usage(
  "usage\_item",
  {
    outputs = {"output_item", {"multi_output1", "multi_output2"}},
    losts = {},
    consumption_time = 60, -- time to change usage item to outputs
    production_step_size = 1, -- speed of production output
  })

Callback for potencionally redefinition
=======================================

All methods can be redefined in child class.

Methods with prefix cb_\* is ideal for redefinition if some special function have to be added.

Redefine method get\_formspec if you are not using default configuration of inventory sizes. Default method support setting have\_usage.


Registration methods
=====================

register\_nodes(shared\_def, inactive\_def, active\_def)
  - shared\_def is table with node setting which is same for active and inactive node.
  - inactive\_def is table with specific settings for inactive node
  - active\_def is table with specific settings for active node
  - table fields are same like if you use function minetest.register\_node
register\_recipes()
  - register all added recipes like custom recipes if inventory like unified\_uinventory, craftguide or i3 is aviable.


Other help functions
====================

appliances.register\_craft\_type({
    description = "", -- description text
    icon = "", -- path to icon file, can be nil
    width = 1, -- width of recipe (unified only)
    height = 1, -- height of recipe (unified only)
    dynamic_display_size = nil, -- unified callback only
  })

appliances.register\_craft({
    type = "", -- type name
    output = "", -- item string
    items = {""}, -- input items
  })

