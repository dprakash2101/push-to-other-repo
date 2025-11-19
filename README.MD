# Push To Other Repo

This GitHub Action syncs a directory from the current repository into another GitHub repository and branch.  
It clones the destination repository, copies the specified directory into it, commits any detected changes, and performs a safe push without using force-push.

---

## Inputs

| Name | Required | Description |
|------|----------|-------------|
| `source_directory` | Yes | Path to the directory inside the current repository that should be synced. |
| `destination_repository` | Yes | Destination GitHub repository in the format `owner/repo`. |
| `target_branch` | Yes | Branch in the destination repository to update. If the branch does not exist, it will be created. |
| `user_email` | Yes | Email address used for the commit in the destination repository. |
| `user_name` | Yes | Git user name for commits. |
| `api_token` | Yes | GitHub Personal Access Token with permission to push to the destination repository. |

---

## Example Workflow

```yaml
name: Push to other repo

on:
  push:
    branches: ["main"]

jobs:
  sync:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Push folder to another repository
        uses: dprakash2101/push-to-other-repo@latest
        with:
          source_directory: "dist"
          destination_repository: "my-org/another-repo"
          target_branch: "main"
          user_email: "automation@example.com"
          user_name: "Sync Bot"
          api_token: ${{ secrets.REPO_PUSH_TOKEN }}
````

---

## How the Action Works

1. The action validates all required inputs.
2. Git is configured using the provided user name and email.
3. The destination repository is cloned using the provided token.
4. The action attempts to check out the target branch.

   * If it does not exist, the branch is created.
5. The specified directory is synchronized into the destination repository using `rsync`, including file additions, updates, and deletions.
6. If changes are found, a commit is created.
7. A fast-forward push is attempted.

   * If it cannot fast-forward, the action performs a pull with rebase and retries the push.
8. If the rebase cannot be completed cleanly, the action stops without force-pushing.

---

## Token Requirements

The value passed to `api_token` must be a GitHub Personal Access Token with at least:

```
repo
```

permissions (or `contents: write` for public repositories).

---

## Notes

* The action never performs a force-push.
* If a rebase conflict occurs, the workflow will fail and the destination repository will not be modified.
* Only the content of `source_directory` is synchronized; nothing else from the current repository is copied.

---

## Author

This action is created and maintained by [Devi Prakash](https://github.com/dprakash2101).

---

## License

This project is licensed under the **MIT License**.  
See the [LICENSE](LICENSE) file for details.
