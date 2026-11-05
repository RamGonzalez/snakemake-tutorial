# Grafica uno o varios UMAP (un panel por cada n_neighbors)
#
# Uso:
#   Rscript scripts/plot_umap.R <salida.png> <nombres_a_resaltar> <umap1.tsv> [umap2.tsv ...]
#
# <nombres_a_resaltar> es una lista separada por comas, por ejemplo Pikachu,Eevee

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(ggrepel)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Uso: Rscript plot_umap.R <salida.png> <nombres_a_resaltar> <umap1.tsv> [umap2.tsv ...]")
}
salida    <- args[1]
resaltar  <- strsplit(args[2], ",")[[1]]
archivos  <- args[-(1:2)]

# juntamos todos los UMAP en una sola tabla
umap.df <- bind_rows(lapply(archivos, read.delim, stringsAsFactors = FALSE))

# un panel por n_neighbors, ordenados de menor a mayor
umap.df <- umap.df |>
  mutate(panel = factor(paste("n_neighbors =", n_neighbors),
                        levels = paste("n_neighbors =", sort(unique(n_neighbors)))))

# crea tu escala de colores
miscol <- c("Grass" = "green",
            "Water" = "blue",
            "Fire" = "red",
            "Normal" = "gray",
            "Electric" = "yellow")

umap.p <- ggplot(data = umap.df,
                 mapping = aes(x = u1, y = u2, fill = Type)) +
  geom_point(size = 3, shape = 21) +
  scale_fill_manual(values = miscol) +
  geom_label_repel(data = filter(umap.df, Starter %in% resaltar),
                   mapping = aes(label = Starter),
                   show.legend = FALSE) +
  facet_wrap(~ panel, scales = "free") +
  theme_classic(base_size = 16)

ggsave(filename = salida, plot = umap.p,
       width = 4.5 * length(archivos), height = 4.5, dpi = 150)

message("Figura guardada en ", salida)
