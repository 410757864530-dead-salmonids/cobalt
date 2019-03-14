# This file contains the schema for the database.
# Under most circumstances, you shouldn't need to run this file directly.
require 'sequel'

module Schema
  Sequel.sqlite(ENV['DB_PATH']) do |db|
    db.create_table?(:economy_users) do
      primary_key :id
      Integer :money, :default=>0
      DateTime :next_checkin
      String :color_role, :size=>255
      DateTime :color_role_daily
    end
  end
end