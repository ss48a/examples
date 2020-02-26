# encoding: UTF-8

require './lib/deep_struct'

require './template'
require './property'
require './options_project'
require './db_project'

require './TestDriver.rb'

use Rack::Reloader, 0
use Rack::Static, :urls => ['/public']

require './config.rb'

require './engine/_RenderPage.rb'
require './engine/_ControllerInitialize.rb'

#===================#
# -- Mix methods -- #
#===================#
INCLUDING_PATH = ['engine','engine/model']
SHARED_PATH = 'engine/shared'

INCLUDING_PATH.each do |path|
  # Connect extensible modules
  shared = `ls #{SHARED_PATH}/`.split("\n")
  shared.each_with_index do |md,index|
    unless /^[A-Z][A-Za-z]{1,256}\.rb$/ =~ shared[index]
      shared.delete(index)
      next
    end  
    shared[index] = shared[index][0..-4]
    require "./#{SHARED_PATH}/#{md}"
  end

  # Expand classes with modules
  `ls #{path}`.split("\n").each do |clss|
    next if not /^[A-Z][A-Za-z]{1,256}\.rb$/ =~ clss

    clss = clss[0..-4]
    require "./#{path}/#{clss}"
    shared.each do |md|
      eval "class #{clss};include #{md};end"
    end
  end
end


class Application
  include RenderPage
  def call(env)
# Rewrite the standard exception for the entire code (actually only for output)
begin

  # RUN def call(env)
    no_route = true

    env['rack_input'] ||= env['rack.input'].read 
    env['request']    ||= Rack::Request.new env

    main = MegaController.new env

    # > static page
    return main.index       if env['REQUEST_PATH'].match %r{^/$}
    return main.element_add if env['REQUEST_PATH'].match %r{^/element_add$}
    return main.user        if env['REQUEST_PATH'].match %r{^/user$}
    # < end static page

    return main.element_read      if env['REQUEST_PATH'].match %r{^/element_read$}
    return main.elements_read     if env['REQUEST_PATH'].match %r{^/elements_read$}
    return main.property_frontend if env['REQUEST_PATH'].match %r{^/property_frontend$}
    
    return main.error( main.env.info ) unless main.env.check

    return main.error( {:bool => false, :code => 8003, :info => "#{env['REQUEST_PATH']}"} ) if no_route
  # END end def call(env)

rescue => e
case e.backtrace[0]
when /Rendering/
  return render_page( JSON.parse(e.message), main.env, env['request'] ) if main.respond_to? :env
  return render_page( JSON.parse(e.message), nil, env['request'] )
when /ANother/
  # Another mixin File
else
  e.message
  e.inspect 
  e.backtrace
end
  end
end
end

run Application.new()