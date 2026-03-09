#!/usr/bin/env nu

# Delete branches on origin that are fully contained in upstream
def main [
  --fetch
  --delete # Actually delete branches (default is dry-run)
] {
  print "Fetching from origin and upstream..."
  if $fetch {
    git fetch origin --prune
    git fetch upstream --prune
  }
  print $"\nChecking branches on origin against upstream...\n"

  # Get all remote branches on origin
  let branches = (
    git branch -r
    | lines
    | where {|it| $it =~ "origin/" and $it !~ "HEAD" }
    | str trim
    | str replace "origin/" ""
    | where {|it| $it != "main" and $it != "master" }
  )

  let to_delete = (
    $branches | where {|branch|
      # Check if branch is fully contained in upstream
      let result = (do { git merge-base --is-ancestor $"origin/($branch)" $"upstream/($branch)" } | complete)
      if $result.exit_code == 0 {
        print $"(ansi r)  [DELETE] origin/($branch)(ansi reset)"
        true
      } else {
        print $"(ansi wd)  [KEEP]   origin/($branch)(ansi reset)"
        false
      }
    }
  )

  print $"\nFound ($to_delete | length) branch\(es\) to delete."

  if ($to_delete | is-empty) {
    print "Nothing to do."
    return
  }

  if not $delete {
    print "\nDry run - no branches deleted. Pass --delete to apply"
  } else {
    print "\nDeleting branches..."
    git push origin --delete ...$to_delete
    print "\nDone!"
  }
}
