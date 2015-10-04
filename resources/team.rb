actions :create
default_action :create

attribute :name, kind_of: [String, Symbol], required: true, name_attribute: true
attribute :org, kind_of: [String, Symbol], required: true
attribute :privacy, equal_to: [:secret, :closed], default: :secret
