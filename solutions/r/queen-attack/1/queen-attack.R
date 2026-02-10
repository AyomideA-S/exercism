files <- c("a" = 0, "b" = 1, "c" = 2, "d" = 3,
           "e" = 4, "f" = 5, "g" = 6, "h" = 7)

create <- function(row, col) {
  if (row < 0 || row > 7 || col < 0 || col > 7) {
    stop("Invalid position!")
  }
  list(names(files[col + 1]), 8 - row)
}

can_attack <- function(queen1, queen2) {
  # Check if they are on the same file / same rank / diagnoal to one another
  if (queen1[[1]] == queen2[[1]] || queen1[[2]] == queen2[[2]] ||
        abs(files[queen1[[1]]] - files[queen2[[1]]]) ==
          abs(queen1[[2]] - queen2[[2]]))
    TRUE
  else
    FALSE
}
