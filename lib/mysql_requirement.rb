class MysqlRequirement
  def self.require
    yield self
  end
  
  def self.encoding(required_encoding = "utf8")
    %w(character_set_database character_set_client character_set_connection).each do |v|
      ActiveRecord::Base.connection.execute("SHOW VARIABLES LIKE '#{v}'").each do |f|
        unless f[1] == required_encoding
          puts "ERROR: MySQL database isn't properly encoded!"
          puts "Kindly set your #{f[0]} variable to '#{required_encoding}'."
          RAILS_DEFAULT_LOGGER.error("MySQL database isn't properly encoded!")
          exit 1
        end
      end
    end
  end

  def self.version(required_version)
     unless version_ok?(required_version)
       error_message = "ERROR: MySQL is required to be of version " +
         "'#{required_version}' but is of version #{actual_version}"
       puts error_message
       RAILS_DEFAULT_LOGGER.error error_message
       exit 1
     end
  end

  def self.c_driver
    Kernel.require 'mysql' if RAILS_ENV == "production"
  end

  def self.sql_mode(required_mode)
    actual_mode = ActiveRecord::Base.connection.select_value('SELECT @@session.sql_mode;')
    required_mode = Regexp.new(Regexp.escape(required_mode)) if required_mode.is_a?(String)
    if actual_mode !~ required_mode
      raise "MySQL sql mode is '#{actual_mode}' but is required to match '#{required_mode}'"
    end
  end  

  private
  def self.version_ok?(required_version)
    required_pattern = if required_version.is_a?(String)
                         Regexp.new(Regexp.escape(required_version))
                       else
                         required_version
                       end
    actual_version =~ required_pattern
  end
  
  def self.actual_version
    ActiveRecord::Base.connection.select_one("show variables like 'version'")["Value"]
  end
end
