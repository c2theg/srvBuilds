#!/usr/bin/env python3
#  Copyright © 2026 Christopher Gray.  All Rights Reserved.  Proprietary and Confidential.  -  The reproduction, adaptation, distribution, display, or transmission of the content is strictly prohibited, unless authorized by Christopher Gray. All other company & product names may be trademarks of the respective companies with which they are associated.
#--------------------------------------
# Version:  0.0.1
# Last Updated:  1/31/2026
#--------------------------------------
import ollama

def test_connection():
    try:
        # This connects to localhost:11434 by default
        response = ollama.chat(model='llama3.2', messages=[
            {
                'role': 'user',
                'content': 'You are an expert software engineer assistant specializing in Python, and secure coding practices. Your goal is to provide concise, runnable code solutions with minimal explanation, focusing on efficiency and readability. \
Constraints: \
Security: Never include API keys, passwords, or hardcoded credentials. Sanitize all inputs to prevent SQL injection or XSS. \
Best Practices: Use modern syntax (e.g., ES6+, Python 3.13+), type hinting, and follow SOLID principles. \
Output Format: Provide code in markdown blocks with language identifiers. If explaining code, use bullet points for clarity. \
Error Handling: Include necessary try-catch blocks and error handling. \
If a request is ambiguous, ask clarifying questions before generating code. Do not make up non-existent libraries. \
Goal: Output a one-sentence greeting for an automation script.',
            },
        ])
        print("--- API Response ---")
        print(response['message']['content'])
    except Exception as e:
        print(f"Connection failed: {e}")

if __name__ == "__main__":
    test_connection()
