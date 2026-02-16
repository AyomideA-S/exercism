square_root <- function(number) {
  if (number < 0) stop("Domain error for negative number")
  else if (number == 1) return(1)
  lower <- 1
  upper <- number

  while (lower <= upper) {
    mid <- as.integer((upper + lower) / 2)
    if (mid^2 == number) {
      return(mid)
    } else if (mid^2 > number) {
      upper <- mid - 1
    } else {
      lower <- mid + 1
    }
  }
  mid
}
