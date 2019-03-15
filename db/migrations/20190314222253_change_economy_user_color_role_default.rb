# Migration: ChangeEconomyUserColorRoleDefault
Sequel.migration do
  up do
    alter_table :economy_users do
      set_column_default :color_role, 'None'
    end
  end

  down do
    alter_table :economy_users do
      set_column_default :color_role, nil
    end
  end
end