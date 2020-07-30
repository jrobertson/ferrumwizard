#!/usr/bin/env ruby

# file: ferrumwizard.rb

require 'rexle'
require 'ferrum'


class FerrumWizard

  attr_reader :browser, :links

  def initialize(url, headless: true, debug: false)

    @url, @debug = url, debug
    @browser = Ferrum::Browser.new headless: headless

  end
  
  def login(username, password)

    b = @browser
    b.goto(@url)


    # search for the username input box
    e_username = b.at_xpath('//input[@type="email"]')

    # search for the password input box
    e_password  = b.at_xpath('//input[@type="password"]')

    if e_username and e_password then

      e_username.focus.type(username)
      e_password.focus.type(password, :Enter)

    end
    
    sleep 4
    fetch_links()
    self
    
  end
  
  def quit
    @browser.quit
  end

  def to_rb()
  end
  
  private
  
  def fetch_links()
    
    b = @browser
    doc = Rexle.new b.body    
    all_links = doc.root.xpath('//a')
    
    valid_links = all_links.reject do |x|
      
      puts 'x: ' + x.inspect if @debug
      s = x.plaintext.gsub('&amp;','&')
      r = (x.attributes[:target] == '_blank') | s.empty?

      puts 'r: ' + r.inspect if @debug
      r
      
    end.map {|x| all_links.index x}

    active_links = b.xpath('//a')
    valid_active_links = valid_links.map {|n| active_links[n]}
    

    @links = valid_active_links.flat_map do |x| 
      a = x.text.split(/\W+/).map {|label| [label, x]} << [x.text, x]
      a + a.map {|x, obj| [x.downcase, obj]}
    end.to_h
    
    names = @links.keys.map(&:downcase).uniq.select {|x| x =~ /^\w+$/}
    links = @links
    
    names.each do |name|
      
      define_singleton_method name.to_sym do
        links[name].click
        sleep 3
        self
      end
      
    end
    
  end  

  def method_missing(method_name, *args)

    node = @browser.at_css '.' + method_name.to_s
    node.text if node
    
  end  
  
end

