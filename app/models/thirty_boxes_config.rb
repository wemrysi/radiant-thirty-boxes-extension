require 'singleton'

class ThirtyBoxesConfig
  include Singleton

  @@attr_prefix = '30boxes'
  @@attrs = [ :api_key, :app_name, :auth_token ]

  @@attrs.each do |attr|
    class_eval(<<-EOS, __FILE__, __LINE__)
      def self.#{attr}
        Radiant::Config['#{@@attr_prefix}.#{attr}'].to_s
      end

      def self.#{attr}=(obj)
        Radiant::Config['#{@@attr_prefix}.#{attr}'] = obj
      end
    EOS
  end

  def self.attributes
    attrs = {}
    @@attrs.each { |a| attrs[a] = send(a) }
    attrs
  end

  def self.attributes=(hash)
    old_attrs = attributes

    hash.each do |k,v|
      if old_attrs.keys.include?(k.to_sym) && (old_attrs[k.to_sym] != v)
        send("#{k}=", v)
      end
    end
  end
end
