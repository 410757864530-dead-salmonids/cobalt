# Migration: ChangeRafflePoolDefault
Sequel.migration do
  up do
    alter_table :raffle do
      set_column_default :pool, 150
    end
  end

  down do
    alter_table :raffle do
      set_column_default :pool, nil
    end
  end
end