# frozen_string_literal: true

require 'yaml'
require 'pry'

# Game class starts new game
class Game
  attr_reader :guesses_left, :secret_word

  def initialize
    @player = Player.new
    @board = Board.new
    @guesses_left = 7
    @guesses = []
    puts play
  end

  def play
    puts 'Welcome to Hangman!'
    save_load_message
    while @guesses_left.positive?
      puts "Wrong guesses left: #{@guesses_left}"
      @board.show
      letter = @player.make_guess
      check_input(letter)
      puts "You have used: #{@guesses.join(' ')}"
      check_game_over
    end
  end

  def check_input(letter)
    save_load_input(letter)
    include_letter(letter)
  end

  def save_load_message
    puts 'If you have a saved game, you can load it by typing "load".'
    puts 'If you want to save your progress, you can do so at anytime by typing "save".'
  end

  def save_load_input(letter)
    save_game if letter == 'save'
    load_game if letter == 'load'
  end

  def include_letter(letter)
    if @board.word.include?(letter)
      already_guessed?(letter)
    elsif not @board.word.include?(letter)
      check_length(letter)
      send_to_guesses(letter)
      @guesses_left -= 1
    else
      puts 'Continuing...'
    end
  end

  def check_length(letter)
    if letter.length > 1
      puts 'Please only type 1 letter for each guess..'
    elsif letter.length == 1
      puts "Sorry, '#{letter}' is not in the secret word."
      puts "You've already guessed #{letter}." if @guesses.include?(letter)
    end
  end

  def send_to_guesses(letter)
    @guesses << letter if letter.length == 1
  end

  def already_guessed?(letter)
    if @guesses.include?(letter)
      puts "You've already guessed #{letter}."
    else
      puts "Good guess! '#{letter}' appears in the secret word."
      @board.update(letter)
      @guesses << letter
    end
  end

  def check_game_over
    if @board.word_complete?
      puts 'You guessed the word!'
      puts "It was #{@board.secret_word}."
      play_again if @board.word_complete?
    elsif !@board.word_complete?
      @board.game_over?(guesses_left)
    end
  end

  def to_yaml(filename)
    Dir.mkdir('saved_games') unless File.exist?('saved_games')
    f = File.open("saved_games/#{filename}.yaml", 'w')
    YAML.dump({
                player: @player,
                board: @board,
                guesses_left: @guesses_left,
                guesses: @guesses
              }, f)
    f.close
    game_saved
  end

  def game_saved
    puts 'Game saved successfully!'
    exit
  end

  def from_yaml(filename)
    game_data = YAML.unsafe_load(File.read("./saved_games/#{filename}.yaml"))
    @player = game_data[:player]
    @board = game_data[:board]
    @guesses_left = game_data[:guesses_left]
    @guesses = game_data[:guesses]
    puts 'Game loaded successfully!'
  end

  def save_game
    puts 'How will you name your file?'
    filename = gets.chomp
    to_yaml(filename)
  end

  def load_game
    if File.exist?('./saved_games/')
      puts "Saved games: #{Dir.children('./saved_games').join(' ')}"
      puts 'Enter one of the filenames like so: "filename" (without ".yaml")'
      filename = gets.chomp
      from_yaml(filename)
    else
      puts 'No saved game found. Start a new game.'
    end
  end

  def play_again
    puts 'Would you like to play again? y/n'
    answer = gets.chomp.downcase
    Game.new if answer == 'y'
    exit if answer == 'n'
  end
end

# Player class to question player
class Player
  def make_guess
    puts 'Enter a letter guess:'
    gets.chomp.downcase
  end
end

# Board class to display and keep updated
class Board
  attr_reader :word, :guesses_left

  def initialize
    @word = choose_word.strip.chars
    @board = Array.new(@word.length, '_')
  end

  def choose_word
    word_array = []
    words = File.open('./google-10000-english-no-swears.txt')
    words.each do |word|
      word_array << word if word.length > 5 && word.length <= 12
    end
    word_array.sample
  end

  def secret_word
    @word.join
  end

  def show
    puts @board.join(' ')
  end

  def update(letter)
    @word.each_with_index do |char, idx|
      @board[idx] = letter if char == letter
    end
  end

  def word_complete?
    !@board.include?('_')
  end

  def game_over?(guesses_left)
    @guesses_left = guesses_left
    puts "Game Over! The secret word was #{secret_word}" if guesses_left <= 0
    play_again if guesses_left <= 0
  end

  def play_again
    puts 'Would you like to play again? y/n'
    answer = gets.chomp.downcase
    Game.new if answer == 'y'
    exit if answer == 'n'
  end
end

Game.new
