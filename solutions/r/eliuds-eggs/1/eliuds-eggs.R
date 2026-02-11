convert_to_binary <- function(n) {
  binary <- c()
  while (n > 0) {
    binary <- c(binary, as.character(n %% 2))
    n <- as.integer(n / 2)
  }
  paste0(rev(binary), collapse = "")
}

egg_count <- function(display_value) {
  binary <- convert_to_binary(display_value)
  sum(unlist(gregexpr("1", binary)) > 0)
}
