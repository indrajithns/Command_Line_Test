#!/bin/bash

# ====================================================================================
# Description : Mini Quiz Application
#
# This script implements a command-line quiz application. It allows users to:
# - Sign up with a username and password.
# - Sign in to their account.
# - Take a quiz with a time limit for each question.
# - View test results showing their answers, correct answers, and their score.
# - Log their activities, such as sign-in attempts and test completion.
#
# The application uses files to manage user accounts, passwords, questions, 
# correct answers, and user responses. It includes features for secure password 
# validation, data storage, and activity logging.
#
# File Structure:
# - `users.csv`            : Stores registered usernames.
# - `passwords.csv`        : Stores usernames and hashed passwords.
# - `test_activity.log`    : Logs user activities (sign-ups, sign-ins, test completions, etc.).
# - `question_bank.txt`    : Contains quiz questions with options in a CSV format.
# - `correct_answers.txt`  : Stores correct answers for the questions.
# - `TestData/`            : Directory for storing user response files.
# ====================================================================================



# File paths
# Define constants for file paths used in the script, such as user data, passwords, logs, and test files.
USER_FILE="users.csv"
PASSWORD_FILE="passwords.csv"
LOG_FILE="test_activity.log"
QUESTION_BANK="question_bank.txt"
CORRECT_ANSWERS="correct_answers.txt"
PROJECT_DIR="TestData" # Directory to store test-related data
ANSWER_FILE=""         # File to store user answers for the current test session
username=""            # Holds the current user's username
score=0                # Tracks the user's score during the test
total_questions=10     # Maximum number of questions in a test

# Function to log activity with a timestamp
# Logs user actions like sign-ups, sign-ins, and test completions.
log_activity() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to create a file to store user answers during the test
# If a previous answer file exists, it creates a backup.
create_answer_file() {
    mkdir -p "$PROJECT_DIR"
    # Get the current date and time in the format YYYYMMDD_HHMMSS
    datetime=$(date '+%Y%m%d_%H%M%S')
    ANSWER_FILE="$PROJECT_DIR/answer_file_${username}_${datetime}.csv"
    if [ -f "$ANSWER_FILE" ]; then
        mv "$ANSWER_FILE" "${ANSWER_FILE}_backup_$(date '+%Y%m%d%H%M%S')"
    fi
    touch "$ANSWER_FILE"
}

