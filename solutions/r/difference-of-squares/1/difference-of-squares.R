# this is a stub function that takes a natural_number
# and should return the difference-of-squares as described
# in the README.md
difference_of_squares <- function(natural_number) {
  squared_sum <- 0
  sum_squares <- 0
  for (i in 1:natural_number) {
    squared_sum <- squared_sum + i
    sum_squares <- sum_squares + i**2
  }
  (squared_sum^2) - sum_squares
}
