module Deprecator
  module Strategy


    class Base
      #on class/module definition/extenting with deprecater or deprecate statement
      def class_found cls, where=nil, reason=nil, args=nil
        this = self
        cls.send(:define_method, :initialize){|*args|
          ::Deprecator.strategy.object_found(cls, self, reason, caller_line, where)
        }

        cls.send(:define_singleton_method, :method_added, ->(name){
          super(name)
          if name == :initialize && !@skip_next_initialize_addition
            meth = instance_method(name)
            @skip_next_initialize_addition = true
            define_method(name){|*args|
              ::Deprecator.strategy.object_found(cls, self, reason, caller_line, where)
              meth.bind(self).call(*args)
            }
            remove_instance_variable :@skip_next_initialize_addition
          end
          })
        cls.send(:define_singleton_method, :singleton_method_added, ->(name){
          #guard for self?
          if name == :method_added
            warn "[WARNING] when you replace method_added for deprecated class - you can no longer autotrack its object creation, use deprecation of initialize method."
          end
          })
      end

      # on deprecated class initialize
      def object_found o, where=nil, reason=nil
      end
      # on method definition
      def method_found cls,name, reason, where=nil
        this = self
        unless cls.method_defined?(name) # also we may place stubs there for existing methods in other strategies
          cls.send :define_method, name, ->(*args){
            this.method_called cls,name,reason,caller_line,where
          }
        else
          method = cls.instance_method(name)
          cls.send :define_method, name, ->(*args){
            this.method_called cls,name,reason,caller_line,where
            method.bind(self).call(*args)
          }
        end
      end
      def method_called cls,name,reason=nil,where,defined_at; end
      def deprecated reason=nil, where=caller_line, args=nil; end
      def fixme! msg, where, args; end
      def todo! msg, where, args; end
      def not_implemented msg, where, args
        raise NotImplemented, "method at #{where} called from #{caller_line(2)}"
      end
    end

    class Warning < Base
      def msg msg, where=nil
        warn "[DEPRECATED] #{msg}".gsub('%{where}', where)
      end

      def object_found o, where=nil, reason=nil # deprecated class initialize
        msg "deprecated class #{o.class} instantiated", where
      end

      def method_called cls,name,reason=nil,where,defined_at
        reason ||= "method %{method} is deprecated. Called from %{where}"
        msg reason.gsub('%{method}', name.to_s), where
      end

      def deprecated reason=nil, where=caller_line, args=nil
        where =~ /in `(.+)'$/
        method_name = $1 || '<unknown>'
        reason ||= "%{method} is deprecated!"
        reason.gsub!('%{method}', method_name)
        msg reason, where
      end
    end


  end
end
