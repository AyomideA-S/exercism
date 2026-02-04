square <- function(n) {
  if (n < 1) stop("Number cannot be 0 or negative")
  else if (n > 64) stop("Number must not be greater than 64")
  else 2^(n - 1)
}

total <- function() {
  sum <- 0
  for (i in 1:64) sum <- sum + square(i)
  sum
}
