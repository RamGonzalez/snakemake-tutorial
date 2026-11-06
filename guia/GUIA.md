# Guía de la práctica: de un script a un flujo de trabajo con Snakemake

Sesión 9 de *Viernes de Bioinformática 2026*.

Ya conoces el script `umap-pokemon.R` de la sesión de R: un solo archivo que lo hace todo. Hoy lo dividimos en pasos y dejamos que **Snakemake** decida qué correr, en qué orden y cuándo hace falta volver a correr algo.

## Cómo usar esta guía

- En cada paso **copias y pegas** un `snakefile` completo (reemplazas todo lo que tenías). Las líneas nuevas o cambiadas están marcadas con `# NUEVO` o `# CAMBIO`.
- Antes de correr algo, **piensa qué crees que va a pasar**. Después de correrlo, **lee lo que Snakemake imprimió**. Ese es el aprendizaje.
- No hace falta escribir código. Si algo no sale, sigue adelante: **no nos vamos a detener por errores** (la sesión queda grabada). Mira la sección [Si te sale un error](#si-te-sale-un-error) o usa el truco para alcanzar al grupo:

  ```bash
  cp ../soluciones/paso3/snakefile .     # cambia el 3 por el último paso que te funcionó
  ```

- Al terminar cada paso, escribe `listo` en el chat.
- Las respuestas están ocultas en los bloques **"Respuesta"**; haz clic para verlas, pero primero intenta.

---

## Antes de empezar

**1. Descarga este repositorio** (no hay otra forma, así todos tenemos exactamente los mismos archivos):

```bash
git clone https://github.com/RamGonzalez/snakemake-tutorial.git
cd snakemake-tutorial/practica
```

Si no usas git: botón verde **Code → Download ZIP**, descomprime, y entra a la carpeta `snakemake-tutorial/practica` desde la terminal.

**2. Activa el entorno de conda** (trae Snakemake, R y los paquetes que usamos: `uwot`, `dplyr`, `ggplot2`, `ggrepel`):

```bash
conda env create -f environment.yml
conda activate practica-smk
```

Si ya tienes Snakemake y R con esos cuatro paquetes instalados (de la sesión de R), puedes usar tu instalación.

**3. Revisa que funciona:**

```bash
snakemake --version
```

Esta práctica se probó con la versión `9.27.1`. Con versiones 8 o 9 debería funcionar igual.

> **Importante:** todos los comandos de esta guía se corren **desde la carpeta `practica/`**. Si no estás seguro, escribe `pwd`: debe terminar en `practica`.

---

## Paso 0: conoce lo que hay en la carpeta

```bash
ls
head data/poke_starter.tsv
```

```
practica/
├── data/poke_starter.tsv     # los datos: 29 Pokémon iniciales y 5 puntajes de tipo
├── scripts/
│   ├── run_umap.R            # calcula un UMAP
│   └── plot_umap.R           # grafica uno o varios UMAP
├── environment.yml
└── snakefile                 # casi vacío: aquí vas a escribir tú, desde el paso 1
```

Los dos scripts de R ya están listos: son el script de la sesión de R, dividido en dos. Tú solo vas a escribir el `snakefile`, que le dice a Snakemake **qué se necesita para producir qué**.

### Los scripts de R reciben sus datos por la línea de comandos

Modificamos los scripts de la sesión de R para que, en vez de tener nombres de archivo y números escritos dentro, los reciban como **argumentos**. Así Snakemake puede llamarlos con distintos archivos y valores. Por ejemplo, `plot_umap.R` empieza así:

```r
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Uso: Rscript plot_umap.R <salida.png> <nombres_a_resaltar> <umap1.tsv> [umap2.tsv ...]")
}
salida    <- args[1]
resaltar  <- strsplit(args[2], ",")[[1]]
archivos  <- args[-(1:2)]
```

- `commandArgs(trailingOnly = TRUE)` devuelve lo que escribes después del nombre del script, como un vector de texto.
- El primer argumento es el archivo de salida, el segundo son los nombres a resaltar (separados por comas) y todo lo demás son los archivos de entrada.
- `run_umap.R` funciona igual, con cinco argumentos: `<entrada.tsv> <salida.tsv> <n_neighbors> <semilla> <min_dist>`.

No tienes que editar los scripts. Solo recuerda este patrón: en el `snakefile`, el comando de `shell:` será justo esa línea de `Rscript ...`.

Esto es lo que vamos a construir. Cada recuadro es una *regla*; las flechas son archivos:

```
                    ┌─► run_umap  nn=5  ─┐
poke_starter.tsv ───┼─► run_umap  nn=9  ─┼─► plot_umap ─► results/umap.png
        │           └─► run_umap  nn=15 ─┘
        └─► count_types ─► results/type_counts.txt
```

Ya hay un `snakefile` casi vacío en la carpeta (el nombre es exacto: sin extensión y en minúsculas). Ábrelo:

```bash
code snakefile      # abre el archivo en VS Code (o ábrelo como prefieras)
```

---

## Paso 1: nuestra primera regla (bash)

Una **regla** dice: "para producir este `output`, necesito este `input`, y lo hago con este comando".

Pega esto en tu `snakefile`:

```python
# Paso 1: nuestra primera regla (bash)

rule count_types:
    input:
        "data/poke_starter.tsv"
    output:
        "results/type_counts.txt"
    shell:
        "cut -f2 {input} | tail -n +2 | sort | uniq -c > {output}"
```

**Mira el código.** `{input}` y `{output}` se reemplazan por los archivos de arriba. El comando de `shell` es bash normal: corta la columna 2 (el tipo), quita el encabezado, ordena y cuenta.

**Antes de correr:** ¿qué crees que significa la `-n` en el siguiente comando?

```bash
snakemake -n
```

Es un *dry-run*: Snakemake **no corre nada**, solo te dice qué haría y por qué. Deberías ver algo así:

```
Job stats:
job            count
-----------  -------
count_types        1
total              1

rule count_types:
    input: data/poke_starter.tsv
    output: results/type_counts.txt
    jobid: 0
    reason: Missing output files: results/type_counts.txt
```

Ahora sí, córrelo. `-j 1` significa "usa 1 core":

```bash
snakemake -j 1
cat results/type_counts.txt
```

```
   1 Electric
   9 Fire
   9 Grass
   1 Normal
   9 Water
```

Ahora **corre `snakemake -j 1` otra vez**. ¿Qué pasa?

<details>
<summary>Respuesta</summary>

Snakemake imprime `Nothing to be done (all requested files are present and up to date)`. El archivo `results/type_counts.txt` ya existe y sus datos de entrada no han cambiado, así que no hay nada que hacer. Esa es la idea central: **Snakemake solo corre lo que hace falta.**

Otra cosa: no creaste la carpeta `results/`; Snakemake la creó sola.
</details>

**Preguntas para pensar:**
1. En el dry-run, ¿qué dice la línea `reason`? ¿Qué diría si el archivo ya existiera?
2. Nosotros nunca le dijimos a Snakemake *cuál* regla correr. ¿Cómo supo?

<details>
<summary>Respuesta</summary>

1. `Missing output files: ...` porque el archivo no existía. Si ya existiera y estuviera al día, no habría ningún job.
2. Cuando no le pides un archivo concreto, Snakemake corre la **primera regla** del archivo. En el paso 2 vamos a hacer esto explícito con una regla `all`.
</details>

✅ **Checkpoint:** escribe `listo` en el chat.

---

## Paso 2: una regla que llama a un script de R

Reemplaza todo el `snakefile` con esto:

```python
# Paso 2: una regla que llama a un script de R

rule all:                                             # NUEVO: lo que queremos obtener al final
    input:
        "results/type_counts.txt",
        "results/umap_nn9.tsv"

rule count_types:
    input:
        "data/poke_starter.tsv"
    output:
        "results/type_counts.txt"
    shell:
        "cut -f2 {input} | tail -n +2 | sort | uniq -c > {output}"

rule run_umap:                                        # NUEVO
    input:
        "data/poke_starter.tsv"
    output:
        "results/umap_nn9.tsv"
    shell:
        "Rscript scripts/run_umap.R {input} {output} 9 7 0.1"
```

Dos cosas nuevas:

- `rule all` no tiene `shell`: solo **declara qué queremos al final**. Snakemake trabaja hacia atrás: mira lo que pedimos en `all` y deduce qué reglas hacen falta.
- `run_umap` llama a `Rscript` desde `shell`. Los números `9 7 0.1` son `n_neighbors`, la semilla y `min_dist`. Por ahora están "escondidos" en el comando; en el paso 5 los arreglamos.

**Antes de correr:** ¿cuántos jobs crees que va a planear Snakemake? ¿Va a volver a correr `count_types`?

```bash
snakemake -n -p
```

`-p` (*print*) además imprime el comando de shell de cada job. Deberías ver:

```
Job stats:
job         count
--------  -------
run_umap        1
all             1
total           2

rule run_umap:
    input: data/poke_starter.tsv
    output: results/umap_nn9.tsv
    jobid: 2
    reason: Missing output files: results/umap_nn9.tsv
Shell command: Rscript scripts/run_umap.R data/poke_starter.tsv results/umap_nn9.tsv 9 7 0.1

rule all:
    input: results/type_counts.txt, results/umap_nn9.tsv
    jobid: 0
    reason: Input files updated by another job: results/umap_nn9.tsv
Shell command: None
```

(El orden de los jobs puede variar.) Ahora córrelo y mira el resultado:

```bash
snakemake -j 1
head -n 4 results/umap_nn9.tsv
```

<details>
<summary>Respuesta: ¿por qué no corrió count_types otra vez?</summary>

Porque `results/type_counts.txt` ya existe y está al día (lo creamos en el paso 1). Solo corre `run_umap`, que es la única que falta, y luego `all`, que se considera "hecha" cuando existen todos sus inputs.
</details>

**Pregunta para pensar:** el comando `Rscript scripts/run_umap.R data/poke_starter.tsv results/umap_nn9.tsv 9 7 0.1` ¿qué haría si lo corrieras a mano en la terminal? ¿Qué ventaja tiene que lo corra Snakemake?

✅ **Checkpoint:** `listo` en el chat.

---

## Paso 3: encadenar reglas

Reemplaza todo el `snakefile`:

```python
# Paso 3: encadenamos reglas (la salida de una es la entrada de otra)

rule all:
    input:
        "results/type_counts.txt",
        "results/umap.png"                            # CAMBIO: ahora pedimos la figura

rule count_types:
    input:
        "data/poke_starter.tsv"
    output:
        "results/type_counts.txt"
    shell:
        "cut -f2 {input} | tail -n +2 | sort | uniq -c > {output}"

rule run_umap:
    input:
        "data/poke_starter.tsv"
    output:
        "results/umap_nn9.tsv"
    shell:
        "Rscript scripts/run_umap.R {input} {output} 9 7 0.1"

rule plot_umap:                                       # NUEVO
    input:
        "results/umap_nn9.tsv"
    output:
        "results/umap.png"
    shell:
        "Rscript scripts/plot_umap.R {output} Pikachu,Eevee {input}"
```

Fíjate que el `output` de `run_umap` (`results/umap_nn9.tsv`) es el `input` de `plot_umap`. **Así es como Snakemake sabe el orden**: no lo escribimos en ninguna parte.

```bash
snakemake -n
snakemake -j 1
```

Abre la figura (`open results/umap.png` en Mac, `xdg-open results/umap.png` en Linux, o haz clic en el archivo en VS Code).

**Preguntas para pensar:**
1. ¿Qué reglas planeó el dry-run? ¿Por qué `run_umap` no aparece?
2. En la figura, ¿dónde quedaron Pikachu y Eevee? ¿De qué tipo son?

<details>
<summary>Respuesta</summary>

1. Solo `plot_umap` y `all`. `results/umap_nn9.tsv` ya existe y está al día.
2. Quedan junto al grupo Grass, aunque Pikachu es Electric y Eevee es Normal. Es la misma pregunta del final del script original: *"¿Pikachu y Eevee son tipo Grass???"*
</details>

✅ **Checkpoint:** `listo` en el chat. *(Si te perdiste, corre `cp ../soluciones/paso3/snakefile .` y sigue con nosotros.)*

---

## Paso 4: wildcards, una regla para muchos casos

Queremos el UMAP con varios valores de `n_neighbors` (5, 9 y 15). No vamos a copiar la regla tres veces: usamos un **wildcard**.

Reemplaza todo el `snakefile`:

```python
# Paso 4: wildcards. Una sola regla para varios valores de n_neighbors

rule all:
    input:
        "results/type_counts.txt",
        "results/umap.png"

rule count_types:
    input:
        "data/poke_starter.tsv"
    output:
        "results/type_counts.txt"
    shell:
        "cut -f2 {input} | tail -n +2 | sort | uniq -c > {output}"

rule run_umap:
    input:
        "data/poke_starter.tsv"
    output:
        "results/umap_nn{nn}.tsv"                     # CAMBIO: {nn} es un wildcard
    shell:
        "Rscript scripts/run_umap.R {input} {output} {wildcards.nn} 7 0.1"   # CAMBIO: el 9 ahora es {wildcards.nn}

rule plot_umap:
    input:
        expand("results/umap_nn{nn}.tsv", nn=[5, 9, 15])   # CAMBIO: tres archivos de entrada
    output:
        "results/umap.png"
    shell:
        "Rscript scripts/plot_umap.R {output} Pikachu,Eevee {input}"
```

- `{nn}` es un **wildcard**: un hueco que Snakemake rellena según el archivo que se pida. Si se pide `results/umap_nn5.tsv`, entonces `nn=5`.
- `expand(...)` genera la lista de tres archivos de entrada.
- Dentro de `shell`, el wildcard se escribe `{wildcards.nn}`.

**Antes de correr:** ¿cuántos jobs de `run_umap` crees que va a planear? ¿Y por qué crees que podría incluir el de `nn=9`, si ese archivo ya existe?

```bash
snakemake -n
```

<details>
<summary>Respuesta</summary>

Planea **3** jobs de `run_umap` (nn=5, nn=9 y nn=15), 1 de `plot_umap` y 1 de `all`.

El de `nn=9` aparece con `reason: Code has changed since last execution`. Snakemake **recuerda el código con el que creó cada archivo** y, como cambiamos la regla, prefiere volver a generarlo para que los resultados sean consistentes con el código. Los de `nn=5` y `nn=15` aparecen por `Missing output files`.
</details>

Ahora córrelo con 4 cores, para que los tres UMAP se calculen **al mismo tiempo**:

```bash
snakemake -j 4
ls results
```

Abre `results/umap.png`: ahora tiene un panel por cada `n_neighbors`.

**Preguntas para pensar:**
1. ¿Cómo cambia la figura al variar `n_neighbors`?
2. Con `-j 1`, ¿en qué cambiaría la ejecución?

<details>
<summary>Respuesta</summary>

1. Con pocos vecinos el UMAP enfatiza la estructura local; con más vecinos, la estructura global. Los grupos de Fire y Water se mantienen separados en todos; los que cambian son las posiciones relativas, y Pikachu/Eevee siempre quedan cerca de Grass.
2. Daría el mismo resultado, pero los tres `run_umap` correrían uno tras otro en lugar de en paralelo.
</details>

✅ **Checkpoint:** `listo` en el chat. *(Si te perdiste: `cp ../soluciones/paso4/snakefile .`)*

---

## Paso 5: params y log, sin números escondidos

Los números `7` y `0.1` siguen escondidos dentro del comando. Los sacamos a `params`, ponemos los valores de `n_neighbors` en una lista al inicio del archivo, y guardamos la salida de cada job en un `log`.

Reemplaza todo el `snakefile`:

```python
# Paso 5: params y log. Sin números "escondidos" dentro de los comandos

NN = [5, 9, 15]                                       # NUEVO: los valores de n_neighbors, en un solo lugar

rule all:
    input:
        "results/type_counts.txt",
        "results/umap.png"

rule count_types:
    input:
        "data/poke_starter.tsv"
    output:
        "results/type_counts.txt"
    shell:
        "cut -f2 {input} | tail -n +2 | sort | uniq -c > {output}"

rule run_umap:
    input:
        "data/poke_starter.tsv"
    output:
        "results/umap_nn{nn}.tsv"
    params:                                           # NUEVO
        seed = 7,
        min_dist = 0.1
    log:                                              # NUEVO
        "logs/run_umap_nn{nn}.log"
    shell:
        "Rscript scripts/run_umap.R {input} {output} {wildcards.nn} {params.seed} {params.min_dist} > {log} 2>&1"

rule plot_umap:
    input:
        expand("results/umap_nn{nn}.tsv", nn=NN)      # CAMBIO: usa la lista NN
    output:
        "results/umap.png"
    params:                                           # NUEVO
        highlight = "Pikachu,Eevee"
    log:                                              # NUEVO
        "logs/plot_umap.log"
    shell:
        "Rscript scripts/plot_umap.R {output} {params.highlight} {input} > {log} 2>&1"
```

- `params:` guarda valores con nombre que puedes usar en `shell` como `{params.seed}`.
- `log:` declara dónde irá el registro de cada job. Es `> {log} 2>&1` el que realmente lo escribe: redirige lo que imprime el script.
- `NN = [5, 9, 15]` es Python normal: una variable al inicio del archivo. Un `snakefile` es Python con superpoderes.

**Antes de correr:** nada de lo que calculamos cambia (misma semilla, mismos valores). ¿Crees que Snakemake va a volver a correr algo?

```bash
snakemake -n
```

<details>
<summary>Respuesta</summary>

Sí: vuelve a planear los 3 `run_umap`, con `reason: Code has changed since last execution; Params have changed since last execution`. Snakemake guarda con qué código y parámetros se creó cada archivo, y ahora la regla tiene parámetros que antes no existían. Es un buen ejemplo de que **vigila no solo los archivos, también el código y los parámetros.**
</details>

```bash
snakemake -j 4
ls logs
cat logs/run_umap_nn9.log
```

**Preguntas para pensar:**
1. ¿A dónde se fue el mensaje `UMAP listo: ...` que antes veíamos en la terminal?
2. ¿Cambió la figura? ¿Por qué sí o por qué no?

<details>
<summary>Respuesta</summary>

1. Al archivo `logs/run_umap_nn9.log`, por el `> {log} 2>&1`. Cuando un job falla, el log es lo primero que hay que revisar.
2. No cambió: usamos la misma semilla (`7`) y los mismos parámetros, y el resultado es idéntico. Eso es reproducibilidad.
</details>

✅ **Checkpoint:** `listo` en el chat. *(Si te perdiste: `cp ../soluciones/paso5/snakefile .`)*

---

## Paso 6: ¿qué vuelve a correr y por qué?

Este paso no cambia el código: lo usamos para entender **cuándo** Snakemake vuelve a correr algo. Para cada experimento: predice, corre `snakemake -n`, compara.

**6a. Cambiar un parámetro.** En tu `snakefile`, cambia `min_dist = 0.1` por `min_dist = 0.5` y guarda.

```bash
snakemake -n
```

¿Qué reglas se van a volver a correr? ¿Se va a correr `count_types`? Compruébalo y luego córrelo para ver cómo cambia la figura:

```bash
snakemake -j 4
```

<details>
<summary>Respuesta</summary>

Los 3 `run_umap` (`Params have changed since last execution`), `plot_umap` y `all`. `count_types` no, porque no depende de nada que cambió.
</details>

**6b. Borrar el resultado final.**

```bash
rm results/umap.png
snakemake -n
```

<details>
<summary>Respuesta</summary>

Solo se vuelve a correr `plot_umap` (y `all`). Los UMAP ya calculados están al día, así que no se recalculan.
</details>

Reconstruye la figura con `snakemake -j 4`.

**6c. Borrar un archivo intermedio.**

```bash
rm results/umap_nn9.tsv
snakemake -n
```

¿Qué crees que va a pasar? ¿Se va a volver a calcular el UMAP de `nn=9`?

<details>
<summary>Respuesta</summary>

**No**: Snakemake dice `Nothing to be done`. Como `results/umap.png` ya existe y está al día, Snakemake no necesita el archivo intermedio. Solo lo vuelve a generar si hace falta para producir algo que sí está desactualizado. Prueba:

```bash
rm results/umap.png
snakemake -n
```

Ahora sí aparecen `run_umap` (nn=9) y `plot_umap`.
</details>

Al terminar, reconstruye todo con `snakemake -j 4`.

**Extra: forzar un paso.** Si quieres volver a correr una regla aunque todo esté al día:

```bash
snakemake -j 4 --forcerun run_umap
```

✅ **Checkpoint final:** `listo` en el chat.

---

## Resumen: comandos que usamos

| Comando | Qué hace |
|---|---|
| `snakemake -n` | Dry-run: muestra qué correría y por qué, sin correr nada |
| `snakemake -n -p` | Igual, e imprime los comandos de shell |
| `snakemake -j 4` | Corre el flujo de trabajo usando hasta 4 cores |
| `snakemake -j 4 --forcerun run_umap` | Fuerza que una regla vuelva a correr |
| `snakemake --unlock` | Quita el candado si una corrida anterior se interrumpió |

| Concepto | Dónde lo vimos |
|---|---|
| `rule`, `input`, `output`, `shell` | Paso 1 |
| `rule all` (el objetivo final) | Paso 2 |
| Llamar a un script de R desde `shell` | Paso 2 |
| Encadenar reglas (el DAG se deduce solo) | Paso 3 |
| Wildcards y `expand()` | Paso 4 |
| `params` y `log` | Paso 5 |
| Cuándo se vuelve a correr algo | Pasos 4, 5 y 6 |

---

## Si te sale un error

Durante la sesión no nos detenemos por errores individuales. Busca el texto de tu error aquí. Si no está, no te preocupes: sigue con el último `snakefile` que funcionó (`cp ../soluciones/pasoN/snakefile .`) y avísanos después con un Issue (ver abajo).

| Mensaje | Qué pasó | Cómo arreglarlo |
|---|---|---|
| `Error: No Snakefile found, tried Snakefile, snakefile, ...` | Estás en la carpeta equivocada, o el archivo no se llama `snakefile`. | `pwd` debe terminar en `practica`. Revisa con `ls` el nombre del archivo. |
| `Error: cores have to be specified for local execution` | Corriste `snakemake` sin decir cuántos cores. | Agrega `-j 1` (o `-j 4`). El dry-run (`-n`) no lo necesita. |
| `TabError ... inconsistent use of tabs and spaces in indentation` | Mezclaste tabuladores y espacios. | Usa solo espacios. En VS Code, abajo a la derecha: *Spaces: 4*. |
| `MissingInputException ... affected files: data/poke_starters.tsv` | Un nombre de archivo mal escrito, o no estás en `practica/`. | Compara la ruta con `ls data`. |
| `MissingInputException ... results/type_counts.txtresults/umap.png` (dos nombres pegados) | Falta una **coma** entre dos elementos de `input:` u `output:`. | Agrega la coma al final de la línea anterior. |
| `WildcardError ... Wildcards in input files cannot be determined from output files: 'nn'` | Usaste `{nn}` en el `input` de una regla que no lo tiene en el `output`. | Usa `expand(...)` o agrega `{nn}` al `output`. |
| `NameError: The name 'nn' is unknown in this context. Did you mean 'wildcards.nn'?` | Dentro de `shell` escribiste `{nn}`. | Escribe `{wildcards.nn}`. |
| `AmbiguousRuleException: Rules ... are ambiguous for the file ...` | Dos reglas pueden producir el mismo archivo. | Haz que los `output` sean distintos. |
| `MissingRuleException: No rule to produce ...` | Pediste un archivo que ninguna regla produce. | Revisa que el nombre coincida con un `output`. |
| `CalledProcessError ... returned non-zero exit status 1` | El comando falló (por ejemplo, el script de R). | **Lee el log**: `cat logs/run_umap_nn9.log`. |
| `there is no package called 'uwot'` (en el log) | Falta un paquete de R. | En R: `install.packages("uwot")`, o activa `practica-smk`. |
| `MissingOutputException ... completed successfully, but some output files are missing` | El comando corrió, pero no creó el archivo declarado en `output`. | Compara el nombre del `output` con lo que el script realmente escribe. |
| `LockException: Directory cannot be locked` | Hay otra corrida activa, o una anterior se interrumpió. | Si no hay otra corrida: `snakemake --unlock`. |

---

## ¿Dudas o errores después de la sesión?

Abre un **Issue** en este repositorio ([Issues → New issue](https://github.com/RamGonzalez/snakemake-tutorial/issues/new)) con:

- el error **completo** (copia y pega, no captura de pantalla),
- el paso en el que estabas,
- la salida de `snakemake --version`.

## Para seguir aprendiendo

- [Documentación de Snakemake](https://snakemake.readthedocs.io/en/stable/) y su [tutorial oficial](https://snakemake.readthedocs.io/en/stable/tutorial/setup.html)
- Mölder et al. 2021, *Sustainable data analysis with Snakemake*, F1000Research
- Sandve et al. 2013, *Ten Simple Rules for Reproducible Computational Research*, PLoS Computational Biology
