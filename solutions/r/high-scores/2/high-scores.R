scores_list <- function(scores) {
  scores
}

latest <- function(scores) {
  tail(scores, n = 1)
}

personal_best <- function(scores) {
  max(scores)
}

personal_top_three <- function(scores) {
  sorted <- scores[order(scores, na.last = TRUE, decreasing = TRUE)]
  head(sorted, 3)
}
