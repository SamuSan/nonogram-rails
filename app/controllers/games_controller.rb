class GamesController < ApplicationController
  def index
    @games = Game.not_completed.reverse
    
    respond_to do |format|
      format.js   do
        response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
        render partial: 'game_list', content_type: 'text/html'
      end
      format.html { render :index }
    end
  end

  def show
    @game = Game.find(params[:id])
    @player = @game.players.find_by(user: current_user)
    @size = @game.nonogram.size if @game.nonogram.present?

    respond_to do |format|
      format.js do
        response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
        render partial: 'other_players_attempts', locals: {player_answers: player_answers, size: @size, waiting_for_results: Time.now - @game.time_finished < 5}, content_type: 'text/html'
      end

      format.json do
        response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
        render json: @game
      end

      format.html do
        case
        when @game.completed?
          @solution = Grid.decode(nonogram_data: @game.nonogram.solution)
          @player_answers = player_answers
          render :game_over
        when @game.started?
          display_game_in_progress
        else render :game_lobby
        end
      end
    end
  end

  def create
    game = Game.new

    if game.save
      redirect_to game
    else
      flash.alert = "was not able to create a game: #{game.errors.messages.values.join(', ')}"
      redirect_to Game
    end
  end

  def update
    game = Game.find(params[:id])
    start_game = StartGame.new(game: game, size: params[:size])
    flash.alert = "was not able to start the game" unless start_game.call
    redirect_to game
  end

  private

  def player_answers
    answers = {}

    @game.players.each do |player|
      if player.answer?
        if player.won == false
          answers[player.user.name] = Grid.decode(nonogram_data: player.answer)
        end
      else
        answers[player.user.name] = nil
      end
    end

    answers
  end

  def display_game_in_progress
    @grid = Grid.decode(nonogram_data: @game.nonogram.solution)
    @rows = @grid.rows
    @columns = @grid.columns
    @clue_length = max_clue_length

    if @player.present?
      if session[:player] == @player.id && session[:player_answer].present?
        @player_answer = Grid.decode(nonogram_data: session[:player_answer])
      end

      render :game_play
    else
      render :game_started_not_joined
    end
  end

  def max_clue_length
    (@rows + @columns).map do |line|
      line.clue.length
    end.max
  end
end