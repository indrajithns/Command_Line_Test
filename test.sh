#!/bin/bash

#Name: Indrajith N S
#Date: 25-October-2024
#Description: The Mini Quiz Application




# File paths
USER_FILE="users.csv"
PASSWORD_FILE="passwords.csv"
LOG_FILE="test_activity.log"
QUESTION_BANK="question_bank.txt"
CORRECT_ANSWERS="correct_answers.txt"
PROJECT_DIR="TestData"
ANSWER_FILE=""
username=""
score=0
total_questions=10

# Function to log activity with timestamp
log_activity() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to create answer CSV file and backup if it exists
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

# User sign-up
sign_up() {
    echo "Sign-Up"
    read -p "Enter a UserName (Alphanumeric Only): " username

    if [[ ! "$username" =~ ^[a-zA-Z0-9]+$ ]]; then
        echo "Invalid UserName! Only Alphanumeric Aharacters Are Allowed."
        log_activity "Failed Sign-Up Attempt With Invalid UserName"
        return
    fi

    if grep -q "$username" "$USER_FILE"; then
        echo "UserName Already Exists !!! Please Choose a Different UserName."
        log_activity "Failed Sign-Up Attempt, UserName Already Exists"
        return
    fi

    read -s -p "Enter a Password (min 8 characters, at least one number and symbol): " password
    echo

    if [[ ${#password} -lt 8 || ! "$password" =~ [0-9] || ! "$password" =~ [^a-zA-Z0-9] ]]; then
        echo "Password Must Be At Least 8 Characters Long With At Least One Number And One Symbol."
        log_activity "Failed Sign-Up Attempt With Weak Password"
        return
    fi

    read -s -p "Re-Enter Password: " password_confirm
    echo

    if [ "$password" != "$password_confirm" ]; then
        echo "Passwords Do Not Match!"
        log_activity "Failed Sign-Up Attempt, Passwords Did Not Match"
        return
    fi

    echo "$username" >> "$USER_FILE"
    echo "$username,$password" >> "$PASSWORD_FILE"
    log_activity "New User $username Signed Up Successfully"
    echo "Sign-Up Successful!"
}

# User sign-in
sign_in() {
    echo "Sign-In"
    read -p "Enter Your UserName: " username
    username=$(echo "$username" | xargs)  # Trim spaces from username

    if ! grep -q "^$username$" "$USER_FILE"; then
        echo "UserName Does Not Exist !!! Please Sign-Up First."
        log_activity "Failed Sign-In Attempt, UserName Not Found"
        return 1
    fi

    read -s -p "Enter Your Password: " password
    echo

    # Check if the username and password combination exists
    if ! grep -q "^$username,$password$" "$PASSWORD_FILE"; then
        echo "Incorrect Password!"
        log_activity "Failed Sign-In Attempt With Incorrect Password"
        return 1
    fi

    log_activity "User $username Signed-In Successfully"
    echo "Sign-In Successful!"
    return 0
}

# Function to display and take the test
take_test() {
    create_answer_file
    score=0

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

    mapfile -t questions < "$QUESTION_BANK"
    mapfile -t answers < "$CORRECT_ANSWERS"

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

        timer=10
        countdown() {
            while [ $timer -gt 0 ]; do
                echo -n -e "\rYou Have $timer Seconds To Answer. Select An Option (a - d): \c"
                sleep 1
                ((timer--))
            done

            answer="Invalid"
            echo "$question,$answer,Invalid,Invalid" >> "$ANSWER_FILE"
        }
        
        countdown &  
        timer_pid=$!

        read -t 10 answer
        kill $timer_pid 2>/dev/null
        wait $timer_pid 2>/dev/null

        echo -ne "\r                                                        \n"

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

