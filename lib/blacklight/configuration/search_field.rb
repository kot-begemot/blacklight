# frozen_string_literal: true
module Blacklight
  class Configuration::SearchField < Blacklight::Configuration::Field
    def normalize! blacklight_config = nil
      self.if = self.include_in_simple_select if self.if.nil?

      super
      self.qt ||= blacklight_config.default_solr_params[:qt] if blacklight_config && blacklight_config.default_solr_params

      self
    end

    def validate!
      raise ArgumentError, "Must supply a search field key" if self.key.nil?
    end

    def search_field_label
      return label if label
      I18n.t('blacklight.search.fields.default')
    end
  end
end
