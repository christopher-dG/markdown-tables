if ENV['CI'] == 'true'
  require 'simplecov'
  SimpleCov.start
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require_relative File.join('..', 'lib', 'markdown-tables')
require 'test/unit'

class TestMarkdownTables < Test::Unit::TestCase

  def test_align_cell
    assert_equal(MarkdownTables.send(:align_cell, 1, 10, ':-'), 1)
    assert_equal(MarkdownTables.send(:align_cell, 1, 10, '-:'), 8)
    assert_equal(MarkdownTables.send(:align_cell, 1, 10, ':-:'), 5)

    assert_equal(MarkdownTables.send(:align_cell, 3, 10, ':-'), 1)
    assert_equal(MarkdownTables.send(:align_cell, 3, 10, '-:'), 6)
    assert_equal(MarkdownTables.send(:align_cell, 3, 10, ':-:'), 4)

    assert_equal(MarkdownTables.send(:align_cell, 4, 10, ':-'), 1)
    assert_equal(MarkdownTables.send(:align_cell, 4, 10, '-:'), 5)
    assert_equal(MarkdownTables.send(:align_cell, 4, 10, ':-:'), 3)
  end

  def test_sanitize!
    labels = ['a', 'b', 'c']
    data = [['1', '2'], ['3', '4'], ['5', '6']]
    MarkdownTables.send(:sanitize!, labels, data)
    assert_equal(labels, ['a', 'b', 'c'])
    assert_equal(data, [['1', '2'], ['3', '4'], ['5', '6']])

    labels = [1, 2, '|']
    data = ['a|bc'], ['ab|c'], ['|a|bc']
    MarkdownTables.send(:sanitize!, labels, data)
    assert_equal(labels, ['1', '2', '&#124;'])
    assert_equal(data, [['a&#124;bc'], ['ab&#124;c'], ['&#124;a&#124;bc']])
  end

  def test_validate
    assert_raises(RuntimeError) {  # 'labels must be an array'
      MarkdownTables.send(:validate, '', [[0]], '', false)
    }
    assert_raises(RuntimeError) {  # 'data must be a two-dimensional array
      MarkdownTables.send(:validate, [0], [0], '', false)
    }
    assert_raises(RuntimeError) {  # 'No column labels given'
      MarkdownTables.send(:validate, [], [[0]], '', false)
    }
    assert_raises(RuntimeError) {  # 'No cells given'
      MarkdownTables.send(:validate, [0], [[], []], '', false)
    }
    not_string = nil
    not_string.instance_eval('undef :to_s')
    assert_raises(RuntimeError) {  # 'One or more column labels cannot be made into a string'
      MarkdownTables.send(:validate, [not_string], [[0]], 0, false)
    }
    assert_raises(RuntimeError) {  # 'One or more cells cannot be made into a string'
      MarkdownTables.send(:validate, [0], [[not_string]], 0, false)
    }
    assert_raises(RuntimeError) {  # 'align must be a string or array'
      MarkdownTables.send(:validate, [0], [[0]], 0, false)
    }
    assert_raises(RuntimeError) {  # 'One or more align values is not a string'
      MarkdownTables.send(:validate, [0], [[0]], [1], false)
    }
    assert_raises(RuntimeError) {  # 'Too many data columns given'
      MarkdownTables.send(:validate, [0], [[0], [0]], '', false)
    }
    assert_raises(RuntimeError) {  # 'One or more rows has too many cells'
      MarkdownTables.send(:validate, [0], [[0, 0]], '', true)
    }
  end

  def test_alignment
    assert_equal(MarkdownTables.send(:alignment, '', 3), ':-:|:-:|:-:')
    assert_equal(MarkdownTables.send(:alignment, 'l', 3), ':-|:-|:-')
    assert_equal(MarkdownTables.send(:alignment, 'r', 3), '-:|-:|-:')
    assert_equal(MarkdownTables.send(:alignment, ['l', 'c', 'r'], 3), ':-|:-:|-:')
    assert_equal(MarkdownTables.send(:alignment, ['r'], 3), '-:|:-:|:-:')
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
    table = "a|b|c\n:-:|:-:|:-:\n1|2|3\n4|5|6\n7|8|9"
    assert_equal(
      MarkdownTables.plain_text(table),
      "|===|===|===|\n| a | b | c |\n|===|===|===|\n| 1 | 2 | 3 |\n|---|---|---|\n| 4 | 5 | 6 |\n|---|---|---|\n| 7 | 8 | 9 |\n|===|===|===|",
    )

    table = "aaaaa|bbbbb|ccccc\n-:|:-:|:-\n1|2|3\n4|5|6\n7|8|9"
    assert_equal(
      MarkdownTables.plain_text(table),
      "|=======|=======|=======|\n| aaaaa | bbbbb | ccccc |\n|=======|=======|=======|\n|     1 |   2   | 3     |\n|-------|-------|-------|\n|     4 |   5   | 6     |\n|-------|-------|-------|\n|     7 |   8   | 9     |\n|=======|=======|=======|",
    )

    table = "a|b|c\n:-:|:-:|:-:\n1|4|7\n||8\n|6|"
    assert_equal(
      MarkdownTables.plain_text(table),
      "|===|===|===|\n| a | b | c |\n|===|===|===|\n| 1 | 4 | 7 |\n|---|---|---|\n|   |   | 8 |\n|---|---|---|\n|   | 6 |   |\n|===|===|===|",
    )

    table = "||\n:-:|:-:|:-:\n||\n||\n||"
    assert_equal(
      MarkdownTables.plain_text(table),
      "|===|===|===|\n|   |   |   |\n|===|===|===|\n|   |   |   |\n|---|---|---|\n|   |   |   |\n|---|---|---|\n|   |   |   |\n|===|===|===|"
    )
  end

end
