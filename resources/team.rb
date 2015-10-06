require 'set'

actions :create
default_action :create

namelist = lambda do |names|
  names.all? { |name| name.is_a?(String) }
end

attribute :name, kind_of: [String, Symbol], required: true, name_attribute: true
attribute :org, kind_of: [String, Symbol], required: true
attribute :description, kind_of: String, required: false
attribute :privacy, equal_to: [:secret, :closed], default: :secret
attribute :maintainers, kind_of: Array, required: false, default: [],
                        callbacks: { "should be list of usernames" => namelist }
attribute :members, kind_of: Array, required: false, default: [],
                    callbacks: { "should be list of usernames" => namelist }

def all_users
  (maintainers + members).to_set
end
