#!/usr/bin/env bash

# Sayr Cloud Run Tool
# Offloads heavy tests, static analysis, and builds to GitHub Actions using gh CLI.

set -euo pipefail

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}          Sayr v3 Cloud Execution Tool (gh CLI)             ${NC}"
echo -e "${BLUE}============================================================${NC}"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
  echo -e "${RED}ERROR: 'gh' CLI is not installed. Please install it first.${NC}"
  exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
  echo -e "${RED}ERROR: You are not authenticated with GitHub CLI.${NC}"
  echo -e "${YELLOW}Please run 'gh auth login' to authenticate, then try again.${NC}"
  exit 1
fi

# Get current branch name
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
  echo -e "${RED}ERROR: Not on a git branch or git is not initialized.${NC}"
  exit 1
fi

# Variables for tracking state
USE_TEMP_BRANCH=false
REF_TO_RUN="$CURRENT_BRANCH"
TEMP_BRANCH_NAME="cloud-run-temp"

# Cleanup function to run on exit or interrupt
cleanup() {
  if [ "$USE_TEMP_BRANCH" = true ]; then
    echo -e "\n${YELLOW}Cleaning up: deleting remote branch '$TEMP_BRANCH_NAME'...${NC}"
    # Delete the remote branch silently
    git push origin --delete "$TEMP_BRANCH_NAME" &>/dev/null || true
    USE_TEMP_BRANCH=false
  fi
}
# Register cleanup trap
trap cleanup EXIT SIGINT SIGTERM

# Check for uncommitted changes
DIRTY_CHANGES=$(git status --porcelain)
if [ -n "$DIRTY_CHANGES" ]; then
  echo -e "${YELLOW}⚠️ You have uncommitted local changes:${NC}"
  echo "$DIRTY_CHANGES"
  echo ""
  echo -e "Since GitHub Actions runs in the cloud, it cannot see your local uncommitted changes."
  echo "Select an option to proceed:"
  echo -e "  1) ${GREEN}Run on a temporary remote branch ('$TEMP_BRANCH_NAME') with local changes${NC} (Recommended - preserves local workspace)"
  echo -e "  2) ${BLUE}Commit changes and push directly to '$CURRENT_BRANCH'${NC}"
  echo -e "  3) Cancel and exit"
  read -p "Select option (1-3): " git_opt
  
  case "$git_opt" in
    1)
      echo -e "${YELLOW}Creating temporary remote branch '$TEMP_BRANCH_NAME' with your local changes...${NC}"
      # Add all changes (including untracked files)
      git add -A
      # Commit temporarily
      git commit -m "wip: cloud-run-temp-commit [skip ci]" --no-verify > /dev/null
      # Push directly to the remote temp branch
      if ! git push origin HEAD:refs/heads/"$TEMP_BRANCH_NAME" --force; then
        echo -e "${RED}ERROR: Failed to push to remote repository. Check your connection/permissions.${NC}"
        git reset HEAD~1 > /dev/null
        exit 1
      fi
      # Reset local branch to previous state, keeping changes in the working directory
      git reset HEAD~1 > /dev/null
      USE_TEMP_BRANCH=true
      REF_TO_RUN="$TEMP_BRANCH_NAME"
      echo -e "${GREEN}✅ Local changes pushed to remote branch '$TEMP_BRANCH_NAME'. Workspace preserved.${NC}"
      ;;
    2)
      read -p "Enter commit message: " commit_msg
      if [ -z "$commit_msg" ]; then
        commit_msg="wip: cloud run commit"
      fi
      git add -A
      git commit -m "$commit_msg"
      echo -e "${YELLOW}Pushing to origin/$CURRENT_BRANCH...${NC}"
      git push origin "$CURRENT_BRANCH"
      REF_TO_RUN="$CURRENT_BRANCH"
      echo -e "${GREEN}✅ Changes pushed to origin/$CURRENT_BRANCH.${NC}"
      ;;
    *)
      echo "Operation cancelled."
      exit 0
      ;;
  esac
else
  # Check if there are local commits not pushed to origin
  LOCAL_SHA=$(git rev-parse HEAD)
  UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")
  if [ -n "$UPSTREAM" ]; then
    REMOTE_SHA=$(git rev-parse "$UPSTREAM")
    if [ "$LOCAL_SHA" != "$REMOTE_SHA" ]; then
      echo -e "${YELLOW}⚠️ Your local branch '$CURRENT_BRANCH' has commits not pushed to origin.${NC}"
      read -p "Would you like to push them to origin now? (y/n): " push_opt
      if [[ "$push_opt" =~ ^[Yy]$ ]]; then
        git push origin "$CURRENT_BRANCH"
        echo -e "${GREEN}✅ Pushed to origin/$CURRENT_BRANCH.${NC}"
      else
        echo -e "${YELLOW}⚠️ Running workflow using the last pushed commit on origin.${NC}"
      fi
    fi
  else
    echo -e "${YELLOW}⚠️ Upstream branch not set. Pushing '$CURRENT_BRANCH' to origin...${NC}"
    git push -u origin "$CURRENT_BRANCH"
  fi
fi

