module MigrationUtils
  # Migration helpers to safely (with backup) eliminate duplicate keys from a table 
  module DuplicateElimination
    require 'active_record'
=begin rdoc
A set of helper methods that can be used to eliminate duplicate rows
from a table prior to creating a unique index.  The duplicate rows 
removed are first copied to a backup table to ensure no data is lost.

The table in question MUST have a primary key column named 'id'

==== Example usage:

   class AddUniqeIndexOnCol1Col2 < ActiveRecord::Migration
      include MigrationUtils::DuplicateKeyRemover

      def up
         eliminate_duplicates(:table1, [:col1, col2])
         add_index :table1, [:col1,:col2], :unique => true
      end

      def down
        remove_index :table1, [:col1, :col2]
        restore_duplicates(:table1)
      end
        
=end
    def prefix_for_tables
      migration_version = ActiveRecord::Migrator.current_version
    end

    def namespace_for_backups
      "migration_backups"
    end

    def backup_table_name(orig_table_name)
      "#{quote_identifier(namespace_for_backups)}.#{quote_identifier([prefix_for_tables,orig_table_name].join('_'))}"
    end

    # Determine if we need to create a separate schema or a database to house the
    # backup tables
    def namespace_equivalent_for_db_server
      # HACK!
      return connection.respond_to?(:postgresql_connection) ?  'schema' : 'database'
    end

    def ensure_namespace_exists(namespace)
      namespace_equivalent_for_db_server = "schema"
      namespace_creation_sql = <<-"EOSQL"
        CREATE #{namespace_equivalent_for_db_server}
          IF NOT EXISTS#{quote_identifier(namespace)}
      EOSQL

      connection.execute(namespace_creation_sql)
    end

    def quote_identifier(identifier)
      connection.quote_column_name(identifier)
    end

    def create_backup_table(table)
      btn = backup_table_name(table)
      ensure_namespace_exists(namespace_for_backups)
      sql = "CREATE TABLE IF NOT EXISTS #{btn} ( LIKE #{quote_identifier(table)})"
      connection.execute(sql)
      btn
    end


    def eliminate_duplicates(table,key_columns)
      # @@@ FIXME: handle tables where primary key is not named 'id'
      primary_key_name = quote_identifier('id')

      btn = create_backup_table(table)
      
      key_column_list = (key_columns.map {|kc| quote_identifier(kc)}).join(',')

      defunct_ids_sql = <<-"EOSQL"
        SELECT defunct_id FROM ( 
          SELECT MAX(#{primary_key_name}) AS defunct_id FROM #{quote_identifier(table)}
            GROUP BY #{key_column_list}
            HAVING COUNT(#{primary_key_name}) > 1
        ) AS necessary_table_alias
      EOSQL

      delete_dup_rows_sql = <<-"EOSQL"
        DELETE FROM #{quote_identifier(table)}
           WHERE #{primary_key_name} IN (#{defunct_ids_sql})
      EOSQL

      backup_rows_sql = <<-"EOSQL"
        INSERT INTO #{btn}
          SELECT * FROM #{quote_identifier(table)}
            WHERE #{primary_key_name} IN (#{defunct_ids_sql})
      EOSQL

      finished = false
      while !finished
        num_rows_backed_up = connection.update_sql(backup_rows_sql)
        if num_rows_backed_up > 0
          num_rows_deleted = connection.update_sql(delete_dup_rows_sql)
          raise "Number of rows backed up (#{num_rows_backed_up}) and deleted (#{num_rows_deleted}) do not match!" unless num_rows_deleted == num_rows_backed_up
        else
          finished = true
        end
      end
    end

    def restore_duplicates(table)
      backup = backup_table_name(table)
      restore_sql = <<-"EOSQL"
        INSERT INTO #{quote_identifier(table)} SELECT * FROM #{backup}
      EOSQL
      num_rows_restored = connection.update_sql(restore_sql)
    end

  end
end
