# encoding: UTF-8

# Static page
module Static
  def index
    render :index => true
  end

  def admin
    render :content => { :page_htm => 'admin' }
  end
 
  def user
    render :file => { :page_htm => 'user' }
  end

  # For examples 404 
  def error(message)
    render :content => { :page_htm => 'p404', :data=>{'page_not_found' => message[:info]} }
  end

  # For examles 502
  # ...
end

class MegaController < ControllerInitialize
  include Static

  def element_add
    # If exception then go to error handler for next standart rendering LISP style
    @env.issue.element_add @meta.element_add ElementAdd.new(@env).insert @is.element_add
  end
  
  # Default read return JSON if in content key has data key
  def element_read type='all'
    case type
    when 'all'
      render :content => { :data => { 'page_not_found' =>  ElementRead.new(@env).all } }
    end
  end

end