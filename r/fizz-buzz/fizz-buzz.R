fz_bz <- c("Fizz" = 3, "Buzz" = 5)

fizz_buzz <- function(n) {
  output <- c()
  while (n) {
    fact <- paste(names(fz_bz[n %% fz_bz == 0]), collapse = " ")

    if (nchar(fact) != 0)
      output <- c(fact, output)
    else
      output <- c(as.character(n), output)

    n <- n - 1
  }
  output
}
