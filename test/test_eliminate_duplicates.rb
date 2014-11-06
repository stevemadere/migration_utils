require 'test/unit'
require 'active_support/hash_with_indifferent_access'
require 'ostruct'
require 'migration_utils/duplicate_elimination'

# These are fixture classes.
# I should really be using mocks but I just cannot get mocha to
# work with Test::Unit  (gem version dependency hell)
class Whatever < OpenStruct
  def initialize(*args)
    super
    @id = nil
  end

end

class RandomMigration

  include MigrationUtils::DuplicateKeyRemover

  def initialize()
  end

end

class EliminateDuplicatesTestCase < Test::Unit::TestCase

  def test_whatever_class_fixture
  end

  def test_random_migration_fixture
  end

  def test_eliminate_duplicates_with_mysql
  end

  def test_eliminate_duplicates_with_postgres
  end

end
