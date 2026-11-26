# Instalar paquetes
# install.packages(c("tidyverse", "janitor", "lmtest", "sandwich", "ggplot2", "foreign", "car", "glmnet"))

# Cargar paquetes
library(foreign)
library(tidyverse)
library(janitor)
library(lmtest)
library(car)
library(glmnet)
library(sandwich)

# Seleccionar carpeta y convertir archivos .dbf a .csv
carpeta <- "C:/Users/Maximiliano Ortega V/Downloads/proyecto_modelos"#ruta a los archivos dbf
list.files(carpeta)

archivos_dbf <- list.files(
  path = carpeta,
  pattern = "\\.dbf$",
  full.names = TRUE,
  ignore.case = TRUE
)

for (archivo in archivos_dbf) {
  salida_csv <- sub("\\.dbf$", ".csv", archivo, ignore.case = TRUE)
  
  if (!file.exists(salida_csv)) {
    df <- read.dbf(archivo, as.is = TRUE)
    write.csv(df, salida_csv, row.names = FALSE)
  }
}
# Cargar bases principales
encevi <- read_csv(file.path(carpeta, "encevi.csv"))
vivienda <- read_csv(file.path(carpeta, "vivienda.csv"))
hogar <- read_csv(file.path(carpeta, "hogar.csv"))
persona <- read_csv(file.path(carpeta, "persona.csv"))
electro <- read_csv(file.path(carpeta, "electro.csv"))

# Dimensiones y nombres de variables
dim(encevi)
dim(vivienda)
dim(hogar)
dim(persona)
dim(electro)

names(encevi)
names(vivienda)
names(hogar)
names(persona)
names(electro)

# Exploración inicial de cons_med1 y llaves
summary(encevi$cons_med1)
table(encevi$cons_med1, useNA = "ifany")
sum(encevi$cons_med1 == 99999, na.rm = TRUE)
sum(encevi$cons_med1 == 0, na.rm = TRUE)

sum(duplicated(encevi[c("folio", "foliohog")]))
sum(duplicated(hogar[c("folio", "foliohog")]))
sum(duplicated(vivienda["folio"]))
sum(!hogar$folio %in% vivienda$folio)
sum(!vivienda$folio %in% hogar$folio)
identical(hogar$folio, vivienda$folio)
setequal(hogar$folio, vivienda$folio)

table(vivienda$tot_hog, useNA = "ifany")
table(hogar$foliohog, useNA = "ifany")
table(hogar$foliohog, vivienda$tot_hog)

viviendas_multiples <- vivienda %>% filter(tot_hog > 1)
nrow(viviendas_multiples)
head(viviendas_multiples, 10)

table(encevi$electri, useNA = "ifany")
table(encevi$tipo_tarif, useNA = "ifany")
table(encevi$uso_refri, useNA = "ifany")
table(encevi$uso_aire, useNA = "ifany")

summary(encevi$cons_med2)
table(encevi$cons_med2, useNA = "ifany")

# Unión de bases
datos <- encevi %>%
  left_join(hogar, by = c("folio", "foliohog")) %>%
  left_join(vivienda, by = "folio")

dim(datos)
head(datos)
names(datos)
sum(duplicated(datos$folio))
sum(duplicated(datos[c("folio", "foliohog")]))
sum(is.na(datos$folio))
sum(is.na(datos$foliohog))

hogares_por_vivienda <- datos %>%
  group_by(folio) %>%
  summarise(
    registros = n(),
    hogares = n_distinct(foliohog),
    .groups = "drop"
  )

hogares_por_vivienda %>%
  filter(registros > 1) %>%
  head(20)

sum(is.na(datos$tot_integ))
sum(is.na(datos$factor_sem))
summary(datos$tot_integ)
table(datos$region, useNA = "ifany")
table(datos$entidad, useNA = "ifany")

# Definición de gasto_electricidad e importes_validos
datos$gasto_electricidad <- datos$cons_med1
datos$gasto_electricidad[datos$gasto_electricidad == 99999] <- NA

importes_validos <- datos$cons_med1[!is.na(datos$cons_med1) & datos$cons_med1 != 99999]

summary(datos$gasto_electricidad)
sum(is.na(datos$gasto_electricidad))
sum(!is.na(datos$gasto_electricidad))

# Revisión de valores extremos y ceros
quantile(datos$gasto_electricidad, probs = c(0, 0.90, 0.95, 0.99, 1), na.rm = TRUE)
sort(datos$gasto_electricidad, decreasing = TRUE)[1:20]
sum(datos$gasto_electricidad > 1000, na.rm = TRUE)
sum(datos$gasto_electricidad > 2000, na.rm = TRUE)
sum(datos$gasto_electricidad > 5000, na.rm = TRUE)
sum(datos$gasto_electricidad > 10000, na.rm = TRUE)
sum(datos$gasto_electricidad > 50000, na.rm = TRUE)

