class Base
  def initialize(params={})
    params.each { |name, value| instance_variable_set "@#{name}", value }
  end

  def attributes
    Hash[instance_variables.map { |name| [name, instance_variable_get(name)] } ]
  end
end

class EDFHeader < Base
  attr_accessor :patient, :recorder
  attr_accessor :start_time
  attr_accessor :data_format      # identification code
  attr_accessor :header_bytes     # number of bytes in header record
  attr_accessor :manufacturer_id  # version / data format / manufacturer
  attr_accessor :record_count     # number of data records, -1 if unknown
  attr_accessor :record_seconds   # duration of data record
end

class EDFChannelHeader < Base
	attr_accessor :channel_label
	attr_accessor :transducer_type
	attr_accessor :dimension_unit   # physical dimension of channel, e.g. uV
	attr_accessor :physical_minimal # minimal physical value (in above units)
	attr_accessor :physical_maximal # maximal physical value
	attr_accessor :digital_minimal  # minimal digital value
	attr_accessor :digital_maximal  # maximal digital value
	attr_accessor :prefiltering     # pre-filtering description
	attr_accessor :sample_count			# number of samples in each record/data chunk
end

class EDFConfig < Base
	attr_accessor :header
	attr_accessor :channel_headers

  def initialize
    @header = EDFHeader.new
    @channel_headers = []
    super
  end

  def to_s
    (header.attributes.to_a + channel_headers.to_a).flatten.join " "
  end
end

class EDFInputIterator
	attr_accessor :edf_config
	attr_accessor :data_record_num
	attr_accessor :sample_num
	attr_accessor :data_record
end
