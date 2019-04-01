module JsonCompletenessChecker

  def verify_json_structure json, structure
    to_check = case json
      when Hash
        json
      when String
        JSON json
    end
    if (errors = match_structure_againts_pattern to_check, structure, []).present?
      {success: false, errors: errors}
    else
      {success: true}
    end
  end

  private 

  def match_structure_againts_pattern json, structure, errors, path = ''
    get_key = ->(data, key){
      case key 
        when String
          if data.has_key?(key)
            key
          else
            sym = key.to_sym
            if data.has_key?(sym)
              sym
            end
          end
        when Symbol
          if data.has_key?(key)
            key
          else
            str = key.to_s
            if data.has_key?(str)
              str
            end
          end
      end
    }

    structure.each {|elem|
      case elem
        when String, Symbol
          key = get_key.(json, elem)
          local_path = "#{path}|#{elem}"
          unless key
            errors << {local_path => :missing}
          end
        when Hash
          elem.each {|field, children|
            key = get_key.(json, field)
            local_path = "#{path}|#{field}"
            unless key
              errors << {local_path => :missing}
            else
              match_structure_againts_pattern json.fetch(key), children, errors, local_path              
            end
          }
        when Array
          elem.each {|e|
            key = get_key.(json, e)
            local_path = "#{path}|#{e}"
            if key
              match_structure_againts_pattern json.fetch(key), elem.fetch(key), errors, local_path
            else
              errors << {local_path => :missing}
            end
          }
        else
          raise Exception.new "Element of unknown type #{el}."
      end
    }

    errors
  end

end