# Factores asociados al importe del último recibo de electricidad del primer medidor en hogares mexicanos: análisis de ENCEVI 2018 mediante regresión lineal múltiple y Ridge

Repositorio reproducible asociado al estudio sobre las características socioeconómicas, demográficas, geográficas y de equipamiento asociadas al importe reportado en el último recibo de electricidad del primer medidor en hogares mexicanos, utilizando la **Encuesta Nacional sobre Consumo de Energéticos en Viviendas Particulares (ENCEVI) 2018** del INEGI y comparando regresión lineal múltiple por mínimos cuadrados ordinarios (MCO) con errores estándar robustos HC3 frente a regresión Ridge (`glmnet`).

## Autores

* Amelí Tellez Rojas
* Jesús Maximiliano Ortega Valencia
* Jorge Alberto Hernández Luján
* Jesús Hernández Suárez

## Descripción general y alcance

* **Fuente de datos:** ENCEVI 2018 (levantada por el INEGI del 8 de enero al 29 de junio de 2018), integrando los archivos `HOGAR` y `VIVIENDA` mediante el identificador `folio` y `foliohog = 1` (hogar principal de cada vivienda seleccionada).
* **Depuración:** De **28,953** registros iniciales se excluyeron **2,970** valores faltantes y **855** registros codificados como `99999` ("No sabe") en `cons_med1`, conservando los importes iguales a cero y obteniendo una muestra analítica final de **25,128** observaciones completas en respuesta y predictores.
* **Periodo de facturación:** Únicamente **11,250** registros (38.86 % de la base inicial) contaron con los cuatro campos de fecha (`inicia1`, `mes_inic1`, `final1`, `mes_final1`) completos y distintos de `99`. Para evitar descartar más del 60 % de la muestra, se modeló el importe observado del recibo del primer medidor sin estandarizar por días ni sumar un segundo medidor (`cons_med2`).
* **Alcance estadístico:** El análisis tiene carácter exploratorio y predictivo sobre los registros analizados. Al no incorporar el factor de expansión (`factor_sem`), el estrato (`est_dis`) ni la unidad primaria de muestreo (`upm`), las estimaciones no constituyen inferencia poblacional representativa ni establecen relaciones causales.

## Especificación de los modelos

La variable respuesta se transformó mediante `log_gasto = ln(cons_med1 + 1)` (implementada con `log1p()` en R) para conservar los registros con importe igual a cero y reducir la asimetría positiva.

### Regresión lineal múltiple (MCO)

$$Y_i^* = \beta_0 + \beta_1\,\mathrm{tot\_integ}_i + \sum_{k=2}^{4} \gamma_k\,I(\mathrm{tam\_loc}_i = k) + \sum_{k=2}^{4} \delta_k\,I(\mathrm{est\_socio}_i = k) + \sum_{k=2}^{3} \theta_k\,I(\mathrm{region}_i = k) + \beta_2\,\mathrm{cuart\_dorm}_i + \beta_3\,\mathrm{num\_tvs2}_i + \beta_4\,\mathrm{num\_venti2}_i + \beta_5\,\mathrm{num\_aire2}_i + \eta\,I(\mathrm{uso\_refri}_i = 2) + \varepsilon_i$$

donde $Y_i^* = \ln(\mathrm{cons\_med1}_i + 1)$, $I(\cdot)$ denota una función indicadora y la categoría `1` actúa como nivel de referencia en cada factor.

### Regresión Ridge

Se estimó mediante `glmnet` con penalización $L_2$ ($\alpha = 0$) y validación cruzada de 10 particiones (`nfolds = 10`, `standardize = TRUE`), minimizando la suma de cuadrados residual penalizada por $\lambda \sum_{j=1}^{p} \beta_j^2$. Se evaluaron tanto `lambda.min` como `lambda.1se` sobre una partición de 80 % entrenamiento y 20 % prueba (`set.seed(123)`).

## Diccionario de variables del modelo

| Variable en R | Descripción operativa | Tipo | Tratamiento / Observación |
| :--- | :--- | :--- | :--- |
| `cons_med1` | Importe del último recibo del primer medidor (pesos) | Numérica | Respuesta original; excluye `NA` y `99999`; periodo variable |
| `log_gasto` | `ln(cons_med1 + 1)` | Numérica | Respuesta modelada (`log1p()`) |
| `tot_integ` | Total de integrantes del hogar | Numérica | Conteo |
| `tam_loc` | Tamaño de localidad | Factor | Categorías 1–4; referencia: 1 |
| `est_socio` | Estrato socioeconómico | Factor | Categorías 1–4; referencia: 1 |
| `region` | Región geográfica | Factor | Categorías 1–3; referencia: 1 |
| `cuart_dorm` | Cuartos para dormir | Numérica | Conteo |
| `num_tvs2` | Número de televisores | Numérica | `0` si `uso_tv == 2`; conserva `num_tvs` en otro caso |
| `num_venti2` | Número de ventiladores | Numérica | `0` si `uso_venti == 2`; conserva `num_venti` en otro caso |
| `num_aire2` | Número de equipos de aire acondicionado | Numérica | `0` si `uso_aire == 2`; conserva `num_aire` en otro caso |
| `uso_refri` | Categoría de uso del refrigerador | Factor | Categorías 1–2; referencia: 1 |

