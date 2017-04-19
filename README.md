# Markdown Tables

[![Gem](https://img.shields.io/gem/v/markdown-tables.svg)](https://rubygems.org/gems/markdown-tables)
[![Travis CI](https://travis-ci.org/christopher-dG/markdown-tables.svg?branch=master)](https://travis-ci.org/christopher-dG/markdown-tables)
[![AppVeyor](https://ci.appveyor.com/api/projects/status/sfqh4ouq46qjuxvx/branch/master?svg=true)](https://ci.appveyor.com/project/christopher-dG/markdown-tables/branch/master)
[![Codecov](https://codecov.io/gh/christopher-dG/markdown-tables/branch/master/graph/badge.svg)](https://codecov.io/gh/christopher-dG/markdown-tables)
[![Code Climate](https://codeclimate.com/github/christopher-dG/markdown-tables.png)](https://codeclimate.com/github/christopher-dG/markdown-tables)

**Utilities for creating and displaying Markdown tables in Ruby.**

## Installation
* `gem install markdown-tables`

## Usage

### `make_table`
You can create a Markdown table from an array of column `labels` and a two-dimensional array of cell `data`.

`data` is assumed to be a list of columns.
If you'd rather pass `data` as a list of rows, use the `is_rows` flag.

To specify the cell alignment, pass `align: 'l'` for left alignment and `'r'` for right alignment.
Any other value (or lack thereof) will result in centered cells.

You can also pass an array of alignment values, such as `['l', 'c', 'r']` to set alignment per column.

To leave a cell empty, use `nil` or an empty string.

```ruby
require 'markdown-tables'

labels = ['a', 'b', 'c']
data = [[1, 2, 3], [4 ,5, 6], [7, 8, 9]]

puts MarkdownTables.make_table(labels, data)
# a|b|c
# :-:|:-:|:-:
# 1|4|7
# 2|5|8
# 3|6|9

puts MarkdownTables.make_table(labels, data, is_rows: true)
# a|b|c
# :-:|:-:|:-:
# 1|2|3
# 4|5|6
# 7|8|9
```

### `plain_text`
Once you've generated a Markdown table, you can use it to produce a human-readable version of the table.

```ruby
require 'markdown-tables'

labels = ['unnecessarily', 'lengthy', 'sentence']
data = [['the', 'quick', 'brown'], ['fox', 'jumps', 'over'], ['the', 'lazy', 'dog']]

table = MarkdownTables.make_table(labels, data, is_rows: true, align: ['r', 'c', 'l'])

puts MarkdownTables.plain_text(table)
# |===============|=========|==========|
# | unnecessarily | lengthy | sentence |
# |===============|=========|==========|
# |           the |  quick  | brown    |
# |---------------|---------|----------|
# |           fox |  jumps  | over     |
# |---------------|---------|----------|
# |           the |  lazy   | dog      |
# |===============|=========|==========|
```
