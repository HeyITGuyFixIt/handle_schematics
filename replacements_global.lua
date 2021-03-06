
-- Note: If you are using handle_schematics.global_replacement_table, please also take into
--       account that you might have to add nodes to other tables, in particular:
--          * handle_schematics.direct_instead_of_drop
--          * handle_schematics.player_can_provide
--          * handle_schematics.bed_node_namess
--          * call handle_schematics.add_mirrored_node_type(..) where needed

-- allows to store global replacements (needed for subgames that do not provide a default mod)
handle_schematics.global_replacement_table = {};

handle_schematics.replace_global = function( node_name )
	if( not( node_name )) then
		return;
	end
	if( handle_schematics.global_replacement_table[ node_name ] ) then
		return handle_schematics.global_replacement_table[ node_name ];
	end
	return node_name;
end

handle_schematics.node_defined = function( node_name )
	if( not( node_name ) or node_name == "" ) then
		return;
	end
	if( handle_schematics.global_replacement_table[ node_name ] ) then
		return minetest.registered_nodes[ handle_schematics.global_replacement_table[ node_name ]];
	end
	return minetest.registered_nodes[ node_name ];
end


-- this is mostly for the build chest so that the final material beeing used can be shown
handle_schematics.apply_global_replacements = function(replacements, nodenames)
	-- change existing replacements where needed
	for i, repl in ipairs(replacements) do
		if(handle_schematics.global_replacement_table[ repl[2] ]) then
			replacements[i][2] = handle_schematics.global_replacement_table[ repl[2] ]
		end
	end
	-- add replacement for nodenames that are not yet covered
	for k, name in ipairs(nodenames) do
		-- if the node is to be replaced
		if(handle_schematics.global_replacement_table[name]) then
			local found = false
			for i, repl in ipairs(replacements) do
				if(repl[1] == name) then
					found = true
					break
				end
			end
			if(not(found)) then
				table.insert(replacements, {name, handle_schematics.global_replacement_table[name]})
			end
		end
	end
	return replacements
end


-- applies all necessary replacements:
--  * discontinued chests from cottages
--  * changed nodes in minetest_game such as doors etc.
--  * user-defined global replacements
--  * adjustments for realtest
--  * replaces wood, roof and plant (cotton) by the materials provided in
--    new_materials. If new_materials is empty, random replacements will used.
--    Structure of new_materials = {"wood":new_wood_material,
--      "roof":new_roof_material, "farming":new_cotton_replacement}
-- (currently only used by handle_schematics/detect_flat_land_fast.lua)
handle_schematics.replace_randomized = function( replacements, new_materials )

	if( not( replacements )) then
		replacements = {};
	end
	if( not( new_materials )) then
		new_materials = {};
	end
	-- these chests from cottages exist no longer
	table.insert( replacements, {"cottages:chest_private", "default:chest"});
	table.insert( replacements, {"cottages:chest_work",    "default:chest"});
	table.insert( replacements, {"cottages:chest_storage", "default:chest"});

	-- replace the wood
	if( not(new_materials['wood']) or not( minetest.registered_nodes[ new_materials['wood'] ])) then
		new_materials['wood'] =  replacements_group['wood'].found[
			math.random( 1, #replacements_group['wood'].found )];
	end
	replacements_group['wood'].replace_material( replacements, "default:wood", new_materials['wood']);
	-- change the roof to a random material
	if( not(new_materials['roof']) or not( minetest.registered_nodes[ new_materials['roof'] ])) then
		new_materials['roof'] =  replacements_group['roof'].found[
			math.random( 1, #replacements_group['roof'].found )];
	end
	replacements_group['roof'].replace_material( replacements, "cottages:roof_connector_wood", new_materials['roof']);
	-- grow random fruit instead of just cotton
	if( not(new_materials['farming']) or not( minetest.registered_nodes[ new_materials['farming'] ])) then
		new_materials['farming'] =  replacements_group['farming'].found[
			   math.random( 1, #replacements_group['farming'].found )];
	end
	replacements_group['farming'].replace_material( replacements, "farming:cotton", new_materials["farming"] );

	-- if this is the subgame realtest then apply the necessary replacements;
	-- handle_schematics.is_realtest is set in init.lua of handle_schematics,
	-- depending on mods installed and found in RealTest
	if( handle_schematics.is_realtest ) then
		replacements = replacements_group['realtest'].replace( replacements );
	end

	-- support global replacements
	for old_material, new_material in pairs( handle_schematics.global_replacement_table ) do
		table.insert( replacements, {old_material, new_material} );
	end

	return replacements;
end


handle_schematics.set_node_is_ground = function(data, value)
	local c_ignore = minetest.get_content_id( 'ignore' );
	-- none of the nodes in the data table count as ground
	for _,v in ipairs( data ) do
		local real_name = minetest.registered_aliases[ v ];
		if(not(real_name)) then
			real_name = v;
		end
		if(real_name and real_name ~= "" and minetest.registered_nodes[ real_name ]) then
			local id = minetest.get_content_id( real_name );
			if( id and id ~= c_ignore ) then
				replacements_group.node_is_ground[ id ] = value;
			end
		end
	end
end


-- just some examples for testing:
--handle_schematics.global_replacement_table[ 'default:wood' ] = 'default:mese';
--handle_schematics.global_replacement_table[ 'stairs:stair_wood' ] = 'default:diamondblock';

-- many people prefer the new 3d torch even if it will melt some snow
handle_schematics.global_replacement_table[ 'mg_villages:torch' ] = 'default:torch';
