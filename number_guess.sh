#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

echo "Enter your username:"
read USERNAME

USERNAME_LENGTH=${#USERNAME}
if [[ $USERNAME_LENGTH -gt 22 ]]; then
  USERNAME=$(echo "$USERNAME" | cut -c1-22)
fi

USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME';")

if [[ -z $USER_DATA ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, 0);")
else
  echo "$USER_DATA" | while IFS="|" read GAMES_PLAYED BEST_GAME; do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

echo "Guess the secret number between 1 and 1000:"

while true; do
  read GUESS
  
  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi
  
  ((NUMBER_OF_GUESSES++))
  
  if [[ $GUESS -eq $SECRET_NUMBER ]]; then
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    
    if [[ -z $USER_DATA ]]; then
      UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=1, best_game=$NUMBER_OF_GUESSES WHERE username='$USERNAME';")
    else
      echo "$USER_DATA" | while IFS="|" read GAMES_PLAYED BEST_GAME; do
        NEW_GAMES_PLAYED=$((GAMES_PLAYED + 1))
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
