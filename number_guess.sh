#!/bin/bash

# Number Guessing Game Script
# Database: number_guess
# User: freecodecamp

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

# Get username
echo "Enter your username:"
read USERNAME

# Check username length (max 22 characters)
USERNAME_LENGTH=${#USERNAME}
if [[ $USERNAME_LENGTH -gt 22 ]]; then
  USERNAME=$(echo "$USERNAME" | cut -c1-22)
fi

# Check if user exists in database
USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME';")

if [[ -z $USER_DATA ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  
  # Insert new user into database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, 0);")
else
  # Returning user
  echo "$USER_DATA" | while IFS="|" read GAMES_PLAYED BEST_GAME; do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# Start the game
echo "Guess the secret number between 1 and 1000:"

while true; do
  read GUESS
  
  # Check if input is an integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi
  
  # Increment guess counter
  ((NUMBER_OF_GUESSES++))
  
  # Check the guess
  if [[ $GUESS -eq $SECRET_NUMBER ]]; then
    # Correct guess
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    
    # Update database with game result
    if [[ -z $USER_DATA ]]; then
      # First game for new user
      UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=1, best_game=$NUMBER_OF_GUESSES WHERE username='$USERNAME';")
    else
      # Returning user - update games played and check if this is best game
      echo "$USER_DATA" | while IFS="|" read GAMES_PLAYED BEST_GAME; do
        NEW_GAMES_PLAYED=$((GAMES_PLAYED + 1))
        
        # Update best game if this is better, or if it's the first game (best_game is 0)
        if [[ $BEST_GAME -eq 0 ]] || [[ $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
          NEW_BEST_GAME=$NUMBER_OF_GUESSES
        else
          NEW_BEST_GAME=$BEST_GAME
        fi
        
        UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED, best_game=$NEW_BEST_GAME WHERE username='$USERNAME';")
      done
    fi
    
    break
    
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done
