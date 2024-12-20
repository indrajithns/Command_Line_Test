# Command Line Quiz Application

A command-line quiz application built with Bash that allows users to sign up, sign in, take quizzes, and view test results. The project is designed to manage users, log activities, and evaluate quiz performances interactively. A comprehensive and interactive quiz application implemented in Bash, offering user authentication, quiz management, and real-time results evaluation. This lightweight terminal-based program is ideal for educational and practice purposes.

---

## Features

- **User Management**: 
  - Sign-up with username and password validation.
  - Sign-in with secure password verification.
  - Prevent duplicate usernames.

- **Quiz Functionality**:
  - Questions are loaded from a configurable `question_bank.txt`.
  - Supports multiple-choice questions with options (a, b, c, d).
  - Timed answers with a default 10 seconds for each question.

- **Activity Logging**:
  - Logs user actions such as sign-ups, sign-ins, test completions, and result views.
  - Stores logs in `test_activity.log`.

- **Result Evaluation**:
  - Records user answers in a dedicated file.
  - Compares user answers with correct answers from `correct_answers.txt`.
  - Displays results in a formatted table.

---

## Project Directory Structure

```plaintext
.
├── users.csv               # Stores usernames of registered users
├── passwords.csv           # Stores usernames and their hashed passwords
├── test_activity.log       # Logs user activities with timestamps
├── question_bank.txt       # Contains quiz questions and options
├── correct_answers.txt     # Contains the correct answers for each question
├── TestData/               # Directory for storing answer files
└── script.sh               # Main script to run the application
```

---

## Setup and Usage

1. **Prepare Question and Answer Files**:
   - Create `question_bank.txt`:
     ```
     Question1,Option1,Option2,Option3,Option4
     Question2,Option1,Option2,Option3,Option4
     ```
   - Create `correct_answers.txt`:
     ```
     a
     b
     ```

2. **Run the Application**:
   ```bash
   bash script.sh
   ```

3. **Navigate the Menus**:
   - **Sign-Up**: Create a new user.
   - **Sign-In**: Log in with your credentials.
   - **Take Test**: Answer quiz questions.
   - **View Results**: See your test performance.

---

## Code Walkthrough

### File paths
The following are the paths used for data storage:
```bash
USER_FILE="users.csv"         # File to store usernames
PASSWORD_FILE="passwords.csv" # File to store username-password pairs
LOG_FILE="test_activity.log"  # Log file for activities
QUESTION_BANK="question_bank.txt" # File containing questions
CORRECT_ANSWERS="correct_answers.txt" # File containing correct answers
PROJECT_DIR="TestData"        # Directory for storing test data
```

### Core Functions

#### `log_activity`
Logs activity with a timestamp to `test_activity.log`. For example:
```bash
log_activity "New User $username Signed Up Successfully"
```

#### `create_answer_file`
Creates a file to store user answers during a test. The file is named based on the username and timestamp:
```bash
ANSWER_FILE="$PROJECT_DIR/answer_file_${username}_${datetime}.csv"
```

#### `sign_up`
Handles user registration with validation:
- Username must be alphanumeric.
- Password must have a minimum of 8 characters, with at least one number and one symbol.

#### `sign_in`
Handles user login:
- Verifies the username exists.
- Matches the username-password combination.

#### `take_test`
Administers the quiz:
- Loads questions from `question_bank.txt`.
- Records user answers in `answer_file`.
- Compares answers with `correct_answers.txt`.

#### `view_test`
Displays test results in a formatted table:
- Reads user answers from the answer file.
- Compares with correct answers to show results.

#### Menus
- **Main Menu**: Sign-In, Sign-Up, or Exit.
- **Test Menu**: Take Test, View Results, or Logout.

---

## Example Question and Answer Files

### `question_bank.txt`
```
What is the capital of France?,Paris,London,Berlin,Madrid
What is 2 + 2?,3,4,5,6
```

### `correct_answers.txt`
```
a
b
```

---

## Customization

- Change the number of questions by modifying:
  ```bash
  total_questions=10
  ```
- Update `question_bank.txt` and `correct_answers.txt` for new quizzes.

---

## Logging

All activities are logged in `test_activity.log` with timestamps, providing a history of user actions for auditing.

---
