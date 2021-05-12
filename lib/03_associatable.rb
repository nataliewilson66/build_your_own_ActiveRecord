require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @class_name = name.to_s.camelcase.singularize
    @foreign_key = name.to_s.singularize.concat("Id").underscore.to_sym
    @primary_key = :id
    options.each do |key, val|
      self.send("#{key}=", val)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @class_name = name.to_s.camelcase.singularize
    @foreign_key = self_class_name.to_s.singularize.concat("Id").underscore.to_sym
    @primary_key = :id
    options.each do |key, val|
      self.send("#{key}=", val)
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)
    define_method(name) {
      options = self.class.assoc_options[name]
      foreign_key_val = self.send(options.foreign_key)
      target_model_class = options.model_class
      target_model_class.where({options.primary_key => foreign_key_val}).first
    }
  end

  def has_many(name, options = {})
    # ...
    options = HasManyOptions.new(name, self.table_name, options)
    define_method(name) {
      primary_key_val = self.send(options.primary_key)
      target_model_class = options.model_class
      target_model_class.where({options.foreign_key => primary_key_val})
    }
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
