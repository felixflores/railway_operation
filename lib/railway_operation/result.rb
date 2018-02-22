class Result < Hash
  def success?
    self[:errors].nil? || self[:errors].empty?
  end
end
