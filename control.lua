
appliances.controls = {}

function appliances.add_control(control_name, control_def)
  if appliances.all_extensions[control_name] then
    minetest.log("error", "Another appliances mod extension with name \""..control_name.."\" is already registered.")
    return ;
  end
  appliances.controls[control_name] = control_def;
  appliances.all_extensions[control_name] = control_def;
end

-- punch
if true then
  local control = 
    {
      control_wait = function (self, control, pos, meta)
          local state = meta:get_int("punch_control");
          if (state~=0) then
            return false;
          end
          return true;
        end,
      deactivate = function (self, control, pos, meta)
          if control.power_off_on_deactivate then
            meta:set_int("punch_control", 0);
          end
        end,
      after_place_node = function (self, control, pos, meta)
          minetest.get_meta(pos):set_int("punch_control", 0);
        end,
      on_punch = function (self, control, pos, node, puncher, pointed_thing)
          local meta = minetest.get_meta(pos);
          local state = meta:get_int("punch_control");
          if (state~=0) then
            meta:set_int("punch_control", 0);
          else
            meta:set_int("punch_control", 1);
            self:activate(pos, meta);
          end
        end,
    };
  appliances.add_control("punch_control", control);
end

-- mesecons
if appliances.have_mesecons then
  local control = 
    {
      control_wait = function (self, control, pos, meta)
          local state = meta:get_int("mesecons_control");
          if (state~=0) then
            return false;
          end
          return true;
        end,
      deactivate = function (self, control, pos, meta)
          if control.power_off_on_deactivate then
            meta:set_int("mesecons_control", 0);
          end
        end,
      update_node_def = function (self, control, node_def)
          node_def.effector = {
            action_on = function (pos, node)
              minetest.get_meta(pos):set_int("mesecons_control", 1);
              self:activate(pos, meta);
            end,
            action_off = function (pos, node)
              minetest.get_meta(pos):set_int("mesecons_control", 0);
            end,
          }
        end,
      after_place_node = function (self, control, pos, meta)
          minetest.get_meta(pos):set_int("mesecons_control", 0);
        end,
      
    };
  appliances.add_control("mesecons_control", control);
end

-- digilines
if appliances.have_digilines then
  local control = 
    {
      control_wait = function (self, control, pos, meta)
          local state = meta:get_float("digilines_control");
          if (state~=0) then
            return false;
          end
          return true;
        end,
      deactivate = function (self, control, pos, meta)
          if control.power_off_on_deactivate then
            meta:set_float("digilines_control", 0);
          end
        end,
      update_node_def = function (self, control, node_def)
          node_def.digilines = {
            receptor = {},
            effector = {
              action = function (pos, _, channel, msg)
                minetest.get_meta(pos):set_float("digilines_control", 0);
              end,
            },
          }
        end,
      after_place_node = function (self, control, pos, meta)
          minetest.get_meta(pos):set_int("digilines_control", 0);
        end,
      
    };
  appliances.add_control("digilines_control", control);
end

