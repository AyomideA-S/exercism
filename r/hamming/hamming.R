# This is a stub function to take two strings
# and calculate the hamming distance
hamming <- function(strand1, strand2) {
  if (nchar(strand1) != nchar(strand2)) stop("Strands must be of equal length")
  strand1_vector <- strsplit(strand1, "")[[1]]
  strand2_vector <- strsplit(strand2, "")[[1]]
  # Loop through nitrogeneous bases & check for inequalities
  # Hamming distance (Mistakes) = Total length - Correct bases
  sum(unlist(Map(`!=`, strand1_vector, strand2_vector)))
}
