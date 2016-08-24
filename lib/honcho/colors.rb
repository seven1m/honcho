require 'curses'

module Honcho
  module Colors
    COLORS = [
      [Curses::COLOR_BLUE,    Curses::A_NORMAL],
      [Curses::COLOR_CYAN,    Curses::A_NORMAL],
      [Curses::COLOR_GREEN,   Curses::A_NORMAL],
      [Curses::COLOR_MAGENTA, Curses::A_NORMAL],
      [Curses::COLOR_RED,     Curses::A_NORMAL],
      [Curses::COLOR_YELLOW,  Curses::A_NORMAL],
      [Curses::COLOR_BLUE,    Curses::A_BOLD],
      [Curses::COLOR_CYAN,    Curses::A_BOLD],
      [Curses::COLOR_GREEN,   Curses::A_BOLD],
      [Curses::COLOR_MAGENTA, Curses::A_BOLD],
      [Curses::COLOR_RED,     Curses::A_BOLD],
      [Curses::COLOR_YELLOW,  Curses::A_BOLD]
    ].freeze

    def assign_colors_for_curses
      COLORS.each_with_index do |(color, _), index|
        Curses.init_pair(index + 1, color, Curses::COLOR_BLACK)
      end
      apps.keys.each_with_index.each_with_object({}) do |(app, index), hash|
        (_, quality) = COLORS[index]
        hash[app] = [index + 1, quality]
      end
    end

    def assign_colors_for_ansi
      colors = COLORS.dup
      apps.keys.each_with_object({}) do |app, hash|
        (curses_color_code, curses_color_quality) = colors.shift
        bold = curses_color_quality == Curses::A_BOLD ? 1 : 0
        hash[app] = "#{bold};3#{curses_color_code}"
      end
    end
  end
end
