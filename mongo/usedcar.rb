
# Linear storage id only
module Mongoid

  # Module for copy bson id from one collection by bson id to another collection
  # Find elements save as array of elements in JSON format
  module BSONsTools
    module KlassMethods
      attr_accessor :copy_options
      def copy *attrs
        # Sugar :from -> :source
        @copy_options = {
          :destination => attrs[0],
          :source      => attrs[1].delete(:from)
        }
      end
    end
    
    module InstanceMethods
      def initialize *attrs
        super
        # After super!
        # Autorun methods
        #
        # Needed check depended of required 'Mongoid' model in extended class...
        #
        if copy_options

          # Check depended
          errors_add { 
            errors.add(destination, :invalid, message: "please: 'incude Mongoid::Document' before" ) 
          } unless defined? Mongoid::Document

          # Validate with help 'ActiveModel::Validations' included by 'super'
          errors_add { 
            errors.add(destination, :invalid, message: "error validate BSONs")
          } unless check_id_bsons?

          # Copy BSONs from :source to :destination
          copy

        end
      end

      def copy
        bsons.map! do |bson|
          # get class as capitalized symbol. For example: :Gallery
          klass = source.capitalize
          # Call method '.find' of 'Mongoid' model. For example: 'Gallery.find(some_id)'
          bson  = Mongoid.const_get(klass).find(bson).to_json
        end
      end
      def check_id_bsons?
        bsons.is_a?(Array) and -> {
          bsons.all? do |bson_id|
            return false unless bson_id =~ /^[0-9a-fA-F]{24}$/
            true
          end
        }.()
      end

      private
        def copy_options
          self.class.copy_options
        end
        def destination
          self.class.copy_options[:destination]
        end
        def source
          self.class.copy_options[:source]
        end
        def bsons
          self.instance_eval destination.to_s
        end
        def errors_add
          self.class.validate { yield }
        end
    end
    
    def self.included(receiver)
      receiver.extend         KlassMethods
      receiver.send :include, InstanceMethods
    end
  end
end



class Usedcar
  include Mongoid::Document
  include Mongoid::BSONsTools

  field :title, type: String
  field :description, type: String
  field :comments, type: String
  field :url, type: String
  field :sort, type: Integer

  field :model, type: String
  field :lineup, type: String
  field :case, type: String
  field :year, type: String
  field :mileage, type: String
  field :color, type: String
  field :engine, type: String
  field :capacity, type: Float
  field :transmission, type: String
  field :wheel, type: String
  field :drive, type: String
  field :condition, type: String
  field :owners, type: String
  field :power, type: String
  field :price, type: String

  field :photos, type: Array, default: []

  copy :photos, :from => :gallery
  
  field :title, type: String
  field :description, type: String
  field :slave, type: String
  field :url, type: String
  field :sort, type: Integer

  private
    def convert_title_to_url
      self.url = self.title.to_slug_param if self.url == nil or self.url == ''
    end
end