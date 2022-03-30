#!/usr/bin/env ruby

# file: ferrumwizard.rb

require 'yaml'
require 'rexle'
require 'ferrum'


class FerrumWizard

  attr_reader :browser, :links, :radio, :buttons, :js_methods

  def initialize(url=nil, headless: true, timeout: 10, cookies: nil,
                 debug: false)

    @url, @debug = url, debug
    @browser = Ferrum::Browser.new headless: headless, timeout: timeout
    sleep 3

    if url then

      loadx(cookies) if cookies

      @browser.goto(@url)
      @browser.network.wait_for_idle
      sleep 4

    end
  end

  def inspect()
    "#<FerrumWizard>"
  end

  # Intended to load all the cookies for a user to login automatically
  #
  # Follow these steps to load the cookies file:
  #
  #  1. launch the Ferrum browser
  #  fw = FerrumWizard.new( headless: false, debug: false)
  #
  #  2. load the cookies before you visit the website
  #  fw.load_cookies('/tmp/indeed2.txt')
  #
  #  3. visit the website
  #  url='https://somewebsite.com'
  #  fw.browser.goto(url)
  #
  def load_cookies(filepath)

    rawcookies = YAML.load(File.read(filepath))

    rawcookies.each do |h|

      if @debug then
        puts 'name: ' + h['name']
        puts 'h: ' + h.inspect
        sleep 0.7
      end

      browser.cookies.set(name: h['name'], value: h['value'],
                          domain: h['domain'], expires: h['expires'],
                          httponly: h['httpOnly'])
    end

  end

  alias loadx load_cookies

  def login(usernamex=nil, passwordx=nil, username: usernamex, password: passwordx)

    puts 'username: ' + username.inspect if @debug

    # search for the username input box
    e_username = @browser.at_xpath('//input[@type="email"]')
    puts 'e_username: ' + e_username.inspect if @debug
    sleep 1
    # search for the password input box
    found  = @browser.at_xpath('//input[@type="password"]')

    e_password = if found then
      found
    else
      @browser.xpath('//input').find {|x| x.property(:id) =~ /password/i}
    end

    sleep 1

    if username and e_username then
      puts 'entering the username' if @debug
      e_username.focus.type(username)
      sleep 1
    end

    e_password.focus.type(password, :Enter) if e_password

    after_login()

  end

  # login2 is used for websites where the user is presented with the username
  # input box on the first page and the password input box on the next page.
  #
  def login2(usernamex=nil, passwordx=nil, username: usernamex, password: passwordx)

    puts 'username: ' + username.inspect if @debug

    # search for the username input box
    e_username = @browser.at_xpath('//input[@type="email"]')
    puts 'e_username: ' + e_username.inspect if @debug
    sleep 1
    # search for the password input box

    if username and e_username then
      puts 'entering the username' if @debug
      e_username.focus.type(username, :Enter)
      sleep 2
    end

    e_password  = @browser.at_xpath('//input[@type="password"]')
    sleep 1

    e_password.focus.type(password, :Enter) if e_password

    after_login()


  end

  def quit
    @browser.quit
  end

  def scan_page()

    @doc = Rexle.new @browser.body
    fetch_links()
    scan_form_elements()
    scan_js_links()
    @browser.mouse.scroll_to(0, 800)
    self
  end

  # Saves all cookies for a given website into a YAML file
  # see also load_cookies()
  #
  # To use this method follow these steps:
  #
  #   1. launch the web browser through Ferrum
  #   fw = FerrumWizard.new(url, headless: false, debug: false)
  #
  #   2. go to the browser and login using your credentials
  #   fw.save_cookies(filepath)
  #
  #   3. exit the IRB session
  #
  def save_cookies(filepath=Tempfile.new('ferrum').path)

    rawcookies = @browser.cookies.all.keys.map do |key|

      if @debug then
        puts 'key: ' + key.inspect
        sleep 0.5
      end

      s = @browser.cookies[key].inspect
      a = s.scan(/"([^"]+)"=\>/)
      s2 = s[/(?<=@attributes=).*(?=>)/]
      eval(s2)

    end

    File.write filepath, rawcookies.to_yaml

  end

  def submit(h)

    e = nil

    h.each do |key, value|
      e = @browser.xpath('//input').find {|x| x.attribute('name') == key.to_s}
      e.focus.type(value)
    end

    e.focus.type('', :Enter)

    sleep 4
    scan_page()

  end

  def to_rb()
  end

  private

  def after_login()

    @browser.network.wait_for_idle
    sleep 4
    scan_page()

    @browser.base_url = File.dirname(@browser.url)
    @browser.mouse.scroll_to(0, 800)
    self

  end


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

    all_links = @doc.root.xpath('//a[@href]')

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

    active_links = @browser.xpath('//a[@href]')
    valid_active_links = indices.map {|n| active_links[n]}


    @links = valid_active_links.flat_map.with_index do |x, i|

      a = valid_links[i].text.split(/\W+/).map {|label| [label, x]}
      a << [valid_links[i].text, x]

      puts 'a: ' + a.inspect if @debug
      a + a.map {|x2, obj| [x2.downcase, obj]}

    end.to_h

    names = @links.keys.map(&:downcase).uniq.select {|x| x =~ /^[\w ]+$/}
    links = @links

    names.each do |name|

      define_singleton_method name.gsub(/ +/,'_').to_sym do

        links[name].click
        @browser.network.wait_for_idle

        sleep 1
        scan_page()
        self

      end

    end

  end

  def scan_form_elements()

    # find radio buttons

    a = @browser.xpath('//input[@type="radio"]')
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
      puts 's: ' + s.inspect  if @debug
      a = s.split(/\W+|(?=[A-Z])/).map {|label| [label, s]}
      a << [s, s]
      a << [s.split(/\W+|(?=[A-Z])/).join('_'), s]
      a << [s.split(/\W+|(?=[A-Z])/).join('_').downcase, s]
      #@js_methods[s] = a

      a.concat a.map {|x, name| [x.downcase, name] }

      puts 'a: ' + a.inspect if @debug

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
