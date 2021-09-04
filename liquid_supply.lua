

appliances.liquid_supplies = {}

function appliances.add_liquid_supply(supply_name, liquid_supply)
  if appliances.all_extensions[supply_name] then
    minetest.log("error", "Another appliances mod extension with name \""..supply_name.."\" is already registered.")
    return ;
  end
  appliances.liquid_supplies[supply_name] = liquid_supply;
  appliances.all_extensions[supply_name] = liquid_supply;
end

-- pipeworks
if appliances.have_pipeworks then
  local pipeworks_pipe_loaded = {
        ["pipeworks:pipe_1_loaded"] = true,
        ["pipeworks:pipe_2_loaded"] = true,
        ["pipeworks:pipe_3_loaded"] = true,
        ["pipeworks:pipe_4_loaded"] = true,
        ["pipeworks:pipe_5_loaded"] = true,
        ["pipeworks:pipe_6_loaded"] = true,
        ["pipeworks:pipe_7_loaded"] = true,
        ["pipeworks:pipe_8_loaded"] = true,
        ["pipeworks:pipe_9_loaded"] = true,
        ["pipeworks:pipe_10_loaded"] = true,
      };
  local pipeworks_pipe_with_facedir_loaded = {
        ["pipeworks:valve_on_loaded"] = true,
        ["pipeworks:entry_panel_loaded"] = true,
        ["pipeworks:flow_sensor_loaded"] = true,
        ["pipeworks:straight_pipe_loaded"] = true,
      };
  local liquid_supply = 
    {
      -- have_liquid function
      have_liquid = function(liquid_data, pos)
          local node = minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z});
          if node then
            if (pipeworks_pipe_loaded[node.name]) then
              return true;
            end
            if (pipeworks_pipe_with_facedir_loaded[node.name]) then
              if (minetest.facedir_to_dir(node.param2).y~=0) then
                return true;
              end
            end
          end
          return false;
        end,
      update_node_def = function(liquid_data, node_def)
          node_def.pipe_connections = {}; 
          for _,pipe_side in pairs(self.liquid_connect_sides) do
            node_def.pipe_connections[pipe_side] = true;
            node_def.pipe_connections[pipe_side.."_param2"] = pipe_connections[pipe_side];
          end
        end,
      after_place_node = function(self, liquid_data, pos)
          pipeworks.scan_for_pipe_objects(pos);
        end,
      after_dig_node = function(self, liquid_data, pos)
          pipeworks.scan_for_pipe_objects(pos);
        end,
    };
  appliances.add_liquid_supply("water_pipe", liquid_supply)
end

