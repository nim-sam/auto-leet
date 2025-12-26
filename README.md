# AutoLeet

AutoLeet is a command-line tool entirely written in V that automatically synchronizes your accepted LeetCode solutions to a GitHub repository, turning your problem-solving history into a clean, organized, and continuously updated portfolio. Designed for developers who want to showcase consistency, language versatility, and algorithmic practice, AutoLeet removes the manual work of copying solutions, writing problem descriptions, and organizing repositories. Once configured, a single command keeps your GitHub repo in sync with your LeetCode progress.

## Required Accounts, Tokens, and Repository (Manual Step)

Before running AutoLeet, you must manually gather all required credentials and create a GitHub repository.
AutoLeet does not create accounts, generate tokens, or log in on your behalf.

> [!WARNING]
> Make sure you complete all steps below before proceeding to configuration.

### What You Need to Prepare

#### 1. LeetCode authentication cookies (required)

1. Log in to _leetcode.com_
2. Open DevTools (F12)
3. Go to Application → Cookies
4. Copy the following values: `csrftoken` \& `LEETCODE_SESSION`

#### 2. GitHub Personal Access Token (required)

1. Go to GitHub → Settings → Developer Settings → **Personal Access Tokens**
2. Create a new personal access token (PAT)
3. Enable the repo scope
4. Copy the generated PAT

#### 3. A GitHub repository

1. Create an empty GitHub repository where your solutions will be pushed
2. Copy the repository URL (HTTPS)

## Quick Setup
Once you complete the steps mentioned above, you can start by setting up your LeetCode and GitHub credentials directly on the CLI.

   ```bash
   # Move to a folder in your PATH (optional)
   mv bin/autolt /usr/local/bin/  # Linux/macOS
   # or keep in bin/ and run with ./autolt
   
   # Configure your tokens
   autolt config csrftoken "your_csrf_token"
   autolt config leetcode_session "your_session_token"
   autolt config remote_repo "https://github.com/yourname/your-repo"
   autolt config pat "your_github_peronal_access_token"
   ```

## Fetch and push your submissions to GitHub

   ```bash
   autolt sync
   ```

## What It Creates

Your GitHub repo will store your submissions in organized folders:

```
0001 - Two Sum/
├── README.md                   # Problem description
├── two-sum-1640995200.py       # Your solution
└── two-sum-1641081600.cpp      # Another solution
0002 - Add Two Numbers/
├── README.md
└── add-two-numbers-1641254400.java
...
```
## Commands

```bash
autolt sync                             # Sync all submissions
autolt config                           # Show current settings
autolt config <key> <value>             # Update a setting
autolt help                             # Show all commands
```

## Notes

- Cookies expire - refresh and update if sync stops working
- Supports 40+ languages automatically
- All data stored locally in `~/.config/autolt/user.json`
