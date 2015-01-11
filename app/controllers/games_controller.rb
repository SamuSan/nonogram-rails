# require_relative '../decorators/descriptive_game'

class GamesController < ApplicationController
  def index
    fetch_joined_and_unjoined_games
    
    respond_to do |format|
      format.js do
        response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
        render partial: 'game_list', content_type: 'text/html'
      end

      format.html { render :index }
    end
  end

  def show
    @game = DescriptiveGame.new(Game.find(params[:id]))
    @player = @game.players.find_by(user: current_user)
    @size = @game.nonogram.size if @game.nonogram.present?

    respond_to do |format|
      format.json do
        response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
        render json: @game
      end

      format.html do
        case
        when @game.completed? then render_game_over
        when @game.started?   then render_game_in_progress
        else                  render :game_lobby
        end
      end
    end
  end

  def new
    @host = current_user
    @nonograms = Nonogram.all
  end

  def create
    game = Game.new

    if game.save
      redirect_to game
    else
      redirect_to Game, alert: "was not able to create a game: #{game.errors.messages.values.join(', ')}"
    end
  end

  def update
    game = Game.find(params[:id])
    start_game = StartGame.new(game: game, size: params[:size])
    flash.alert = "was not able to start the game" unless start_game.call
    redirect_to game
  end

  private

  def fetch_joined_and_unjoined_games
    games = Game.not_completed.reverse
    joined_games = Game.not_completed.joined(current_user).reverse
    @joined_games = joined_games.map { |game| DescriptiveGame.new(game) }
    @unjoined_games = (games - joined_games).map { |game| DescriptiveGame.new(game) }
  end

  def render_game_over
    # is business logic => move elsewhere?
    @nonogram = DescriptiveNonogram.new(@game.nonogram)
    @solution_grid = Grid.decode(nonogram_data: @nonogram.solution)
    # @player_answers = player_answers
    render :game_over
  end

  def render_game_in_progress
    @grid = Grid.decode(nonogram_data: @game.nonogram.solution)
    @rows = @grid.rows
    @columns = @grid.columns

    if @player.present?
      render :game_play
    else
      render :game_started_not_joined
    end
  end
end