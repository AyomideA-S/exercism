acronym <- function(input) {
  tla <- ""
  for (word in unlist(strsplit(input, " |-|_"))) {
    tla <- paste0(tla, toupper(substr(word, 1, 1)))
  }
  tla
}
