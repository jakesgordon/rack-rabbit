class ErrorApp
  def self.call(env)
    raise "wtf"
  end
end

run ErrorApp
