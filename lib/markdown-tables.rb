class MarkdownTables

  # Generate a Markdown table.
  # labels and data are one and two-dimensional arrays, respectively.
  # All input must have a to_s method.
  # Pass align: 'l' for left alignment or 'r' for right  alignment. Anything
  # else will result in cells being centered. Pass an array of align values
  # to specify alignment per column.
  # If is_rows is true, then each sub-array represents a row.
  # Conversely, if is_rows is false, each sub-array of data represents a column.
  # Empty cells can be given with nil or an empty string.
  def self.make_table(labels, data, align: '', is_rows: false)
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

  # Convert a Markdown table into human-readable form.
  def self.plain_text(md_table)
    lines = md_table.split("\n")
    alignments = lines[1].split('|')
    table_width = alignments.length

    # Add back any any missing empty cells.
    labels = lines[0].split('|')
    labels.length < table_width && labels += [' '] * (table_width - labels.length)
    rows = lines[2..-1].map {|line| line.split('|')}
    rows.each_index do |i|
      rows[i].length < table_width && rows[i] += [' '] * (table_width - rows[i].length)
    end

    # Replace non-breaking HTML characters with their plaintext counterparts.
    rows.each do |row|
      row.each do |cell|
        cell.gsub!(/(&nbsp;)|(&#124;)/, '&nbsp;' => ' ', '&#124;' => '|')
      end
    end

    # Get the width for each column.
    widths = labels.map(&:length)  # Lengths of each column's longest element.
    rows.length.times do |i|
      rows[i].length.times do |j|
        rows[i][j].length > widths[j] && widths[j] = rows[i][j].length
      end
    end
    widths.map! {|w| w + 2}  # Add padding on each side.

    # Align the column labels.
    labels.length.times do |i|
      label_length = labels[i].length
      start = align_cell(label_length, widths[i], alignments[i])

      labels[i].prepend(' ' * start)
      labels[i] += ' ' * (widths[i] - start - label_length)
    end

    # Align the cells.
    rows.each do |row|
      row.length.times do |i|
        cell_length = row[i].length
        start = align_cell(cell_length, widths[i], alignments[i])
        row[i].prepend(' ' * start)
        row[i] += ' ' * (widths[i] - start - cell_length)
      end
    end

    border = "\n|" + widths.map {|w| '=' * w}.join('|') + "|\n"
    separator = border.gsub('=', '-')

    table = border[1..-1]  # Don't include the first newline.
    table += '|' + labels.join('|') + '|'
    table += border
    table += rows.map {|row| '|' + row.join('|') + '|'}.join(separator)
    table += border

    return table.chomp
  end

  # Sanity checks for make_table.
  private_class_method def self.validate(labels, data, align, is_rows)
    if labels.class != Array
      raise('labels must be an array')
    elsif data.class != Array || data.any? {|datum| datum.class != Array}
      raise('data must be a two-dimensional array')
    elsif labels.empty?
      raise('No column labels given')
    elsif data.all? {|datum| datum.empty?}
      raise('No cells given')
    elsif labels.any? {|label| !label.respond_to?(:to_s)}
      raise('One or more column labels cannot be made into a string')
    elsif data.any? {|datum| datum.any? {|cell| !cell.respond_to?(:to_s)}}
      raise('One or more cells cannot be made into a string')
    elsif ![String, Array].include?(align.class)
      raise('align must be a string or array')
    elsif align.class == Array && align.any? {|val| val.class != String}
      raise('One or more align values is not a string')
    elsif !is_rows && data.length > labels.length
      raise('Too many data columns given')
    elsif is_rows && data.any? {|row| row.length > labels.length}
      raise('One or more rows has too many cells')
    end
  end

  # Convert all input to strings and replace  any '|' characters  with
  # non-breaking equivalents,
  private_class_method def self.sanitize!(labels, data)
    bar = '&#124;'  # Non-breaking HTML vertical bar.
    labels.map! {|label| label.to_s.gsub('|', bar)}
    data.length.times {|i| data[i].map! {|cell| cell.to_s.gsub('|', bar)}}
  end

  # Generate the alignment line from a string or array.
  # align must be a string or array or strings.
  # n: number of labels in the table to be created.
  private_class_method def self.alignment(align, n)
    if align.class == String
      alignment = align == 'l' ? ':-' : align == 'r' ? '-:' : ':-:'
      alignment_line = ([alignment] * n).join('|')
    else
      alignments = align.map {
        |a| a.downcase == 'l' ? ':-' : a.downcase == 'r' ? '-:' : ':-:'
      }
      if alignments.length < n
        alignments += [':-:'] * (n - alignments.length)
      end
      alignment_line = alignments.join('|')
    end
    return alignment_line
  end

  # Get the starting index of a cell's text from the text's length, the cell's
  # width, and the alignment.
  private_class_method def self.align_cell(length, width, align)
    if align =~ /:-+:/
      return (width / 2) - (length / 2)
    elsif align =~ /-+:/
      return width - length - 1
    else
      return 1
    end
  end

end
