class CustomApp
  def self.call(env)
    [ 200, {}, [ "Custom App" ] ]
  end
end

run CustomApp
