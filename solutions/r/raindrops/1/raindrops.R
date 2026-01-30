raindrops <- function(number) {
  result <- ""

  if (number %% 3 != 0 && number %% 5 != 0 && number %% 7 != 0) {
    return(as.character(number))
  }

  if (number %% 3 == 0) {
    result <- "Pling"
  }
  if (number %% 5 == 0) {
    result <- paste(result, "Plang", sep = "")
  }
  if (number %% 7 == 0) {
    result <- paste(result, "Plong", sep = "")
  }

  result
}