datos %>%
  filter(gasto_electricidad > 5000) %>%
  count(gasto_electricidad, sort = TRUE) %>%
  print(n = 50)

datos %>%
  filter(gasto_electricidad > 5000) %>%
  select(
    gasto_electricidad, electri, local_com, elect_loc,
    tipo_tarif, inicia1, mes_inic1, final1, mes_final1
  ) %>%
  arrange(desc(gasto_electricidad)) %>%
  print(n = 90)

hist(
  datos$gasto_electricidad[datos$gasto_electricidad <= 5000],
  main = "Distribución del gasto en electricidad",
  xlab = "Gasto en electricidad (pesos)",
  ylab = "Frecuencia",
)

sum(datos$gasto_electricidad == 0, na.rm = TRUE)

datos %>%
  mutate(
    grupo = case_when(
      gasto_electricidad == 0 ~ "Gasto cero",
      !is.na(gasto_electricidad) ~ "Gasto positivo",
      TRUE ~ "Faltante"
    )
  ) %>%
  count(grupo, electri, local_com, elect_loc)

datos %>%
  filter(gasto_electricidad == 0) %>%
  count(tipo_tarif, sort = TRUE)

datos %>%
  filter(gasto_electricidad == 0) %>%
  count(inicia1, final1, sort = TRUE)

sum(datos$gasto_electricidad == 0 & datos$tipo_tarif == 9, na.rm = TRUE)
sum(datos$gasto_electricidad == 0 & datos$inicia1 == "99" & datos$final1 == "99", na.rm = TRUE)

# Revisión de fechas
variables_fecha <- c("inicia1", "mes_inic1", "final1", "mes_final1")
lapply(datos[, variables_fecha], unique)

for (v in variables_fecha) {
  cat("\nVariable:", v, "\n")
  cat("Valores NA:", sum(is.na(datos[[v]])), "\n")
  cat("Valores 99:", sum(datos[[v]] == "99", na.rm = TRUE), "\n")
  cat("Valores disponibles:", sum(!is.na(datos[[v]]) & datos[[v]] != "99"), "\n")
}

fechas_completas <- with(
  datos,
  !is.na(inicia1) & !is.na(mes_inic1) & !is.na(final1) & !is.na(mes_final1) &
    inicia1 != "99" & mes_inic1 != "99" & final1 != "99" & mes_final1 != "99"
)
sum(fechas_completas)
round(mean(fechas_completas) * 100, 2)
length(fechas_completas)

# Frecuencia y resumen de importes válidos > 5000
table(importes_validos[importes_validos > 5000])
summary(importes_validos[importes_validos > 5000])

importes_altos <- datos %>%
  filter(!is.na(cons_med1), cons_med1 != 99999, cons_med1 > 5000)

table(importes_altos$local_com, useNA = "ifany")
table(importes_altos$elect_loc, useNA = "ifany")
table(importes_altos$local_com, importes_altos$elect_loc, useNA = "ifany")

# Limpieza y transformación de variables predictoras
datos$num_venti2 <- ifelse(datos$uso_venti == 2, 0, datos$num_venti)
datos$num_aire2 <- ifelse(datos$uso_aire == 2, 0, datos$num_aire)
datos$num_tvs2 <- ifelse(datos$uso_tv == 2, 0, datos$num_tvs)

datos$tipo_tarif[datos$tipo_tarif == 9] <- NA
datos$super_cons[datos$super_cons == 9] <- NA

vars_categoricas <- c("uso_refri", "tipo_tarif", "super_cons", "tam_loc", "est_socio", "region")
datos[vars_categoricas] <- lapply(datos[vars_categoricas], as.factor)

variables_modelo <- c(
  "gasto_electricidad", "tot_integ", "tam_loc", "est_socio",
  "region", "super_cons", "cuart_dorm", "num_tvs2",
  "num_venti2", "num_aire2", "uso_refri", "tipo_tarif"
)

nrow(datos)
sum(complete.cases(datos[variables_modelo]))
sum(complete.cases(datos[setdiff(variables_modelo, "tipo_tarif")]))
sum(complete.cases(datos[setdiff(variables_modelo, "super_cons")]))
sum(complete.cases(datos[setdiff(variables_modelo, c("tipo_tarif", "super_cons"))]))

variables_finales <- c(
  "gasto_electricidad", "tot_integ", "tam_loc", "est_socio",
  "region", "cuart_dorm", "num_tvs2", "num_venti2",
  "num_aire2", "uso_refri"
)

datos_modelo <- datos[complete.cases(datos[variables_finales]), variables_finales]
datos_modelo$log_gasto <- log1p(datos_modelo$gasto_electricidad)

