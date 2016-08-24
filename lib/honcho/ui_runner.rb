require 'stringio'
require 'curses'
require_relative './passenger_status'
require_relative './ui_runner/table'

module Honcho
  class UIRunner < Runner
    def run
      setup_curses
      @colors = assign_colors_for_curses
      init_log_window
      draw
      super
    ensure
      unsetup_curses
    end

    def log(name, message)
      (color_index, color_quality) = colors[name]
      @log.attron(Curses.color_pair(color_index) | color_quality) do
        @log.addstr(name.rjust(label_width))
      end
      @log.addstr(': ')
      @log.addstr(message)
      @log.refresh
    end

    private

    def init_log_window
      top = adapters.size + 3
      @log = Curses::Window.new(lines - top, cols, top, 0)
      @log.scrollok(true)
    end

    def draw
      draw_queues
      draw_uptime
    end

    def draw_queues
      adapter_names = adapters.map(&:name)
      max_name_width = adapter_names.map(&:size).max
      bar_width = cols - max_name_width - 80
      table = UI::Table.new(
        headings: [
          'app'.ljust(max_name_width + 2),
          'webs   ',
          "req's   ",
          'sidekiq  ',
          'resque   ',
          ' ',
          'work queue'.ljust(bar_width),
          ' '
        ],
        width: cols - 100,
        top: 1,
        left: 2
      )
      pstatus = passenger_status
      data = adapters_by_app.map do |app, adapters|
        @pstatus_for_app = pstatus[app]
        count = adapters.map(&:total_count).inject(&:+)
        sidekiq = adapters.detect { |a| a.type == 'sidekiq' }
        resque = adapters.detect { |a| a.type == 'resque' }
        [
          [app, *colors[app]],
          [count_web_servers],
          [count_web_requests],
          [sidekiq && sidekiq.running? ? 'running' : ''],
          [resque && resque.running? ? 'running' : ''],
          ['['],
          [bar(count, bar_width), 2, 0],
          [']']
        ]
      end
      table.draw(data)
    end

    def count_web_servers
      return unless @pstatus_for_app
      return unless (busy_webs = @pstatus_for_app['workers'].select { |s| s['Uptime'] }).any?
      busy_webs.size
    end

    def count_web_requests
      return unless @pstatus_for_app
      @pstatus_for_app['workers'].map { |s| s['Processed'].to_i }.inject(&:+)
    end

    def draw_uptime
      x = cols - 38
      uptime = `uptime`
      loadavg = uptime.match(/load averages: (.*)/)[1]
      Curses.setpos(2, x)
      Curses.attron(Curses.color_pair(2)) do
        Curses.addstr('Load average: ')
      end
      Curses.addstr(loadavg)
      time = uptime.match(/up (.*), \d+ users/)[1]
      Curses.setpos(3, x)
      Curses.attron(Curses.color_pair(2)) do
        Curses.addstr('Uptime: ')
      end
      Curses.addstr(time)
    end

    def print(text, y = nil, x = nil)
      if y && x
        $stdout.print("\033[#{y};#{x}f#{text}")
      else
        $stdout.print(text)
      end
    end

    def bar(count, width)
      ('|' * count).ljust(width)[0...width]
    end

    def check_for_work
      draw
      super
    end

    def lines
      Curses.lines
    end

    def cols
      Curses.cols
    end

    def setup_curses
      Curses.init_screen
      Curses.start_color
      Curses.cbreak
      Curses.noecho
      Curses.curs_set(0)
      Curses.stdscr.keypad(true)
    end

    def unsetup_curses
      Curses.close_screen
    end

    def show_passenger?
      return @show_passenger unless @show_passenger.nil?
      @show_passenger = system('which passenger-status &>/dev/null')
    end

    def passenger_status
      return {} unless show_passenger?
      PassengerStatus.new.data.each_with_object({}) do |app, hash|
        hash[app['name']] = app
      end
    end
  end
end
