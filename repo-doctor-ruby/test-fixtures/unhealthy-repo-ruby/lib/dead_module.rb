# This module is never required by anything
module DeadModule
  def self.unused_method
    "I am never called"
  end

  def self.another_unused_method
    "also unused"
  end
end
