score <- function(x, y) {
  distance <- sqrt(x^2 + y^2)
  if (distance <= 1) {
    10
  } else if (distance <= 5) {
    5
  } else if (distance <= 10) {
    1
  } else {
    0
  }
}
