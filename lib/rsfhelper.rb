#!/usr/bin/env ruby

# file: rsfhelper.rb

require 'open-uri'
require 'cgi'
require 'rexml/document'

class RSFHelper
  include REXML

  attr_reader :doc, :result, :text
  attr_accessor :package

  def initialize(hostname: nil)

    @hostname = hostname
    raise 'please supply a hostname' unless @hostname

    @url = File.join(parent_url, package + '.rsf')
    doc = Rexle.new URI.open(@url, 'UserAgent' => 'ClientRscript').read
    a = doc.root.xpath 'job/attribute::id'

    a.each do |attr|
      method_name = attr.gsub('-','_')
      method = "def %s(*args); run_job('%s', args) ; end" % \
                                                          ([method_name] * 2)
      self.instance_eval(method)
    end



    @package = o[:package]

    if @package.length > 0 then
      jobs_to_methods(@package)
      init_content_types
    end

  end

  class Package

    def initialize(drb_obj, parent_url, package)

      @obj = drb_obj

      @url = File.join(parent_url, package + '.rsf')
      doc = Rexle.new URI.open(@url, 'UserAgent' => 'ClientRscript').read
      a = doc.root.xpath 'job/attribute::id'

      a.each do |attr|
        method_name = attr.gsub('-','_')
        method = "def %s(*args); run_job('%s', args) ; end" % \
                                                            ([method_name] * 2)
        self.instance_eval(method)
      end

    end

    private

    def run_job(method_name, *args)

      args.flatten!(1)
      params = args.pop if args.find {|x| x.is_a? Hash}
      a = ['//job:' + method_name, @url, args].flatten(1)
      params ? @obj.run(a, params) : @obj.run(a)
    end

  end



  def package=(s)
    if s then
      @package = s
      jobs_to_methods(@package)
      init_content_types
    end
  end

  private

  def jobs_to_methods(package)

    url = "http://%s/source/%s" % [@hostname, package]

    doc = Document.new(URI.open(url, 'UserAgent' => 'ClientRscript').read)
    a = XPath.match(doc.root, 'job/attribute::id')

    a.each do |attr|
      method_name = attr.value.to_s.gsub('-','_')
      method = "def %s(param={}); query_method('%s', param); end" % [method_name, method_name]
      self.instance_eval(method)
    end
  end

  def init_content_types

    @return_type = {}

    xmlproc = Proc.new {
      @doc = Document.new(@result.sub(/xmlns=["']http:\/\/www.w3.org\/1999\/xhtml["']/,''))
      summary_node = XPath.match(@doc.root, 'summary/*')
      if summary_node then
        summary_node.each do |node|

        if node.cdatas.length > 0 then
          if node.cdatas.length == 1 then
            content =  node.cdatas.join.strip
          else
            if node.elements["@value='methods'"] then

            else
              content = node.cdatas.map {|x| x.to_s[/^\{.*\}$/] ? eval(x.to_s) : x.to_s}
            end

          end
        else
          content = node.text.to_s.gsub(/"/,'\"').gsub(/#/,'\#')
        end


method =<<EOF
def #{node.name}()
  #{content}
end
EOF
          self.instance_eval(method)
        end
        records = XPath.match(@doc.root, 'records/*/text()')
        method = "def %s(); %s; end" % [@doc.root.name, records.inspect] if records
        self.instance_eval(method)
      end
    }

    textproc = Proc.new {@text = @result}
    @return_type['text/plain'] = textproc
    @return_type['text/html'] = textproc
    @return_type['text/xml'] = xmlproc
    @return_type['application/xml'] = xmlproc
    @return_type['application/rss+xml'] = xmlproc

  end

  def query_method(method, params={})

    base_url = "http://#{@hostname}/do/#{@package}/"
    param_list = params.to_a.map{|param, value| "%s=%s" % [param, CGI.escape(value)]}.join('&')

    x = param_list.empty? ? '' : param_list
    url = "%s%s%s" % [base_url, method.gsub('_','-'), x]

    response = URI.open(url, 'UserAgent' => 'RSFHelper')
    @result = response.read
    @return_type[response.content_type].call
    return self
  end

end
