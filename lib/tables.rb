# Sanity checks for make_table.
def validate(labels, data, align, is_rows)
  if labels.class != Array
    raise('labels must be an Array')
  elsif data.class != Array || data.any? {|datum| datum.class != Array}
    raise('data must be a two-dimensional array')
  elsif labels.empty?
    raise('No column labels given')
  elsif data.empty?
    raise('No columns given')
  elsif data.all? {|datum| datum.empty?}
    raise('No cells given')
  elsif labels.any? {|label| !label.respond_to?(:to_s)}
    raise('One or more column labels cannot be made into a string')
  elsif data.any? {|datum| datum.any? {|cell| !cell.respond_to?(:to_s)}}
    raise('One or more cells cannot be made into a string')
  elsif ![String, Array].include?(align.class)
    raise('align must be a String or Array')
  elsif align.class == Array && align.any? {|val| val.class != String}
    raise('One or more align values is not a String')
  elsif !is_rows && data.length > labels.length
    raise('Too many data columns given')
  elsif is_rows && data.any? {|row| row.length > labels.length}
    raise('One or more rows has too many cells')
  end
end

# Convert all input to strings and replace  any '|' characters  with
# non-breaking equivalents,
def sanitize!(labels, data)
  bar = '&#124;'  # Non-breaking HTML vertical bar.
  labels.map! {|label| label.to_s.gsub('|', bar)}
  data.length.times {|i| data[i].map! {|cell| cell.to_s.gsub('|', bar)}}
end

# Generate the alignment line from a string or array.
# align must be a string or array or strings.
# n: number of labels in the table to be created.
def alignment(align, n)
  if align.class == String
    alignment = align == 'l' ? ':-' : align == 'r' ? '-:' : ':-:'
    alignment_line = ([alignment] * n).join('|')
  else
    alignments = align.map {
      |a| a.downcase == 'l' ? ':-' : a.downcase == 'r' ? '-:' : ':-l'
    }
    if alignments.length < n
      alignments += [':-:'] * (n - alignments.length)
    end
    alignment_line = alignments.join('|')
  end
  return alignment_line
end

# Generate a Markdown table.
# labels and data are one and two-dimensional arrays, respectively.
# All input must have a to_s method.
# Pass align: 'l' for left alignment or 'r' for right  alignment. Anything
# else will result in cells being centered. Pass an array of align values
# to specify alignment per column.
# If is_rows is true, then each sub-array represents a row.
# Conversely, if is_rows is false, each sub-array of data represents a column.
# Empty cells can be given with nil or an empty string.
def make_table(labels, data, align: '', is_rows: false)
  labels = Marshal.load(Marshal.dump(labels))
  data = Marshal.load(Marshal.dump(data))
  validate(labels, data, align, is_rows)
  sanitize!(labels, data)

  header_line = labels.join('|')
  alignment_line = alignment(align, labels.length)

  if is_rows
    rows = data.map {|row| row.join('|')}
  else
    max_len = data.map(&:size).max
    rows = []
    max_len.times do |i|
      row = []
      data.each {|col| row.push(col[i])}
      rows.push(row.join('|'))
    end
  end

  return [header_line, alignment_line, rows.join("\n")].join("\n")
end

# Print out a Markdown table in human-readable form.
def print_table(table) end
