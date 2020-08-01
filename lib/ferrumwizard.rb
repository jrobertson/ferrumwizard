#!/usr/bin/env ruby

# file: ferrumwizard.rb

require 'rexle'
require 'ferrum'


class FerrumWizard

  attr_reader :browser, :links, :radio, :buttons, :js_methods

  def initialize(url, headless: true, debug: false)

    @url, @debug = url, debug
    @browser = Ferrum::Browser.new headless: headless
    sleep 2
  end
  
  def inspect()
    "#<FerrumWizard>"
  end
  
  def login(usernamex=nil, passwordx=nil, username: usernamex, password: passwordx)
    
    puts 'username: ' + username.inspect if @debug

    b = @browser
    b.goto(@url)
    @browser.network.wait_for_idle
    sleep 3

    # search for the username input box
    e_username = b.at_xpath('//input[@type="email"]')
    puts 'e_username: ' + e_username.inspect if @debug
    sleep 1
    # search for the password input box
    e_password  = b.at_xpath('//input[@type="password"]')
    sleep 1
    
    if username and e_username then
      puts 'entering the username' if @debug
      e_username.focus.type(username)       
      sleep 1
    end
    
    e_password.focus.type(password, :Enter) if e_password
    @browser.network.wait_for_idle
    
    sleep 4

    scan_page()
    
  end    
  
  def quit
    @browser.quit
  end
  
  def scan_page()
    
    @doc = Rexle.new @browser.body       
    fetch_links()
    scan_form_elements()    
    scan_js_links()
    self
  end

  def to_rb()
  end
  
  private
  
  def fetch_buttons()

    a2 = @browser.xpath('//input[@type="button"]')
    @buttons = a2.flat_map do |x|

      a = x.value.split(/\W+/).map {|label| [label, x]}
      a << [x.value, x]
      a + a.map {|x, obj| [x.downcase, obj]}

    end.to_h

    names = @buttons.keys.map(&:downcase).uniq.select {|x| x =~ /^\w+$/}
    buttons = @buttons

    names.each do |name|
      
      define_singleton_method name.to_sym do
        buttons[name].click
        @browser.network.wait_for_idle
        sleep = 1
        self
      end
      
    end

  end
  
  def fetch_links()
     
    all_links = @doc.root.xpath('//a')
    
    all_links.each do |x|
      
      if x.plaintext.empty? then
        x.text = x.attributes[:href].sub(/\.\w+$/,'')[/([^\/]+)$/].split(/[_]|(?=[A-Z])/).join(' ')
      else
        x.text = x.plaintext.gsub('&amp;','&')
      end

    end
                                                                                                        
    valid_links = all_links.reject do |x|
      
      puts 'x: ' + x.inspect if @debug
      r = (x.attributes[:target] == '_blank')

      puts 'r: ' + r.inspect if @debug
      r
      
    end
    indices = valid_links.map {|x| all_links.index x}

    active_links = @browser.xpath('//a')
    valid_active_links = indices.map {|n| active_links[n]}
    

    @links = valid_active_links.flat_map.with_index do |x, i| 

      a = valid_links[i].text.split(/\W+/).map {|label| [label, x]}
      a << [valid_links[i].text, x]
      
      puts 'a: ' + a.inspect if @debug
      a + a.map {|x, obj| [x.downcase, obj]}
    end.to_h
    
    names = @links.keys.map(&:downcase).uniq.select {|x| x =~ /^[\w ]+$/}
    links = @links
    
    names.each do |name|
      
      define_singleton_method name.gsub(/ +/,'_').to_sym do
        links[name].click
        sleep 1
        scan_page()
        self
      end
      
    end
    
  end

  def scan_form_elements()
    
    # find radio buttons
    
    #a = doc.root.xpath('//input[@type="radio"]')
    a = @browser.xpath('//input[@type="radio"]')
    #h = a.group_by {|x| x.attributes[:name]}
    h = a.group_by {|x| x.attribute('name')}
    @radio = h.values
    define_singleton_method(:on) { @radio[0][0].click; self }
    define_singleton_method(:off) { @radio[0][1].click; self }
    
    fetch_buttons()
  
  end
  
  def scan_js_links()
    
    @js_methods = {}
    b = @browser
    
    b.xpath('//a').select {|x| x.attribute('href') =~ /^javascript/}.each do |e|
    

      s = e.attribute('href')[/(?<=^javascript:)[^\(]+/]
      puts 's: ' + s.inspect  
      a = s.split(/\W+|(?=[A-Z])/).map {|label| [label, s]}
      a << [s, s]
      a << [s.split(/\W+|(?=[A-Z])/).join('_'), s]
      a << [s.split(/\W+|(?=[A-Z])/).join('_').downcase, s]
      #@js_methods[s] = a

      a.concat a.map {|x, name| [x.downcase, name] }      

      puts 'a: ' + a.inspect

      a.uniq.select {|x, _| x =~ /^[a-z0-9_]+$/}.each do |x, name|
        
        if @debug then
          puts 'x: ' + x.inspect
          puts 'name: ' + name.inspect
        end
        
        define_singleton_method(x.to_sym) do |*args|
          #args = raw_args.map {|x| x[/^[0-9]+$/] ? x.to_i : x}
          js_method = "%s(%s)" % [name, args.map(&:inspect).join(', ')]
          puts 'js_method: ' + js_method.inspect if @debug
          @browser.evaluate(js_method)
          @browser.network.wait_for_idle
          sleep 4
          self.scan_page()
        end
        
      end
      
    end
  end

  def method_missing(method_name, *args)

    puts 'method_missing: ' + method_name.inspect if @debug
    node = @browser.at_css '.' + method_name.to_s
    node.text if node
    
  end  
  
end
