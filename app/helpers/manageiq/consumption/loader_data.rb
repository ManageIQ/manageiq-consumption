#
# Helper for load YAML files
#
#
#

module ManageIQ::Consumption
  module LoaderData
    def self.seed_file_name(*path)
      @seed_file_name ||= Pathname.new(Gem.loaded_specs['manageiq-consumption'].full_gem_path).join(*path)
    end

    def self.seed_data(*path)
      File.exist?(seed_file_name(*path)) ? YAML.load_file(seed_file_name(*path)) : []
    end
  end
end