# Select workflow to run
echo ""
echo -e "${BLUE}Select the GitHub Actions workflow to run:${NC}"
echo "  1) Core CI (ci.yml)"
echo "     - Formatting check, build_runner code generation, strict analysis"
echo "     - Flutter unit and widget tests"
echo "     - React Admin dashboard TypeScript compile & ESLint check"
echo "  2) Test Coverage (coverage.yml)"
echo "     - Runs all tests with coverage, merges report, checks 25% gate"
echo "  3) Database & Migrations CI (database-ci.yml)"
echo "     - Verifies database migrations on Supabase CLI and Deno Edge Function tests"
echo "  4) Build Android (build-android.yml)"
echo "     - Builds release APK and App Bundle (AAB)"
echo "  5) Deploy Admin (deploy-admin.yml)"
echo "     - Builds and deploys React Admin panel to GitHub Pages"
echo "  6) Cancel"
read -p "Select option (1-6): " wf_opt

WORKFLOW=""
DOWNLOAD_ARTIFACTS=false
ARTIFACT_NAME=""
ARTIFACT_DEST=""

case "$wf_opt" in
  1) WORKFLOW="ci.yml" ;;
  2)
    WORKFLOW="coverage.yml"
    DOWNLOAD_ARTIFACTS=true
    ARTIFACT_NAME="coverage-report"
    ARTIFACT_DEST="coverage/"
    ;;
  3) WORKFLOW="database-ci.yml" ;;
  4)
    WORKFLOW="build-android.yml"
    DOWNLOAD_ARTIFACTS=true
    ARTIFACT_NAME="android-release"
    ARTIFACT_DEST="apps/mobile/build/app/outputs/"
    ;;
  5) WORKFLOW="deploy-admin.yml" ;;
  *)
    echo "Operation cancelled."
    exit 0
    ;;
esac

echo -e "\n${YELLOW}Triggering workflow '$WORKFLOW' on branch/ref '$REF_TO_RUN'...${NC}"
if ! gh workflow run "$WORKFLOW" --ref "$REF_TO_RUN"; then
  echo -e "${RED}ERROR: Failed to trigger workflow. Please check your branch name or if the workflow is active.${NC}"
  exit 1
fi

echo -e "${YELLOW}Waiting for the run to start on GitHub...${NC}"
sleep 4

# Polling loop to find the run ID
RUN_ID=""
for i in {1..15}; do
  # Search for the latest run that is queued/in_progress/waiting/completed
  RUN_ID=$(gh run list --workflow "$WORKFLOW" --branch "$REF_TO_RUN" --limit 1 --json databaseId,status -q '.[] | select(.status == "queued" or .status == "in_progress" or .status == "waiting") | .databaseId')
  if [ -n "$RUN_ID" ]; then
    break
  fi
  # Fallback to the latest run ID on this branch/workflow regardless of status
  RUN_ID=$(gh run list --workflow "$WORKFLOW" --branch "$REF_TO_RUN" --limit 1 --json databaseId -q '.[0].databaseId' || echo "")
  if [ -n "$RUN_ID" ]; then
    break
  fi
  sleep 2
done

if [ -z "$RUN_ID" ]; then
  echo -e "${RED}ERROR: Could not find the triggered run on GitHub.${NC}"
  echo -e "You can monitor the runs manually at: ${BLUE}https://github.com/wisam79/sayr/actions${NC}"
  exit 1
fi

echo -e "${GREEN}Found Run ID: $RUN_ID${NC}"
echo -e "Live URL: ${BLUE}https://github.com/wisam79/sayr/actions/runs/$RUN_ID${NC}"
echo -e "${YELLOW}Streaming execution logs (Press Ctrl+C to disconnect; workflow will keep running)...${NC}"
echo -e "${BLUE}------------------------------------------------------------${NC}"

# Disable exit on error for log streaming and checks
set +e
gh run watch "$RUN_ID"
WATCH_EXIT_CODE=$?
set -e

echo -e "\n${BLUE}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Checking final workflow run status...${NC}"

# Get final status and conclusion
STATUS=$(gh run view "$RUN_ID" --json status -q '.status')
CONCLUSION=$(gh run view "$RUN_ID" --json conclusion -q '.conclusion')

echo -e "Status: ${BLUE}$STATUS${NC}"
if [ -n "$CONCLUSION" ]; then
  echo -e "Conclusion: ${BLUE}$CONCLUSION${NC}"
fi

# Run cleanup to delete remote temp branch (if we created one) before downloading artifacts
cleanup

if [ "$CONCLUSION" = "success" ]; then
  echo -e "${GREEN}✅ Workflow completed successfully!${NC}"
  if [ "$DOWNLOAD_ARTIFACTS" = true ]; then
    echo -e "${YELLOW}Would you like to download the artifact '$ARTIFACT_NAME'? (y/n):${NC} "
    read -p "" download_opt
    if [[ "$download_opt" =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}Downloading to '$ARTIFACT_DEST'...${NC}"
      mkdir -p "$ARTIFACT_DEST"
      if gh run download "$RUN_ID" --name "$ARTIFACT_NAME" --dir "$ARTIFACT_DEST"; then
        echo -e "${GREEN}✅ Artifacts successfully downloaded to '$ARTIFACT_DEST'!${NC}"
      else
        echo -e "${RED}Failed to download artifacts. You can download them manually from the link above.${NC}"
      fi
    fi
  fi
else
  echo -e "${RED}❌ Workflow failed, was cancelled, or timed out.${NC}"
  exit 1
fi
