require File.join(File.dirname(__FILE__), 'db.rb')

class Runner < Sequel::Model

  def self.record!(hash)
    runner = create_or_update_by_mac!(hash)
    
    if runner[:idle_instances].to_i > runner[:max_instances].to_i
      runner.update :max_instances => runner[:idle_instances]
    end
  end
  
  def self.create_or_update_by_mac!(hash)
    if (runner = find(:mac => hash[:mac]))
      runner.update hash
    else
      Runner.create hash
    end
  end
  
  def self.find_all_outdated
    DB[:runners].filter("version < ? OR version IS NULL", Server.version)
  end
  
  def self.find_all_available
    DB[:runners].filter("version = ? AND last_seen_at > ?", Server.version, Time.now - 3)
  end  
  
  def self.available_instances
    find_all_available.inject(0) { |sum, r| r[:idle_instances] + sum }
  end
  
  def self.total_instances
    return 1 if ENV['INTEGRATION_TEST']
    DB[:runners].filter("version = ? AND last_seen_at > ?", Server.version, Time.now - 3600).inject(0) { |sum, r| r[:max_instances] + sum }
  end
  
end
