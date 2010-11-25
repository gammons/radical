require 'stringio'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/radical_daemon'

require 'rubygems'
require 'mocha'
require 'ruby-debug' rescue nil

ActionMailer::Base.delivery_method = :test
$test_mode = true

class SSHObject < OpenStruct
  attr_accessor :options

  def initialize(options = {})
  end

  def on_data
    yield SSHObject.new, ""
  end

  def on_extended_data
    yield SSHObject.new, "", ""
  end

  def read_long
    ""
  end

  def upload!(from, to)
    nil
  end

  def scp
    SSHObject.new
  end

  def on_request(item)
    yield SSHObject.new, SSHObject.new
  end
end
