require 'curses'

module Honcho
  module UI
    class Table
      def initialize(headings:, width:, top:, left:)
        @headings = headings
        @width = width
        @top = top
        @left = left
      end

      attr_accessor :width, :headings, :top, :left
      attr_reader :columns

      def draw(data)
        draw_headings
        draw_data(data)
        Curses.refresh
      end

      private

      def draw_headings
        @columns = []
        column = left
        Curses.setpos(top, left)
        headings.each_with_index do |heading, index|
          @columns[index] = column
          column += heading.size
          Curses.addstr(heading)
        end
      end

      def draw_data(data)
        data.each_with_index do |row, row_index|
          row.each_with_index do |(cell, color_index, color_quality), cell_index|
            cell_start = columns[cell_index]
            cell_width = (columns[cell_index + 1] || width) - cell_start
            Curses.setpos(top + row_index + 1, cell_start)
            if color_index && color_quality
              Curses.attron(Curses.color_pair(color_index) | color_quality) do
                Curses.addstr(cell.to_s.ljust(cell_width))
              end
            else
              Curses.addstr(cell.to_s.ljust(cell_width))
            end
          end
        end
      end
    end
  end
end
