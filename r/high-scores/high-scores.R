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
  if (length(scores) >= 3) {
    scores[order(scores, na.last = TRUE, decreasing = TRUE)][1:3]
  } else {
    scores[order(scores, decreasing = TRUE)][1:length(scores)]
  }
}
