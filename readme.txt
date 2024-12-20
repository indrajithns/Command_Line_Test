Command Line Quiz Application

A terminal-based quiz application built in Bash that allows users to sign up, sign in, take quizzes, and view results. It includes user authentication, activity logging, and real-time evaluation of answers.

---

Key Features:

1. User Authentication:
   - Sign-Up: Users can register with alphanumeric usernames and complex passwords.
   - Sign-In: Users log in with their username and password.

2. Quiz Management:
   - Questions are loaded from a text file with multiple-choice options.
   - Timed responses (10 seconds per question).
   - User answers are saved to a file.

3. Activity Logging:
   - User activities (sign-ups, sign-ins, test completions) are logged with timestamps.

4. Result Evaluation:
   - Compares user responses against the correct answers.
   - Displays a summary with the user's score.

---

How to Use:

1. Prepare the quiz data in `question_bank.txt` and `correct_answers.txt`.

2. Run the application:
   bash script.sh

3. Choose from the main menu:
   - Sign-Up
   - Sign-In
   - Take Test
   - View Results

---