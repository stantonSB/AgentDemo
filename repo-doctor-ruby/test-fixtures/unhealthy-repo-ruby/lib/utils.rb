# TODO: refactor this method to be more efficient
def slow_sort(arr)
  # FIXME: this is O(n^2), should use a better algorithm
  arr.each_index do |i|
    ((i + 1)...arr.length).each do |j|
      arr[i], arr[j] = arr[j], arr[i] if arr[i] > arr[j]
    end
  end
  arr
end

# HACK: temporary workaround for date parsing bug
def parse_date(str)
  Date.parse(str)
end

# XXX: this needs proper error handling
def divide(a, b)
  a / b
end
