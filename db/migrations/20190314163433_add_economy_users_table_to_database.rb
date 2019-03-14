# Migration: AddEconomyUsersTableToDatabase
Sequel.migration do
  change do
    create_table(:economy_users) do
      primary_key :id
      Integer :money, default: 0
      Time :next_checkin
      String :color_role
      Time :color_role_daily
    end
  end
end