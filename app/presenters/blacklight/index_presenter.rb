# frozen_string_literal: true
module Blacklight
  # Presents a single document on the results page
  class IndexPresenter
    attr_reader :document, :configuration, :view_context

    # @param [SolrDocument] document
    # @param [ActionView::Base] view_context scope for linking and generating urls
    # @param [Blacklight::Configuration] configuration
    def initialize(document, view_context, configuration = view_context.blacklight_config)
      @document = document
      @view_context = view_context
      @configuration = configuration
    end

    # link_to_document('VIEW', :counter => 3)
    # Use the catalog_path RESTful route to create a link to the show page for a specific item.
    # catalog_path accepts a hash. The solr query params are stored in the session,
    # so we only need the +counter+ param here. We also need to know if we are viewing to document as part of search results.
    def link_to_document(field_or_opts = nil, opts={ :counter => nil })
      if field_or_opts.is_a? Hash
        opts = field_or_opts
      else
        field = field_or_opts
      end

      view_context.link_to(label(field, opts),
                           view_context.url_for_document(document),
                           document_link_params(opts))
    end

    ##
    # Render the document index heading
    #
    # @param [Symbol, Proc, String] field_or_string_or_proc Render the given field or evaluate the proc or render the given string. if nil it defaults to calling _show_link_field_
    # @param [Hash] opts
    def label(field_or_string_or_proc = nil, opts = {})
      field_or_string_or_proc ||= show_link_field
      config = Configuration::NullField.new
      value = case field_or_string_or_proc
                when Symbol
                  config = field_config(field_or_string_or_proc)
                  document[field_or_string_or_proc]
                when Proc
                  field_or_string_or_proc.call(document, opts)
                when String
                  field_or_string_or_proc
              end

      value ||= document.id
      field_values(config, value: value)
    end

    ##
    # Render the index field label for a document
    #
    # Allow an extention point where information in the document
    # may drive the value of the field
    # @param [String] field
    # @param [Hash] options
    # @option options [String] :value
    def field_value field, options = {}
      field_config = field_config(field)
      field_values(field_config, options)
    end

    # Used in the document list partial (search view) for creating a link to the document show action
    def show_link_field
      fields = Array(view_configuration.title_field)
      field = fields.find { |f| document.has? f }
      field &&= field.try(:to_sym)
      field ||= document.id
      field
    end

    private

      def document_link_params(opts)
        view_context.session_tracking_params(document, opts[:counter]).deep_merge(opts.except(:label, :counter))
      end

      # TODO: perhaps the view_configuration can be passed in on initialize
      def view_configuration
        configuration.view_config(view_context.document_index_view_type)
      end

      ##
      # Get the value for a document's field, and prepare to render it.
      # - highlight_field
      # - accessor
      # - solr field
      #
      # Rendering:
      #   - helper_method
      #   - link_to_facet
      # @param [Blacklight::Configuration::Field] field_config solr field configuration
      # @param [Hash] options additional options to pass to the rendering helpers
      def field_values(field_config, options={})
        FieldPresenter.new(view_context, document, field_config, options).render
      end

      def field_config(field)
        configuration.index_fields.fetch(field) { Configuration::NullField.new(field) }
      end
  end
end
