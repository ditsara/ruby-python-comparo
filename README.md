# Ruby vs Python Language Comparison

*Task*: Develop a CLI client to list Gitlab issues.

- Read Gitlab auth token from environment

- Parse arguments for assignee usernames (multiple) and milestone (single)

- Set the following defaults:
  - User: [my username], from environment
  - Milestone: open milestone with soonest due date

- Call Gitlab API
- Display results with issue title, tags, and assignee(s)
