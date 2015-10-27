class Hastighedstest < Sinatra::Base
    def format_response(data, accept)
      accept.each do |type|
       # return data.to_xml  if type.downcase.eql? 'text/xml'
        return data.to_json if type.downcase.eql? 'application/json'
        return data.to_json
      end
    end
end


class Hash
  def to_xml
    map do |k, v|
      text = Hash === v ? v.to_xml : v
      "<%s>%s</%s>" % [k, text, k]
    end.join
  end
end
