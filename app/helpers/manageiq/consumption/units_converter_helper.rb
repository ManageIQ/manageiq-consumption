#
# Helper for unit converters
#
# Allows the user to find distance between prefixes, and also to convert between units.
# It also allows the user to extract the prefix from a unit 'Mb' -> 'M'
#
#

module ManageIQ::Consumption
  module UnitsConverterHelper
    SYMBOLS = %w(b B Hz bps Bps).freeze # What symbols are going to be searched for

    SI_PREFIX = { :''  => { name: '',
                            value: 1 },
                  :'K' => { name: 'kilo',
                            value: 1000 },
                  :'M' => { name: 'mega',
                            value: 1_000_000 },
                  :'G' => { name: 'giga',
                            value: 1_000_000_000 },
                  :'T' => { name: 'tera',
                            value: 1_000_000_000_000 },
                  :'P' => { name: 'peta',
                            value: 1_000_000_000_000_000 },
                  :'E' => { name: 'exa',
                            value:  1_000_000_000_000_000_000 },
                  :'d' => { name: 'deci',
                            value: 1 / 10.to_r }, # Rational
                  :'c' => { name: 'centi',
                            value: 1 / 100.to_r },
                  :'m' => { name: 'milli',
                            value: 1 / 1000.to_r },
                  :'µ' => { name: 'micro',
                            value: 1 / 1000_000.to_r},
                  :'n' => { name: 'nano',
                            value: 1 / 1000_000_000.to_r},
                  :'p' => { name: 'pico',
                            value: 1 / 1000_000_000_000.to_r} }.freeze
    BINARY_PREFIX = { :''   => { name: '',
                                 value: 1},
                      :'Ki' => { name: 'kibi',
                                 value: 1024},
                      :'Mi' => { name: 'mebi',
                                 value: 1_048_576},
                      :'Gi' => { name: 'gibi',
                                 value: 1_073_741_824},
                      :'Ti' => { name: 'tebi',
                                 value: 1_099_511_627_776},
                      :'Pi' => { name: 'pebi',
                                 value: 1_125_899_906_842_624},
                      :'Ei' => { name: 'exbi',
                                 value: 1_152_921_504_606_846_976} }.freeze

    ALL_PREFIXES = (SI_PREFIX.merge BINARY_PREFIX).freeze

    def self.to_unit(value, unit = '', destination_unit = '', prefix_type = 'ALL_PREFIXES')
      # It returns the value converted to the new unit
      prefix = extract_prefix(unit)
      destination_prefix = extract_prefix(destination_unit)
      prefix_distance = distance(prefix, destination_prefix, prefix_type)
      return nil if prefix_distance.nil?
      (value * prefix_distance).to_f
    end

    def self.distance(prefix, other_prefix = '', prefix_type = 'ALL_PREFIXES')
      # Returns the distance and whether you need to divide or multiply
      # Check that the list of conversions exists or use the International Sistem SI
      list = (self.const_get(prefix_type.upcase) if const_defined?(prefix_type.upcase)) || ALL_PREFIXES

      # Find the prefix name, value pair in the list
      orig = list[prefix.to_sym]
      dest = list[other_prefix.to_sym]
      # If I can't find the prefixes in the list:
      # If they are the same, return 1
      # If they are different (i.e. "cores" vs "none", return nil)
      return 1 if prefix == other_prefix
      return nil if orig.nil? || dest.nil?
      orig[:value].to_r / dest[:value]
    end

    def self.extract_prefix(unit)
      prefix = nil
      SYMBOLS.each do |x|
        prefix ||= /(.*)#{x}\z/.match(unit)&.captures
      end
      (prefix[0] unless prefix.nil?) || unit || ''
    end

    def self.extract_base_unit(unit)
      prefix = extract_prefix(unit)
      unit.slice(prefix.size, unit.size)

    end
  end
end