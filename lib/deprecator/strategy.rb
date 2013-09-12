module Deprecator
  module Strategy


    class Base
      def class_found o, where=nil, reason=nil, args=nil
        # msg(if reason
        #   reason.gsub(/%{cls}/, o)
        # else
        #   "#{o} is deprecated!"
        # end, where)
      end
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
      def fixme! msg, where, args; end
      def todo! msg, where, args; end
      def not_implemented msg, where, args
        raise NotImplemented, "method at #{where} called from #{caller_line(2)}"
      end
    end

    class Warning < Base
      def msg msg, where=nil
        warn "[DEPRECATED] #{msg}"
      end

      def object_found o, where=nil, reason=nil # deprecated class initialize
        msg "deprecated class #{o.class} instantiated", where
      end

      # this is not entry point
      def method_called cls,name,reason=nil,where,defined_at
        msg "method #{name} is deprecated. Called from #{caller_line}"
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
