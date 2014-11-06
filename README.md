migration_utils
==========

Utilities that are useful for complex rails database migrations.

Example:


  require 'migration_utils'

  class AddIndexOnCol1Col2 < ActiveRecord::Migration
    include MigrationUtils::DuplicateKeyRemover

    def up
       eliminate_duplicates(:table1, [:col1, col2])
       add_index :table1, [:col1,:col2], :unique => true
    end

    def down
      remove_index :table1, [:col1, :col2]
    end

  end
