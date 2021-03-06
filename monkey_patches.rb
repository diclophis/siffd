#JonBardin
#
class Siffd::Controllers::ServerError
  def get(k, m, e)
    r(500, Mab.new do
      h1("Error")
      h2("#{k}.#{m}")
      h3("#{e.class} #{e.message}:")
      ul { e.backtrace.each { |bt| li(bt) } }
    end.to_s)
  end
end

class Siffd::Controllers::NotFound
  def get(p)
    r(404, Mab.new do
      h1((p + " not found wang chung"))
    end)
  end
end

class Time
  def slugify
    return self.month, self.day, self.year
  end
end

class Date
  def slugify
    return self.month, self.day, self.year
  end
end

class String
  def codify
    parts = self.split("(")
    name = parts[0].strip
    code = parts[1].gsub(")", "").strip
    {:name => name, :code => code}
  end
end
