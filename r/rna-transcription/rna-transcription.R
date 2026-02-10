rna_complements <- c("G" = "C", "C" = "G", "T" = "A", "A" = "U")

to_rna <- function(dna) {
  rna <- rna_complements[strsplit(dna, "")[[1]]]
  if (NA %in% rna) {
    stop("Invalid DNA input!")
  }
  paste(rna, collapse = "")
}
