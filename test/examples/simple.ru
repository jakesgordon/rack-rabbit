class SimpleApp
  def self.call(env)
    [ 200, {}, [ "simple" ] ]
  end
end

run SimpleApp
