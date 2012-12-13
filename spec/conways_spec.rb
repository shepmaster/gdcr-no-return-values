class Board
  def initialize
    @cells = Set.new
    self
  end

  def come_alive_at(x, y)
    @cells << [x, y]
    self
  end

  def reset
    @cells.clear
    self
  end

  def find_live_cell_neighbors(callback)
    each_live_cell do |x, y|
      case alive_neighbor_count(x, y)
      when 2
        callback.has_two_neighbors(x, y)
      when 3
        callback.has_three_neighbors(x, y)
      end
    end
    self
  end

  def find_dead_cell_with_neighbors(callback)
    each_fringe_cell do |x, y|
      case alive_neighbor_count(x, y)
      when 3
        callback.has_three_neighbors(x, y)
      end
    end
    self
  end

  def each_live_cell
    @cells.each do |c|
      yield c
    end
    self
  end

  def each_fringe_cell
    fringe.each do |c|
      yield c
    end
    self
  end

  def alive_neighbor_count(x, y)
    points_surrounding(x, y).count { |point| @cells.include? point }
  end
  private :alive_neighbor_count

  def fringe
    @cells.flat_map { |x, y| points_surrounding(x, y) }.to_set - @cells
  end
  private :fringe

  def points_surrounding(x, y)
    (-1..1).flat_map do |delta_x|
      (-1..1).map do |delta_y|
        [x + delta_x, y + delta_y]
      end
    end.reject { |point| point == [x, y] }
  end
  private :points_surrounding
end

require 'forwardable'

class Game
  extend Forwardable

  def initialize
    @board = Board.new
    self
  end

  def_delegators :@board, :come_alive_at

  class AliveCellRules
    def initialize(board)
      @board = board
      self
    end

    def has_two_neighbors(x, y)
      @board.come_alive_at(x, y)
      self
    end

    def has_three_neighbors(x, y)
      @board.come_alive_at(x, y)
      self
    end
  end

  class DeadCellRules
    def initialize(board)
      @board = board
      self
    end

    def has_three_neighbors(x, y)
      @board.come_alive_at(x, y)
      self
    end
  end

  def time_passes
    new_board = Board.new
    alive_rules = AliveCellRules.new(new_board)
    dead_rules = DeadCellRules.new(new_board)

    @board.find_live_cell_neighbors(alive_rules)
    @board.find_dead_cell_with_neighbors(dead_rules)

    @board = new_board
    self
  end

  def output(device)
    @board.each_live_cell do |x, y|
      device.draw_cell(x, y)
    end
    self
  end
end

describe "Conway's Game of Life" do
  let (:ui) { double("user interface").as_null_object }
  subject { Game.new }

  it "starts with all cells dead" do
    ui.should_not_receive(:draw_cell)

    subject.output(ui)
  end

  it "allows cells to come alive" do
    ui.should_receive(:draw_cell).with(0, 0)
    subject.come_alive_at(0, 0)

    subject.output(ui)
  end

  context "when time passes" do
    describe "an alive cell" do
      let(:alive_cell_position) { [0, 0] }

      before do
        subject.come_alive_at(*alive_cell_position)
      end

      context "with fewer than two alive neighbors" do
        it "dies" do
          ui.should_not_receive(:draw_cell)
          subject.time_passes

          subject.output(ui)
        end
      end

      context "with two alive neighbors" do
        before do
          alive! [1, 0], [-1, 0]
        end

        it "keeps living" do
          ui.should_receive(:draw_cell).with(*alive_cell_position)
          subject.time_passes

          subject.output(ui)
        end
      end

      context "with three alive neighbors" do
        before do
          alive! [1, 0], [-1, 0], [1, 1]
        end

        it "keeps living" do
          ui.should_receive(:draw_cell).with(*alive_cell_position)
          subject.time_passes

          subject.output(ui)
        end
      end

      context "with more than three alive neighbors" do
        before do
          alive! [1, 0], [-1, 0], [1, 1], [-1, -1]
        end

        it "dies" do
          ui.should_not_receive(:draw_cell).with(*alive_cell_position)
          subject.time_passes

          subject.output(ui)
        end
      end
    end

    describe "a dead cell" do
      let(:dead_cell_position) { [0, 0] }

      context "with three alive neighbors" do
        before do
          alive! [1,1], [0,1], [1,0]
        end

        it "comes alive" do
          ui.should_receive(:draw_cell).with(*dead_cell_position)
          subject.time_passes
          subject.output(ui)
        end
      end
    end

    def alive!(*points)
      points.each do |point|
        subject.come_alive_at(*point)
      end
    end
  end
end
