reverse <- function(text) {
  paste(rev(unlist(strsplit(text, split = ""))), collapse = "")
}