# Function to handle user sign-up
# Ensures the username is alphanumeric and passwords meet complexity requirements.
sign_up() {
    echo "Sign-Up"
    read -p "Enter a UserName (Alphanumeric Only): " username

    # Check if the username contains only alphanumeric characters
    if [[ ! "$username" =~ ^[a-zA-Z0-9]+$ ]]; then
        echo "Invalid UserName! Only Alphanumeric Characters Are Allowed."
        log_activity "Failed Sign-Up Attempt With Invalid UserName"
        return
    fi

    # Verify if the username already exists in the user file
    if grep -q "$username" "$USER_FILE"; then
        echo "UserName Already Exists !!! Please Choose a Different UserName."
        log_activity "Failed Sign-Up Attempt, UserName Already Exists"
        return
    fi

    # Prompt for password and check complexity
    read -s -p "Enter a Password (min 8 characters, at least one number and symbol): " password
    echo

    # Validate password requirements
    if [[ ${#password} -lt 8 || ! "$password" =~ [0-9] || ! "$password" =~ [^a-zA-Z0-9] ]]; then
        echo "Password Must Be At Least 8 Characters Long With At Least One Number And One Symbol."
        log_activity "Failed Sign-Up Attempt With Weak Password"
        return
    fi

    # Confirm password and check for a match
    read -s -p "Re-Enter Password: " password_confirm
    echo

    if [ "$password" != "$password_confirm" ]; then
        echo "Passwords Do Not Match!"
        log_activity "Failed Sign-Up Attempt, Passwords Did Not Match"
        return
    fi

    # Save the username and password
    echo "$username" >> "$USER_FILE"
    echo "$username,$password" >> "$PASSWORD_FILE"
    log_activity "New User $username Signed Up Successfully"
    echo "Sign-Up Successful!"
}

# Function to handle user sign-in
# Verifies the username exists and matches the password.
sign_in() {
    echo "Sign-In"
    read -p "Enter Your UserName: " username
    username=$(echo "$username" | xargs)  # Trim spaces from username

    # Check if the username exists in the user file
    if ! grep -q "^$username$" "$USER_FILE"; then
        echo "UserName Does Not Exist !!! Please Sign-Up First."
        log_activity "Failed Sign-In Attempt, UserName Not Found"
        return 1
    fi

    # Prompt for the password
    read -s -p "Enter Your Password: " password
    echo

    # Verify username and password combination
    if ! grep -q "^$username,$password$" "$PASSWORD_FILE"; then
        echo "Incorrect Password!"
        log_activity "Failed Sign-In Attempt With Incorrect Password"
        return 1
    fi

    log_activity "User $username Signed-In Successfully"
    echo "Sign-In Successful!"
    return 0
}

# Function to take the test
# Displays questions, records answers, and evaluates results.
take_test() {
    create_answer_file
    score=0

    # Validate existence of required files
    if [ ! -f "$QUESTION_BANK" ]; then
        echo "Error: Question Bank File Not Found!"
        log_activity "Test Aborted, Question Bank File Missing"
        return
    fi

    if [ ! -f "$CORRECT_ANSWERS" ]; then
        echo "Error: Correct Answers File Not Found!"
        log_activity "Test Aborted, Correct Answers File Missing"
        return
    fi

    echo "Starting The Test. You Will Answer Each Question One By One."

    mapfile -t questions < "$QUESTION_BANK" # Read questions into an array
    mapfile -t answers < "$CORRECT_ANSWERS" # Read correct answers into an array

    # Iterate over questions
    for question_count in $(seq 0 $((total_questions - 1))); do
        if [ $question_count -ge ${#questions[@]} ]; then
            break
        fi

        IFS=',' read -r question option1 option2 option3 option4 <<< "${questions[$question_count]}"
        
        echo "$((question_count + 1)). $question"
        echo "a) $option1"
        echo "b) $option2"
        echo "c) $option3"
        echo "d) $option4"

        timer=10 # Initialize a 10-second countdown for each question
        countdown() {
            while [ $timer -gt 0 ]; do
                echo -n -e "\rYou Have $timer Seconds To Answer. Select An Option (a - d): \c"
                sleep 1
                ((timer--))
            done

            answer="Invalid" # Default answer if the user doesn't respond in time
            echo "$question,$answer,Invalid,Invalid" >> "$ANSWER_FILE"
        }
        
        countdown & # Start the countdown in the background
        timer_pid=$!

        read -t 10 answer # Wait for user input for 10 seconds
        kill $timer_pid 2>/dev/null # Terminate countdown if input is provided
        wait $timer_pid 2>/dev/null

        echo -ne "\r                                                        \n" # Clear countdown prompt

        if [[ -z "$answer" ]]; then
            echo "You Did Not Answer In Time. Moving To The Next Question..."
            echo "-----------------------------------------------------------"
            continue
        else
            if [[ ! "$answer" =~ ^[a-d]$ ]]; then
                echo "Invalid Input, Moving To The Next Question..."
                answer="Invalid"
                echo "$question,$answer,Invalid,Invalid" >> "$ANSWER_FILE"
            else
                correct_answer=${answers[$question_count]}
                if [ "$answer" == "$correct_answer" ]; then
                    score=$((score + 1))
                    echo "$question,$answer,$correct_answer,Correct" >> "$ANSWER_FILE"
                else
                    echo "$question,$answer,$correct_answer,Not Correct" >> "$ANSWER_FILE"
                fi
            fi
        fi

        echo "-----------------------------------------------------------"
    done

    log_activity "User $username Completed Test With $((question_count)) Questions Answered"
    echo "Test Completed... Your Answers Have Been Saved In $ANSWER_FILE."
}

# View test results
# Displays a summary of the user's answers, correct answers, and the result.
view_test() {
    if [ ! -f "$CORRECT_ANSWERS" ]; then
        echo "Error: Correct Answers File Not Found !!!"
        log_activity "Failed To View Test, Correct Answers File Missing"
        return
    fi

    echo "-------------------------------------------------------------------------------------------"
    printf "%-45s %-16s %-15s %-10s\n" "Question" "Your Answer" "Correct Answer" "Result"
    echo "-------------------------------------------------------------------------------------------"

    mapfile -t questions < "$QUESTION_BANK"
    mapfile -t correct_answers < "$CORRECT_ANSWERS"
    declare -A user_answers
    correct_count=0
    total_questions=${#questions[@]}

    if [ -f "$ANSWER_FILE" ]; then
        while IFS=',' read -r question user_answer correct result; do
            user_answers["$question"]="$user_answer"
        done < "$ANSWER_FILE"
    fi

    for i in "${!questions[@]}"; do
        IFS=',' read -r question option1 option2 option3 option4 <<< "${questions[i]}"
        correct_answer=${correct_answers[i]}
        user_answer=${user_answers[$question]:-"Not Answered"}
        result="Not Correct"  # Default result if the answer is wrong

        # Determine result based on the user answer
        if [[ "$user_answer" == "$correct_answer" ]]; then
            result="Correct"
            ((correct_count++))
        fi

        printf "%-45s %-16s %-15s %-10s\n" "$question" "$user_answer" "$correct_answer" "$result"
    done

    echo "-------------------------------------------------------------------------------------------"
    echo "Your Test Results: $correct_count/$total_questions"
    echo "-------------------------------------------------------------------------------------------"
    log_activity "User Viewed Their Test Results With Correct Answer Information"
}

# Main menu
# Provides options for user sign-in, sign-up, or exiting the application.
main_menu() {
    while true; do
        echo "Welcome To The Quiz Application"
        echo "1. Sign-In"
        echo "2. Sign-Up"
        echo "3. Exit"
        read -p "Choose An Option: " option

        case $option in
            1)
                sign_in
                if [ $? -eq 0 ]; then
                    test_menu
                fi
                ;;
            2)
                sign_up
                ;;
            3)
                echo "Exiting Application..."
                log_activity "User Exited The Application"
                exit 0
                ;;
            *)
                echo "Invalid Option. Please Try Again."
                ;;
        esac
    done
}

# Test menu
# Provides options for taking the test, viewing results, or logging out.
test_menu() {
    while true; do
        echo "1. Take Test"
        echo "2. View Test Results"
        echo "3. Logout"
        read -p "Choose an option: " option

        case $option in
            1)
                take_test
                ;;
            2)
                view_test
                ;;
            3)
                echo "Logging Out..."
                log_activity "User $username Logged Out"
                return
                ;;
            *)
                echo "Invalid Option. Please Try Again."
                ;;
        esac
    done
}

# Run the main menu
main_menu


