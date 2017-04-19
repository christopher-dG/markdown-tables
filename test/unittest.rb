if ENV['CI'] == 'true'
  require 'simplecov'
  SimpleCov.start
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require_relative File.join('..', 'lib', 'markdown-tables')
require 'test/unit'

class TestMarkdownTables < Test::Unit::TestCase

  def test_aligned_cell
    assert_equal(MarkdownTables.send(:aligned_cell, 'a', 5, ':-'), ' a   ')
    assert_equal(MarkdownTables.send(:aligned_cell, 'a', 5, '-:'), '   a ')
    assert_equal(MarkdownTables.send(:aligned_cell, 'a', 5, ':-:'), '  a  ')
    assert_equal(MarkdownTables.send(:aligned_cell, 'aaa', 8, ':-'), ' aaa    ')
    assert_equal(MarkdownTables.send(:aligned_cell, 'aaa', 8, '-:'), '    aaa ')
    assert_equal(MarkdownTables.send(:aligned_cell, 'aaa', 9, ':-:'), '   aaa   ')
    assert_equal(MarkdownTables.send(:aligned_cell, 'aaaa', 9, ':-'), ' aaaa    ')
    assert_equal(MarkdownTables.send(:aligned_cell, 'aaaa', 9, '-:'), '    aaaa ')
    assert_equal(MarkdownTables.send(:aligned_cell, 'aaaa', 10, ':-:'), '   aaaa   ')
  end

  def test_sanitize
    assert_equal(MarkdownTables.send(:sanitize, ''), '')
    assert_equal(MarkdownTables.send(:sanitize, 'a'), 'a')
    assert_equal(MarkdownTables.send(:sanitize, 0), '0')
    assert_equal(MarkdownTables.send(:sanitize, 'a|bc'), 'a&#124;bc')
  end

  def test_unsanitize
    assert_equal(MarkdownTables.send(:unsanitize, ''), '')
    assert_equal(MarkdownTables.send(:unsanitize, 'a'), 'a')
    assert_equal(MarkdownTables.send(:unsanitize, 'a&#124;bc'), 'a|bc')
    assert_equal(MarkdownTables.send(:unsanitize, 'a&nbsp;bc'), 'a bc')
  end

  def test_fill
    assert_equal(MarkdownTables.send(:fill, [], 0), [])
    assert_equal(MarkdownTables.send(:fill, [0], 1), [0])
    assert_equal(MarkdownTables.send(:fill, [], 1), [''])
    assert_equal(MarkdownTables.send(:fill, [0], 2), [0, ''])
    assert_raises(RuntimeError) {MarkdownTables.send(:fill, [0, 0], 1)}
  end

  def test_column_width
    assert_equal(MarkdownTables.send(:column_width, []), 3)
    assert_equal(MarkdownTables.send(:column_width, ['a']), 3)
    assert_equal(MarkdownTables.send(:column_width, ['a', 'abc']), 5)
  end

  def test_validate
    not_string = nil
    not_string.instance_eval('undef :to_s')
    # 'labels must be an array'
    assert_raises(RuntimeError) {MarkdownTables.send(:validate, '', [[0]], '', false)}
    # 'data must be a two-dimensional array
    assert_raises(RuntimeError) {MarkdownTables.send(:validate, [0], [0], '', false)}
    # 'No column labels given'
    assert_raises(RuntimeError) {MarkdownTables.send(:validate, [], [[0]], '', false)}
    # 'No cells given'
    assert_raises(RuntimeError) {MarkdownTables.send(:validate, [0], [[], []], '', false)}
    # 'One or more column labels cannot be made into a string'
    assert_raises(RuntimeError) {MarkdownTables.send(:validate, [not_string], [[0]], 0, false)}
    # 'One or more cells cannot be made into a string'
    assert_raises(RuntimeError) {MarkdownTables.send(:validate, [0], [[not_string]], 0, false)}
    # 'align must be a string or array'
    assert_raises(RuntimeError) {MarkdownTables.send(:validate, [0], [[0]], 0, false)}
    # 'One or more align values is not a string'
    assert_raises(RuntimeError) {MarkdownTables.send(:validate, [0], [[0]], [1], false)}
    # 'Too many data columns given'
    assert_raises(RuntimeError) {MarkdownTables.send(:validate, [0], [[0], [0]], '', false)}
    # 'One or more rows has too many cells'
    assert_raises(RuntimeError) {MarkdownTables.send(:validate, [0], [[0, 0]], '', true)}
  end

  def test_parse_alignment
    assert_equal(MarkdownTables.send(:parse_alignment, ['l'], 1), ':-')
    assert_equal(MarkdownTables.send(:parse_alignment, ['c'], 1), ':-:')
    assert_equal(MarkdownTables.send(:parse_alignment, ['r'], 1), '-:')
    assert_equal(MarkdownTables.send(:parse_alignment, ['l', 'c', 'r'], 3), ':-|:-:|-:')
    assert_equal(MarkdownTables.send(:parse_alignment, ['r'], 3), '-:|:-:|:-:')
  end

  def test_make_table
    labels = ['a', 'b', 'c']
    data = [[1, 2, 3], [4, 5, 6], [7 ,8, 9]]
    assert_equal(
      MarkdownTables.make_table(labels, data),
      "a|b|c\n:-:|:-:|:-:\n1|4|7\n2|5|8\n3|6|9",
    )
    assert_equal(
      MarkdownTables.make_table(labels, data, align: 'l'),
      "a|b|c\n:-|:-|:-\n1|4|7\n2|5|8\n3|6|9",
    )
    assert_equal(
      MarkdownTables.make_table(labels, data, is_rows: true),
      "a|b|c\n:-:|:-:|:-:\n1|2|3\n4|5|6\n7|8|9",
    )
    data = [[1], [4, nil, 6], [7, 8, '']]
    assert_equal(
      MarkdownTables.make_table(labels, data),
      "a|b|c\n:-:|:-:|:-:\n1|4|7\n||8\n|6|",
    )
    labels = [nil, nil, nil]
    data = [[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]]
    assert_equal(
      MarkdownTables.make_table(labels, data),
      "||\n:-:|:-:|:-:\n||\n||\n||",
    )
  end

  def test_plain_text
    assert_equal(
      MarkdownTables.plain_text("a|b|c\n:-:|:-:|:-:\n1|2|3\n4|5|6\n7|8|9"),
      "|===|===|===|\n| a | b | c |\n|===|===|===|\n| 1 | 2 | 3 |\n|---|---|---|\n| 4 | 5 | 6 |\n|---|---|---|\n| 7 | 8 | 9 |\n|===|===|===|",
    )
    assert_equal(
      MarkdownTables.plain_text("aaaaa|bbbbb|ccccc\n-:|:-:|:-\n1|2|3\n4|5|6\n7|8|9"),
      "|=======|=======|=======|\n| aaaaa | bbbbb | ccccc |\n|=======|=======|=======|\n|     1 |   2   | 3     |\n|-------|-------|-------|\n|     4 |   5   | 6     |\n|-------|-------|-------|\n|     7 |   8   | 9     |\n|=======|=======|=======|",
    )
    assert_equal(
      MarkdownTables.plain_text("a|b|c\n:-:|:-:|:-:\n1|4|7\n||8\n|6|"),
      "|===|===|===|\n| a | b | c |\n|===|===|===|\n| 1 | 4 | 7 |\n|---|---|---|\n|   |   | 8 |\n|---|---|---|\n|   | 6 |   |\n|===|===|===|",
    )
    assert_equal(
      MarkdownTables.plain_text("||\n:-:|:-:|:-:\n||\n||\n||"),
      "|===|===|===|\n|   |   |   |\n|===|===|===|\n|   |   |   |\n|---|---|---|\n|   |   |   |\n|---|---|---|\n|   |   |   |\n|===|===|===|"
    )
  end

end
