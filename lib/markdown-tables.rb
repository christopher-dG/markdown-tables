class MarkdownTables

  # Generate a Markdown table.
  # labels and data are one and two-dimensional arrays, respectively.
  # All input must have a to_s method.
  # Pass align: 'l' for left alignment or 'r' for right  alignment. Anything
  # else will result in cells being centered. Pass an array of align values
  # to specify alignment per column.
  # If is_rows is true, then each sub-array of data represents a row.
  # Conversely, if is_rows is false, each sub-array of data represents a column.
  # Empty cells can be given with nil or an empty string.
  def self.make_table(labels, data, align: '', is_rows: false)
    validate(labels, data, align, is_rows)

    # Deep copy the arguments so we don't mutate the originals.
    labels = Marshal.load(Marshal.dump(labels))
    data = Marshal.load(Marshal.dump(data))

    # Remove any breaking Markdown characters.
    labels.map! {|label| sanitize(label)}
    data.map! {|datum| datum.map {|cell| sanitize(cell)}}

    # Convert align to something that other methods won't need to validate.
    align.class == String && align = [align] * labels.length
    align.map! {|a| a =~ /[lr]/i ? a.downcase : 'c'}

    # Generate the column labels and alignment line.
    header_line = labels.join('|')
    alignment_line = parse_alignment(align, labels.length)

    # Pad the data arrays so that it can be transposed if necessary.
    max_len = data.map(&:length).max
    data.map! {|datum| fill(datum, max_len)}

    # Generate the table rows.
    rows = (is_rows ? data : data.transpose).map {|row| row.join('|')}

    return [header_line, alignment_line, rows.join("\n")].join("\n")
  end

  # Convert a Markdown table into human-readable form.
  def self.plain_text(md_table)
    md_table !~ // && raise('Invalid input')

    # Split the table into lines to get the labels, rows, and alignments.
    lines = md_table.split("\n")
    alignments = lines[1].split('|')
    # labels or rows might have some empty values but alignments
    # is guaranteed to be of the right width.
    table_width = alignments.length
    # '|||'.split('|') == [], so we need to manually add trailing empty cells.
    # Leading empty cells are taken care of automatically.
    labels = fill(lines[0].split('|'), table_width)
    rows = lines[2..-1].map {|line| fill(line.split('|'), table_width)}

    # Get the width for each column.
    cols = rows.transpose
    widths = cols.each_index.map {|i| column_width(cols[i].push(labels[i]))}

    # Align the labels and cells.
    labels = labels.each_index.map { |i|
      aligned_cell(unsanitize(labels[i]), widths[i], alignments[i])
    }
    rows.map! { |row|
      row.each_index.map { |i|
        aligned_cell(unsanitize(row[i]), widths[i], alignments[i])
      }
    }

    border = "\n|" + widths.map {|w| '=' * w}.join('|') + "|\n"
    return (
      border + [
        '|' + labels.join('|') + '|',
        rows.map {|row| '|' + row.join('|') + '|'}.join(border.tr('=', '-'))
      ].join(border) + border
    ).strip

  end

  # Sanity checks for make_table.
  private_class_method def self.validate(labels, data, align, is_rows)
    if labels.class != Array
      raise('labels must be an array')
    end
    if data.class != Array || data.any? {|datum| datum.class != Array}
      raise('data must be a two-dimensional array')
    end
    if labels.empty?
      raise('No column labels given')
    end
    if data.all? {|datum| datum.empty?}
      raise('No cells given')
    end
    if labels.any? {|label| !label.respond_to?(:to_s)}
      raise('One or more column labels cannot be made into a string')
    end
    if data.any? {|datum| datum.any? {|cell| !cell.respond_to?(:to_s)}}
      raise('One or more cells cannot be made into a string')
    end
    if ![String, Array].include?(align.class)
      raise('align must be a string or array')
    end
    if align.class == Array && align.any? {|val| val.class != String}
      raise('One or more align values is not a string')
    end
    if !is_rows && data.length > labels.length
      raise('Too many data columns given')
    end
    if is_rows && data.any? {|row| row.length > labels.length}
      raise('One or more rows has too many cells')
    end
  end

  # Convert some input to a string and replace any '|' characters  with
  # a non-breaking equivalent,
  private_class_method def self.sanitize(input)
    bar = '&#124;'  # Non-breaking HTML vertical bar.
    return input.to_s.gsub('|', bar)
  end

  # Replace non-breaking HTML characters with their plaintext counterparts.
  private_class_method def self.unsanitize(input)
    return input.gsub(/(&nbsp;)|(&#124;)/, '&nbsp;' => ' ', '&#124;' => '|')
  end

  # Generate the alignment line from a string or array.
  # align must be a string or array of strings.
  # n: number of labels in the table to be created.
  private_class_method def self.parse_alignment(align, n)
    align_map = {'l' => ':-', 'c' => ':-:', 'r' => '-:'}
    alignments = align.map {|a| align_map[a]}
    # If not enough values were given, center the remaining columns.
    alignments.length < n && alignments += [':-:'] * (n - alignments.length)
    return alignments.join('|')
  end

  # Align some text in a cell.
  private_class_method def self.aligned_cell(text, width, align)
    if align =~ /:-+:/  # Center alignment.
      start = (width / 2) - (text.length / 2)
    elsif align =~ /-+:/  # Right alignment.
      start = width - text.length - 1
    else  # Left alignment.
      start = 1
    end
    return ' ' * start + text + ' ' * (width - start - text.length)
  end

  # Get the width for a column.
  private_class_method def self.column_width(col)
    # Pad each cell on either side and maintain a minimum 3 width of characters.
    return [(!col.empty? ? col.map(&:length).max : 0) + 2, 3].max
  end

  # Add any missing empty values to a row.
  private_class_method def self.fill(row, n)
    row.length > n && raise('Sanity checks failed for fill')
    return row.length < n ? row + ([''] * (n - row.length)) : row
  end

end
