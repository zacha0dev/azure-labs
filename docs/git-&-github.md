# Git & Github

Install GitHub CLI:
```
winget install --id GitHub.cli
```
Check GitHub CLI Version: 
```
gh --version
```
Login with GitHub CLI in the Browser: 
```
gh auth login
```
Git Setup: 
```
git config --global user.name "name"
git config --global user.email "email@email.com"
```
Git Workflow (First-Time): 
```
git init
git add .
git commit -m "initial lab scaffold"
git branch -M main
git remote add origin https://github.com/username/repo.git
git push -u origin main
```
Git Workflow (Normal): 
```
git pull
# make changes
git add .
git commit -m "commit message"
git push
```