## Principales resultados

### 1. Caracterización de la muestra analítica ($n = 25,128$)

* **Importe original (`cons_med1`):** Mediana de 261.00 pesos (RIC = 322.20; Q1 = 157.80, Q3 = 480.00), media de 472.60 pesos (DE = 1,577.00) y rango de 0 a 99,899.00 pesos.
* **Importe transformado (`log_gasto`):** Media de $5.60$ (DE = $1.06$), mediana de $5.57$ (RIC = $1.11$).
* **Correlaciones de Spearman con `log_gasto`:** `num_aire2` ($\rho = 0.375$), `num_venti2` ($\rho = 0.315$), `num_tvs2` ($\rho = 0.286$), `cuart_dorm` ($\rho = 0.240$) y `tot_integ` ($\rho = 0.192$).

### 2. Estimación MCO, diagnósticos e inferencia robusta HC3

* **Bondad de ajuste y prueba global:** $R^2 = 0.2236$, $R^2$ ajustado $= 0.2232$, error estándar residual $= 0.9324$, $F(14, 25113) = 516.7$ ($p < 2.2 \times 10^{-16}$).
* **Multicolinealidad y heterocedasticidad:** Los valores de $\mathrm{GVIF}^{1/(2\cdot\mathrm{df})}$ oscilaron entre $1.0587$ y $1.2037$ (sin evidencia de multicolinealidad elevada). La prueba de Breusch–Pagan detectó heterocedasticidad ($BP = 234.93$, $\mathrm{gl} = 14$, $p < 2.2 \times 10^{-16}$).
* **Inferencia con errores estándar HC3:** Todas las variables explicativas mantuvieron significancia estadística ($p < 0.001$), excepto `region` categoría 3 ($p = 0.05412$).
* **Sensibilidad a valores extremos:** Al excluir temporalmente los **90** importes válidos superiores a 5,000 pesos ($n = 25,038$), $R^2$ pasó de $0.2236191$ a $0.2244868$ y los coeficientes conservaron sus signos con variaciones mínimas, por lo que dichos registros se mantuvieron en el análisis principal.

### 3. Comparación predictiva MCO vs. Ridge (conjunto de prueba, 20 %)

En la validación cruzada sobre entrenamiento se seleccionaron $\lambda_{\min} = 0.0344857$ y $\lambda_{1\mathrm{se}} = 0.6168283$. Sobre el conjunto de prueba en escala logarítmica:

| Modelo | RMSE | MAE |
| :--- | :---: | :---: |
| MCO | 0.9421544 | 0.6189150 |
| Ridge (`lambda.min`) | 0.9415527 | 0.6188546 |
| Ridge (`lambda.1se`) | 0.9483057 | 0.6265426 |

MCO y Ridge (`lambda.min`) presentaron errores prácticamente idénticos, por lo que la regularización $L_2$ no aportó una mejora predictiva práctica en la especificación evaluada.

## Estructura del repositorio

```text
.
├── README.md          # Documentación general, metodología y resultados
├── LICENSE            # Licencia aplicable al código del repositorio
├── analisis_encevi2018.R  # Script completo en R (depuración, descriptivos, MCO, HC3 y Ridge)
└── datos/             # Bases de datos de ENCEVI 2018 utilizadas en el flujo
```

## Requisitos y ejecución

1. **Entorno y librerías:** Se requiere **R** y los siguientes paquetes:
   ```r
   install.packages(c("tidyverse", "janitor", "lmtest", "sandwich", "ggplot2", "foreign", "car", "glmnet"))
   ```
2. **Configuración de ruta:** Abre el *script* principal en R y modifica el objeto `carpeta` apuntando al directorio local donde se encuentran los archivos de ENCEVI 2018.
3. **Flujo reproducible:** Al ejecutarse, el código convierte los archivos `.dbf` a `.csv` únicamente si aún no existen, genera los resúmenes descriptivos de la muestra analítica ($n = 25,128$), ajusta los modelos MCO/HC3 y Ridge (`set.seed(123)`) y produce las figuras diagnósticas y comparativas.

