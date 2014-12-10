class GamesController < ApplicationController
  def index
    @games = Game.all.reverse
  end

  def show
    @game = Game.find(params[:id])
    @player = @game.players.where(user: current_user).first

    case @game.stage
    when :finished then render :game_over
    when :started  then render @player ? :play_game : :game_already_started
    else                render :lobby
    end
  end

  def create
    game = Game.new(size: params[:game][:size])

    if game.save
      redirect_to game
    else
      flash.alert = "was not able to create a game: #{game.errors.messages.values.join(', ')}"
      redirect_to Game
    end
  end
end