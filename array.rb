class Array
  def abs
    arr=self.clone
    for i in 0..arr.size-1
      arr[i]=arr[i].abs
    end
    return arr
  end
end