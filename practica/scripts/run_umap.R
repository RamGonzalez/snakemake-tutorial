# Calcula un UMAP con los valores numéricos de poke_starter.tsv
#
# Uso:
#   Rscript scripts/run_umap.R <entrada.tsv> <salida.tsv> <n_neighbors> <semilla> <min_dist>

suppressPackageStartupMessages({
  library(dplyr)
  library(uwot)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 5) {
  stop("Uso: Rscript run_umap.R <entrada.tsv> <salida.tsv> <n_neighbors> <semilla> <min_dist>")
}
entrada      <- args[1]
salida       <- args[2]
n_neighbors  <- as.integer(args[3])
semilla      <- as.integer(args[4])
min_dist     <- as.numeric(args[5])

# cargar data
pokemon.df <- read.delim(entrada, stringsAsFactors = FALSE)

# determinamos una semilla para lo random del umap
set.seed(semilla)

# obtenemos solo los valores numericos y calculamos umap ahi
# (los pasamos a double para evitar un warning de uwot con enteros)
umap_res <- pokemon.df |>
  select(where(is.numeric)) |>
  mutate(across(everything(), as.numeric)) |>
  umap(n_neighbors = n_neighbors, min_dist = min_dist,
       metric = "euclidean")

# juntamos las coordenadas umap con el dataframe original
pokemon_umap <- pokemon.df |>
  mutate(u1 = umap_res[, 1],
         u2 = umap_res[, 2],
         n_neighbors = n_neighbors)

write.table(pokemon_umap, file = salida, sep = "\t",
            quote = FALSE, row.names = FALSE)

message("UMAP listo: n_neighbors = ", n_neighbors,
        ", semilla = ", semilla, ", min_dist = ", min_dist)
