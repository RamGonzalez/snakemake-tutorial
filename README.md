# Taller de Snakemake

Sesión 9 de *Viernes de Bioinformática 2026*: introducción a Snakemake. Partimos del script `umap-pokemon.R` de la sesión de R y lo convertimos en un flujo de trabajo.

## Para seguir la práctica

1. Descarga este repositorio:

   ```bash
   git clone https://github.com/RamGonzalez/snakemake-tutorial.git
   cd snakemake-tutorial/practica
   ```

   (o **Code → Download ZIP** y entra a la carpeta `practica/`)

2. Crea y activa el entorno de conda:

   ```bash
   conda env create -f environment.yml
   conda activate practica-smk
   ```

3. Abre la guía y sigue los pasos: **[guia/GUIA.md](guia/GUIA.md)**

## Contenido

| Carpeta | Qué hay |
|---|---|
| [guia/](guia/GUIA.md) | La guía paso a paso de la práctica (en español) |
| [practica/](practica/) | Tu carpeta de trabajo: datos, scripts de R y `environment.yml`. Aquí escribes tu `snakefile` |
| [soluciones/](soluciones/) | El `snakefile` de cada paso, por si te pierdes: `cp ../soluciones/paso3/snakefile .` |
| [slides/](slides/) | Las diapositivas de la sesión (`snakemake_sesion9.pptx`) |

## ¿Dudas o errores?

Abre un [Issue](https://github.com/RamGonzalez/snakemake-tutorial/issues/new) con el error completo (copiado, no captura), el paso en el que estabas y la salida de `snakemake --version`.

Plan del curso (para quien imparte): [PLAN.md](PLAN.md).