## Datos y licencia

* **Fuente de datos:** Los microdatos utilizados corresponden a la **Encuesta Nacional sobre Consumo de Energéticos en Viviendas Particulares (ENCEVI) 2018** del **Instituto Nacional de Estadística y Geografía (INEGI)**. Su uso y redistribución se rigen por los *Términos de uso* y la normatividad de información estadística del INEGI; debe citarse siempre al INEGI como fuente y no presentarse este estudio como avalado o elaborado oficialmente por el instituto.
* **Licencia del código:** El archivo `LICENSE` incluido en este repositorio cubre exclusivamente el código en R y la documentación elaborada por los autores, sin alterar los derechos ni los términos de uso de los microdatos originales del INEGI.

## Referencias

* Bakiri, H. A., & Mbembati, H. (2023). The effect of electricity consumption determinants in household load forecasting models. *Journal of Electrical Systems and Information Technology*, 10, Article 52. https://doi.org/10.1186/s43067-023-00122-0
* Breusch, T. S., & Pagan, A. R. (1979). A simple test for heteroscedasticity and random coefficient variation. *Econometrica*, 47(5), 1287–1294. https://doi.org/10.2307/1911963
* Carbajal Lúa, J. V. (2023). Housing and population characteristics that affect electricity spending in Mexico, 2020. *Studies in Applied Economics*, 41(3). https://doi.org/10.25115/sae.v41i3.9254
* De Cian, E., Falchetta, G., Pavanello, F., Romitti, Y., & Sue Wing, I. (2025). The impact of air conditioning on residential electricity consumption across world countries. *Journal of Environmental Economics and Management*, 131, Article 103122. https://doi.org/10.1016/j.jeem.2025.103122
* Friedman, J., Hastie, T., & Tibshirani, R. (2010). Regularization paths for generalized linear models via coordinate descent. *Journal of Statistical Software*, 33(1), 1–22. https://doi.org/10.18637/jss.v033.i01
* Hernández, M., & Patino-Echeverri, D. (2022). Electricity consumption, subsidies, and policy inequalities in Mexico: Data from 100,000 households. *Energy for Sustainable Development*, 71, 186–199. https://doi.org/10.1016/j.esd.2022.09.014
* Hoerl, A. E., & Kennard, R. W. (1970). Ridge regression: Biased estimation for nonorthogonal problems. *Technometrics*, 12(1), 55–67. https://doi.org/10.1080/00401706.1970.10488634
* Instituto Nacional de Estadística y Geografía. (2018a). *Encuesta Nacional sobre Consumo de Energéticos en Viviendas Particulares (ENCEVI) 2018*. https://www.inegi.org.mx/programas/encevi/2018/
* Instituto Nacional de Estadística y Geografía. (2018b). *Encuesta Nacional sobre Consumo de Energéticos en Viviendas Particulares. ENCEVI: Diseño muestral*. https://www.inegi.org.mx/contenidos/productos/prod_serv/contenidos/espanol/bvinegi/productos/nueva_estruc/702825107086.pdf
* Instituto Nacional de Estadística y Geografía. (2018c). *Encuesta Nacional sobre Consumo de Energéticos en Viviendas Particulares (ENCEVI) 2018: Descripción de la base de datos*. https://www.inegi.org.mx/contenidos/programas/encevi/2018/doc/encevi_2018_fd.pdf
* Instituto Nacional de Estadística y Geografía. (2018d). *Encuesta Nacional sobre Consumo de Energéticos en Viviendas Particulares (ENCEVI) 2018: Cuestionario*. https://www.inegi.org.mx/programas/encevi/2018/
* James, G., Witten, D., Hastie, T., & Tibshirani, R. (2021). *An introduction to statistical learning: With applications in R* (2nd ed.). Springer. https://doi.org/10.1007/978-1-0716-1418-1
* Molar-Cruz, A., Huezo Rodríguez, S. A., & Hamacher, T. (2021). Characterizing the energy burden of urban households in Mexico: The impact of socioeconomic and temperature conditions across metropolitan areas. *Frontiers in Sustainable Cities*, 3, Article 662968. https://doi.org/10.3389/frsc.2021.662968
* Najeeb, A., Sridharan, S., Rao, A. B., Agnihotri, S. B., & Mishra, V. (2024). Determinants of residential electricity consumption in South, East and South East Asia: A systematic review. *Renewable and Sustainable Energy Reviews*, 198, Article 114400. https://doi.org/10.1016/j.rser.2024.114400
* White, H. (1980). A heteroskedasticity-consistent covariance matrix estimator and a direct test for heteroskedasticity. *Econometrica*, 48(4), 817–838. https://doi.org/10.2307/1912934
