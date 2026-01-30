sounds <- c("Pling" = 3, "Plang" = 5, "Plong" = 7)

raindrops <- function(number) {
  result <- paste(names(sounds[number %% sounds == 0]), collapse = "")
  if (nchar(result) != 0) result else as.character(number)
}
