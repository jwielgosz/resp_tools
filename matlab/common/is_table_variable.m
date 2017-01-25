function [ is_var ] = is_table_variable(tab, var_name )
% Test if a table has a variable with the specified name

matches = strncmp(var_name, tab.Properties.VariableNames, length(var_name));
is_var = any(matches);

end