dim(datos_modelo)
str(datos_modelo)
summary(datos_modelo)

# Análisis exploratorio sobre datos_modelo

vars_numericas <- c(
  "gasto_electricidad", "log_gasto", "tot_integ",
  "cuart_dorm", "num_tvs2", "num_venti2", "num_aire2"
)

resumen_numericas <- datos_modelo %>%
  select(all_of(vars_numericas)) %>%
  pivot_longer(cols = everything(), names_to = "variable", values_to = "valor") %>%
  group_by(variable) %>%
  summarise(
    n = sum(!is.na(valor)),
    media = mean(valor, na.rm = TRUE),
    de = sd(valor, na.rm = TRUE),
    mediana = median(valor, na.rm = TRUE),
    ric = IQR(valor, na.rm = TRUE),
    min = min(valor, na.rm = TRUE),
    max = max(valor, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))

print(resumen_numericas, n = Inf)
vars_categoricas_modelo <- c("tam_loc", "est_socio", "region", "uso_refri")
resumen_categoricas <- map_dfr(
  vars_categoricas_modelo,
  ~ datos_modelo %>%
    count(categoria = as.character(.data[[.x]]), name = "n") %>%
    mutate(
      variable = .x,
      porcentaje = round(n / sum(n) * 100, 2)
    ) %>%
    select(variable, categoria, n, porcentaje)
)

print(resumen_categoricas, n = Inf)
quantile(datos_modelo$gasto_electricidad, probs = c(0, .25, .50, .75, .90, .95, .99, 1), na.rm = TRUE)

variables_cor <- datos_modelo[, c("log_gasto", "tot_integ", "cuart_dorm", "num_tvs2", "num_venti2", "num_aire2")]
round(cor(variables_cor, method = "spearman"), 3)

par(mfrow = c(2, 2))
boxplot(log_gasto ~ tam_loc, data = datos_modelo, main = "Gasto según tamaño de localidad", xlab = "Tamaño de localidad", ylab = "Log(gasto + 1)")
boxplot(log_gasto ~ est_socio, data = datos_modelo, main = "Gasto según nivel socioeconómico", xlab = "Nivel socioeconómico", ylab = "Log(gasto + 1)")
boxplot(log_gasto ~ region, data = datos_modelo, main = "Gasto según región", xlab = "Región", ylab = "Log(gasto + 1)")
boxplot(log_gasto ~ uso_refri, data = datos_modelo, main = "Gasto según uso de refrigerador", xlab = "Uso de refrigerador", ylab = "Log(gasto + 1)")
par(mfrow = c(1, 1))

# Modelo OLS y diagnósticos
formula_modelo <- log_gasto ~ tot_integ + tam_loc + est_socio +
  region + cuart_dorm + num_tvs2 + num_venti2 + num_aire2 + uso_refri

modelo_ols <- lm(formula_modelo, data = datos_modelo)
summary(modelo_ols)

par(mfrow = c(2, 2))
plot(modelo_ols)
par(mfrow = c(1, 1))

bptest(modelo_ols)
vif(modelo_ols)

resultados_HC3 <- coeftest(modelo_ols, vcov. = vcovHC(modelo_ols, type = "HC3"))
tabla_HC3 <- data.frame(
  Variable = rownames(resultados_HC3),
  Estimacion = resultados_HC3[, 1],
  Error_HC3 = resultados_HC3[, 2],
  Estadistico = resultados_HC3[, 3],
  Valor_p = resultados_HC3[, 4]
)
tabla_HC3[, 2:5] <- round(tabla_HC3[, 2:5], 5)
tabla_HC3

# Sensibilidad sin gastos > 5,000
datos_sin_extremos <- datos_modelo %>% filter(gasto_electricidad <= 5000)
modelo_sin_extremos <- lm(formula_modelo, data = datos_sin_extremos)

nrow(datos_modelo)
nrow(datos_sin_extremos)
summary(modelo_ols)$r.squared
summary(modelo_sin_extremos)$r.squared
round(coef(modelo_ols), 4)
round(coef(modelo_sin_extremos), 4)

# Modelo Ridge y validación cruzada en muestra completa
x <- model.matrix(formula_modelo, data = datos_modelo)[, -1]
y <- datos_modelo$log_gasto

set.seed(123)
modelo_ridge_cv <- cv.glmnet(x, y, alpha = 0, nfolds = 10, standardize = TRUE)
modelo_ridge_cv$lambda.min
modelo_ridge_cv$lambda.1se
coef(modelo_ridge_cv, s = "lambda.1se")

