
appliances.power_supplies = {}

function appliances.add_power_supply(supply_name, power_supply)
  if appliances.all_extensions[supply_name] then
    minetest.log("error", "Another appliances mod extension with name \""..supply_name.."\" is already registered.")
    return ;
  end
  appliances.power_supplies[supply_name] = power_supply;
  appliances.all_extensions[supply_name] = power_supply;
end

-- no power
if true then
  local power_supply = 
    {
      is_powered = function (self, power_supply, pos, meta)
          return 0;
        end,
    };
  appliances.add_power_supply("no_power", power_supply)
end

-- time
if true then
  local power_supply = 
    {
      is_powered = function (self, power_supply, pos, meta)
          return power_supply.run_speed;
        end,
    };
  appliances.add_power_supply("time_power", power_supply)
end

-- punch
if true then
  local power_supply = 
    {
      is_powered = function (self, power_supply, pos, meta)
          local is_powered = meta:get_int("is_powered");
          if (is_powered>0) then
            meta:set_int("is_powered", is_powered-1);
            return power_supply.run_speed;
          end
          return 0;
        end,
      power_need = function (self, power_supply, pos, meta)
          meta:set_int("is_powered", 0);
        end,
      power_idle = function (self, power_supply, pos, meta)
          meta:set_int("is_powered", 0);
        end,
      on_punch = function (self, power_supply, pos, node, puncher, pointed_thing)
          local meta = minetest.get_meta(pos);
          meta:set_int("is_powered", power_supply.punch_power or 1);
          
        end,
    };
  appliances.add_power_supply("punch_power", power_supply)
end

-- mesecons
if appliances.have_mesecons then
  local power_supply = 
    {
      is_powered = function (self, power_supply, pos, meta)
          local is_powered = meta:get_int("is_powered");
          if (is_powered~=0) then
            return power_supply.run_speed;
          end
          return 0;
        end,
      update_node_def = function (self, power_supply, node_def)
          node_def.effector = {
            action_on = function (pos, node)
              minetest.get_meta(pos):set_int("is_powered", 1);
            end,
            action_off = function (pos, node)
              minetest.get_meta(pos):set_int("is_powered", 0);
            end,
          }
        end,
      after_place_node = function (self, power_supply, pos, meta)
          minetest.get_meta(pos):set_int("is_powered", 0);
        end,
    };
  appliances.add_power_supply("mesecons_power", power_supply)
end

-- technic
if appliances.have_technic then
  -- LV
  local power_supply = 
    {
      is_powered = function (self, power_data, pos, meta)
          local eu_input = meta:get_int("LV_EU_input");
          local demand = power_data.demand or power_data.get_demand(self, pos, meta)
          if (eu_input>=demand) then
            return power_data.run_speed;
          end
          return 0;
        end,
      power_need = function (self, power_data, pos, meta)
          local demand = power_data.demand or power_data.get_demand(self, pos, meta)
          meta:set_int("LV_EU_demand", demand)
        end,
      power_idle = function (self, power_data, pos, meta)
          meta:set_int("LV_EU_demand", 0)
        end,
      activate = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      deactivate = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      running = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      waiting = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      no_power = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      update_node_def = function (self, power_data, node_def)
          self.meta_infotext = "technic_info";
          node_def.groups.technic_machine = 1;
          node_def.groups.technic_lv = 1;
          node_def.connect_sides = self.power_connect_sides;
          node_def.technic_run = function (pos, node)
            local meta = minetest.get_meta(pos);
            meta:set_string("infotext", meta:get_string("technic_info"));
          end
          node_def.technic_on_disable = function (pos, node)
            local meta = minetest.get_meta(pos);
            meta:set_string("infotext", meta:get_string("technic_info"));
          end
        end,
      after_register_node = function (self, power_data)
          technic.register_machine("LV", self.node_name_inactive, technic.receiver)
          technic.register_machine("LV", self.node_name_active, technic.receiver)
        end,
      on_construct = function (self, power_data, pos, meta)
          local meta = minetest.get_meta(pos);
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
    };
  appliances.add_power_supply("LV_power", power_supply)
  -- MV
  local power_supply = 
    {
      is_powered = function (self, power_data, pos, meta)
          local eu_input = meta:get_int("MV_EU_input");
          local demand = power_data.demand or power_data.get_demand(self, pos, meta)
          if (eu_input>=demand) then
            return power_data.run_speed;
          end
          return 0;
        end,
      power_need = function (self, power_data, pos, meta)
          local demand = power_data.demand or power_data.get_demand(self, pos, meta)
          meta:set_int("MV_EU_demand", demand)
        end,
      power_idle = function (self, power_data, pos, meta)
          meta:set_int("MV_EU_demand", 0)
        end,
      activate = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      deactivate = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      running = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      waiting = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      no_power = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      update_node_def = function (self, power_data, node_def)
          self.meta_infotext = "technic_info";
          node_def.groups.technic_machine = 1;
          node_def.groups.technic_mv = 1;
          node_def.connect_sides = self.power_connect_sides;
          node_def.technic_run = function (pos, node)
            local meta = minetest.get_meta(pos);
            meta:set_string("infotext", meta:get_string("technic_info"));
          end
          node_def.technic_on_disable = function (pos, node)
            local meta = minetest.get_meta(pos);
            meta:set_string("infotext", meta:get_string("technic_info"));
          end
        end,
      after_register_node = function (self, power_data)
          technic.register_machine("MV", self.node_name_inactive, technic.receiver)
          technic.register_machine("MV", self.node_name_active, technic.receiver)
        end,
      on_construct = function (self, power_data, pos, meta)
          local meta = minetest.get_meta(pos);
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
    };
  appliances.add_power_supply("MV_power", power_supply)
  -- HV
  local power_supply = 
    {
      is_powered = function (self, power_data, pos, meta)
          local eu_input = meta:get_int("HV_EU_input");
          local demand = power_data.demand or power_data.get_demand(self, pos, meta)
          if (eu_input>=demand) then
            return power_data.run_speed;
          end
          return 0;
        end,
      power_need = function (self, power_data, pos, meta)
          local demand = power_data.demand or power_data.get_demand(self, pos, meta)
          meta:set_int("HV_EU_demand", demand)
        end,
      power_idle = function (self, power_data, pos, meta)
          meta:set_int("HV_EU_demand", 0)
        end,
      activate = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      deactivate = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      running = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      waiting = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      no_power = function(self, power_data, pos, meta)
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
      update_node_def = function (self, power_data, node_def)
          self.meta_infotext = "technic_info";
          node_def.groups.technic_machine = 1;
          node_def.groups.technic_hv = 1;
          node_def.connect_sides = self.power_connect_sides;
          node_def.technic_run = function (pos, node)
            local meta = minetest.get_meta(pos);
            meta:set_string("infotext", meta:get_string("technic_info"));
          end
          node_def.technic_on_disable = function (pos, node)
            local meta = minetest.get_meta(pos);
            meta:set_string("infotext", meta:get_string("technic_info"));
          end
        end,
      after_register_node = function (self, power_data)
          technic.register_machine("HV", self.node_name_inactive, technic.receiver)
          technic.register_machine("HV", self.node_name_active, technic.receiver)
        end,
      on_construct = function (self, power_data, pos, meta)
          local meta = minetest.get_meta(pos);
          meta:set_string("infotext", meta:get_string("technic_info"));
        end,
    };
  appliances.add_power_supply("HV_power", power_supply)
end

