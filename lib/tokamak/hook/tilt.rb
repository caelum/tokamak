require File.expand_path(File.dirname(__FILE__) + '/../../tokamak.rb') unless defined? ::Tokamak

module Tokamak
  module Hook
    module Tilt
      
      class TokamakTilt
        
        def initialize
          @registry = Tokamak::Registry.new
        end
        
        # unfortunately Tilt uses a global registry
        def new(view, options)
          TokamakTemplate.new(@registry, view, options)
        end
        
      end

      class TokamakTemplate < ::Tilt::Template
        
        def initialize(registry, view, options)
          super(view, options)
          @registry = registry
        end
        
        def initialize_engine
          return if defined?(::Tokamak)
          require_template_library 'tokamak'
        end

        def prepare
          @media_type = options[:media_type]
          raise Tokamak::BuilderError.new("Content type required to build representation.") unless @media_type
        end

        def precompiled_preamble(locals)
          local_assigns = super
          <<-RUBY
            begin
              extend @registry[#{@media_type.inspect}].helper
              #{local_assigns}
          RUBY
        end

        def precompiled_postamble(locals)
          <<-RUBY
            end
          RUBY
        end

        def precompiled_template(locals)
          data.to_str
        end
      end

      ::Tilt.register 'tokamak', TokamakTilt.new

    end
  end
end