plot(modelo_ridge_cv)
abline(v = log(modelo_ridge_cv$lambda.min), lty = 2, col = "blue", lwd = 2)
abline(v = log(modelo_ridge_cv$lambda.1se), lty = 3, col = "red", lwd = 2)
legend("topright", legend = c("Lambda mínimo", "Lambda 1se"), col = c("blue", "red"), lty = c(2, 3), lwd = 2, bty = "n")

# División train/test y evaluación OLS vs Ridge
set.seed(123)
n <- nrow(datos_modelo)
id_train <- sample(seq_len(n), size = floor(0.8 * n))
train <- datos_modelo[id_train, ]
test <- datos_modelo[-id_train, ]

ols_train <- lm(formula_modelo, data = train)
pred_ols <- predict(ols_train, newdata = test)

x_train <- model.matrix(formula_modelo, data = train)[, -1]
x_test <- model.matrix(formula_modelo, data = test)[, -1]
y_train <- train$log_gasto

set.seed(123)
ridge_cv_train <- cv.glmnet(x_train, y_train, alpha = 0, nfolds = 10, standardize = TRUE)

pred_min <- predict(ridge_cv_train, s = "lambda.min", newx = x_test)
pred_1se <- predict(ridge_cv_train, s = "lambda.1se", newx = x_test)

calc_rmse <- function(real, pred) sqrt(mean((real - as.numeric(pred))^2))
calc_mae <- function(real, pred) mean(abs(real - as.numeric(pred)))

rmse_minimo <- calc_rmse(test$log_gasto, pred_min)
mae_minimo <- calc_mae(test$log_gasto, pred_min)
rmse_uno <- calc_rmse(test$log_gasto, pred_1se)
mae_uno <- calc_mae(test$log_gasto, pred_1se)

resultados_modelos <- data.frame(
  Modelo = c("OLS", "Ridge lambda.min", "Ridge lambda.1se"),
  RMSE = c(calc_rmse(test$log_gasto, pred_ols), rmse_minimo, rmse_uno),
  MAE = c(calc_mae(test$log_gasto, pred_ols), mae_minimo, mae_uno)
)
resultados_modelos

# Gráficos con ggplot2
ggplot(datos_modelo, aes(x = gasto_electricidad)) +
  geom_histogram(binwidth = 150, boundary = 0, fill = "steelblue", color = "black") +
  coord_cartesian(xlim = c(0, 5000)) +
  labs(
    title = "Distribución del importe del recibo de electricidad (hasta $5,000)",
    subtitle = "Eje X acotado visualmente; se conservan todos los registros en la muestra",
    x = "Importe del recibo (pesos)",
    y = "Frecuencia"
  ) +
  theme_minimal()

ggplot(datos_modelo, aes(x = log_gasto)) +
  geom_histogram(bins = 40, color = "black") +
  labs(title = "Distribución del importe transformado", x = "Logaritmo del importe más uno", y = "Frecuencia") +
  theme_minimal()

ggplot(datos_modelo, aes(x = region, y = log_gasto)) +
  geom_boxplot() +
  labs(title = "Importe transformado por región", x = "Región", y = "Logaritmo del importe más uno") +
  theme_minimal()

ggplot(datos_modelo, aes(x = est_socio, y = log_gasto)) +
  geom_boxplot() +
  labs(title = "Importe transformado por estrato socioeconómico", x = "Estrato socioeconómico", y = "Logaritmo del importe más uno") +
  theme_minimal()

grafico_residuos <- data.frame(
  Ajustados = fitted(modelo_ols),
  Residuos = residuals(modelo_ols)
)

ggplot(grafico_residuos, aes(x = Ajustados, y = Residuos)) +
  geom_point(alpha = 0.3) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(title = "Residuos contra valores ajustados", x = "Valores ajustados", y = "Residuos") +
  theme_minimal()

ggplot(data.frame(Residuos = residuals(modelo_ols)), aes(sample = Residuos)) +
  stat_qq() +
  stat_qq_line() +
  labs(title = "Gráfico Q-Q de los residuos", x = "Cuantiles teóricos", y = "Cuantiles de los residuos") +
  theme_minimal()


df_pred <- bind_rows(
  data.frame(
    Modelo = "MCO",
    Observados = test$log_gasto,
    Predichos = as.numeric(pred_ols)
  ),
  data.frame(
    Modelo = "Ridge (lambda.min)",
    Observados = test$log_gasto,
    Predichos = as.numeric(pred_min)
  )
)

ggplot(df_pred, aes(x = Observados, y = Predichos)) +
  geom_point(alpha = 0.12, size = 1.1) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  facet_wrap(~ Modelo) +
  labs(
    title = "Valores observados contra predichos en el conjunto de prueba",
    x = "Observados: ln(importe + 1)",
    y = "Predichos: ln(importe + 1)"
  ) +
  theme_minimal()