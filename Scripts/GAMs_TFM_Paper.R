library(dplyr)
library(readxl)
library(ggplot2)
library(gam)
library(mgcv)
library(tweedie)
library(broom)
library(patchwork) 

#Data
data <- read_excel("D:/Investigación/TFM/Algas_EROS.xlsx") %>% 
  mutate(Island=factor(Island, levels = c("El Hierro", "La Palma", "La Gomera","Tenerife", "Gran Canaria", "Lanzarote", "Fuerteventura")))

island_data <- split(data, data$Island)

# Modelo para toda canarias Canarias
#Bryopsidales
gam_model_C_B <- gam(S_Bryopsidales ~ Year + (s(Salinity,  bs = 'cr', k = 30) +
                       s(SST,  bs = 'cr', k = 30) +
                       s(swh, bs = 'cr', k = 30) +  
                       s(ssr, bs = 'cr', k = 30) +   
                       s(NO3, bs = 'cr', k = 30) +
                       s(PO4, bs = 'cr', k = 30)), 
                     data = data, method = 'REML',
                     family = Tweedie(p = 1.5, link = "log"), # Uso adecuado de la familia Tweedie
                     select = TRUE, # Permitir penalización adaptativa
                     na.action = na.exclude)
summary(gam_model_C_B)
#Fucales
gam_model_C_F<- gam(S_Fucales ~ Year + (s(Salinity, bs = 'cr', k = 30) + 
                      s(SST, bs = 'cr', k = 30) + 
                      s(swh, bs = 'cr', k = 30) +  
                      s(ssr, bs = 'cr', k = 30) + 
                      s(NO3, bs = 'cr', k = 35) +   
                      s(PO4, bs = 'cr', k = 30)), 
                    data = data, method = 'REML',
                    family = Tweedie(p = 1.5, link = "log"), 
                    select = TRUE, 
                    na.action = na.exclude)
summary(gam_model_C_F)

#Ceramiales
gam_model_C_C<- gam(S_Ceramiales ~ Year + (s(Salinity, bs = 'cr', k = 30) + 
                      s(SST, bs = 'cr', k = 30) + 
                      s(swh, bs = 'cr', k = 30) +  
                      s(ssr, bs = 'cr', k = 30) + 
                      s(NO3, bs = 'cr', k = 35) +   
                      s(PO4, bs = 'cr', k = 30)), 
                    data = data, method = 'REML',
                    family = Tweedie(p = 1.5, link = "log"), 
                    select = TRUE, 
                    na.action = na.exclude)
summary(gam_model_C_C)

#Dictyotales 
gam_model_C_D<- gam(S_Dictyotales ~ Year + (s(Salinity, bs = 'cr', k = 30) + 
                      s(SST, bs = 'cr', k = 30) + 
                      s(swh, bs = 'cr', k = 30) +  
                      s(ssr, bs = 'cr', k = 30) + 
                      s(NO3, bs = 'cr', k = 35) +   
                      s(PO4, bs = 'cr', k = 30)), 
                    data = data, method = 'REML',
                    family = Tweedie(p = 1.5, link = "log"), 
                    select = TRUE,
                    na.action = na.exclude)
summary(gam_model_C_D)




# Función para procesar un modelo y extraer coeficientes, incluyendo Island
process_gam_model_1 <- function(model, model_name, data) {
  summary_model <- summary(model)
  
  # Términos paramétricos
  parametric_terms <- data.frame(
    term = rownames(summary_model$p.table), 
    estimate = summary_model$p.table[, "Estimate"],
    std.error = summary_model$p.table[, "Std. Error"],
    p.value = summary_model$p.table[, "Pr(>|t|)"],
    type = "Parametric",
    Island = rep(unique(data$Island), each = nrow(summary_model$p.table)) 
  )
  
  # Términos suavizados
  smooth_terms <- data.frame(
    term = rownames(summary_model$s.table), 
    estimate = summary_model$s.table[, "edf"], 
    std.error = NA,
    p.value = summary_model$s.table[, "p-value"],
    type = "Smooth",
    Island = rep(unique(data$Island), each = nrow(summary_model$s.table)) 
  )
  
  # Combinar términos
  coef_data <- rbind(parametric_terms, smooth_terms)
  
  # Añadir metadatos y escala logarítmica
  coef_data <- coef_data %>%
    mutate(
      Significance = case_when(
        p.value < 0.001 ~ "***",
        p.value < 0.01 ~ "**",
        p.value < 0.05 ~ "*",
        TRUE ~ ""
      ),
      Model = model_name,
      log_estimate = ifelse(estimate == 0, NA, log10(abs(estimate))),
      Sign = ifelse(estimate > 0, "Positive", "Negative")
    )
  
  return(coef_data)
}


# Procesar modelos, asegurándose de pasar los datos correspondientes
coef_data_C_B <- process_gam_model_1(gam_model_C_B, "Bryopsidales", data)
coef_data_C_F <- process_gam_model_1(gam_model_C_F, "Fucales", data)
coef_data_C_C <- process_gam_model_1(gam_model_C_C, "Ceramiales", data)
coef_data_C_D <- process_gam_model_1(gam_model_C_D, "Dyctiotales", data)


# Combinar todos los datos
#Para Canarias
coef_data_C_all <- bind_rows(coef_data_C_B, coef_data_C_F, coef_data_C_C, coef_data_C_D)


# Asegurar que Island sea un factor con un orden deseado si es necesario
coef_data_C_all <- coef_data_C_all %>%
  mutate(Island = factor(Island, levels = unique(Island))) 

# Asegurar que todos los términos estén presentes para cada modelo
terms_order <- c("(Intercept)", "Year", "s(Salinity)", "s(SST)", "s(swh)", "s(ssr)", "s(NO3)", "s(PO4)")

coef_data_C_all <- coef_data_C_all %>%
  mutate(term = factor(term, levels = terms_order)) %>%  # Ordenar los términos explícitamente
  arrange(Model, term)  # Asegurarte de que cada modelo siga este orden

coef_data_C_all <- coef_data_C_all %>%
  mutate(Significance = case_when(
    p.value < 0.001 ~ "***",
    p.value < 0.01 ~ "**",
    p.value < 0.05 ~ "*",
    TRUE ~ ""
  ))

# Crear el gráfico
C_E_PLOT <- ggplot(coef_data_C_all, aes(x = log_estimate, y = term, shape = type, color = Model, group = Model)) +
  geom_point(size = 2) +  # Puntos
  geom_path(size = 1, linetype = "solid", alpha = 0.7) +  # Líneas continuas que conectan los términos
  geom_errorbarh(
    aes(xmin = log_estimate - std.error, xmax = log_estimate + std.error),
    height = 0.2, na.rm = TRUE
  ) +
  # Agregar anotaciones de significancia
  geom_text(aes(label = Significance), hjust = -0.5, size = 4, na.rm = TRUE, color = "black") +
  geom_vline(xintercept = -1, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey50") +
  labs(
    x = "Log10(Coefficient Estimate)", 
    y = NULL, 
    color = "Order", 
    shape = "Term Type (Parametric/Smooth)"
  ) +
  theme_minimal() +
  theme(legend.position = "right") +
  scale_color_manual(values = c("red", "blue", "green", "purple")) +
  scale_x_continuous(limits = c(-2.3, 2.3)) +
  scale_y_discrete(limits = rev(terms_order)) 


# Modelo para cada isla Canarias
#Bryopsidales
gam_model_I_B <- lapply(island_data, function(df) { gam(S_Bryopsidales ~ Year + 
                                                (s(Salinity, bs = 'cr', k = 30) +
                                                s(SST, bs = 'cr', k = 30) +
                                                s(swh, bs = 'cr', k = 30) +  
                                                s(ssr, bs = 'cr', k = 30) +   
                                                s(NO3, bs = 'cr', k = 35) +
                                                s(PO4, bs = 'cr', k = 30)), 
                     data = data, method = 'REML',
                     family = Tweedie(p = 1.5, link = "log"), # Uso adecuado de la familia Tweedie
                     select = TRUE, # Permitir penalización adaptativa
                     na.action = na.exclude)})
summary(gam_model_I_B)
#Fucales
gam_model_I_F <-  lapply(island_data, function(df) {gam(S_Fucales ~ Year + 
                                          (s(Salinity, bs = 'cr', k = 30) + 
                                          s(SST, bs = 'cr', k = 30) + 
                                          s(swh, bs = 'cr', k = 30) +  
                                          s(ssr, bs = 'cr', k = 30) + 
                                          s(NO3, bs = 'cr', k = 35) +   
                                          s(PO4, bs = 'cr', k = 30)), 
                    data = data, method = 'REML',
                    family = Tweedie(p = 1.5, link = "log"), 
                    select = TRUE, na.action = na.exclude)})
summary(gam_model_I_F)
#Ceramiales
gam_model_I_C <-  lapply(island_data, function(df) {gam(S_Ceramiales ~ Year + 
                                            (s(Salinity, bs = 'cr', k = 30) + 
                                             s(SST, bs = 'cr', k = 30) +
                                             s(swh, bs = 'cr', k = 30) +  
                                             s(ssr, bs = 'cr', k = 30) + 
                                             s(NO3, bs = 'cr', k = 35) +   
                                             s(PO4, bs = 'cr', k = 30)), 
                    data = data, method = 'REML',
                    family = Tweedie(p = 1.5, link = "log"), 
                    select = TRUE, na.action = na.exclude)})
summary(gam_model_I_C)

#Dictyotales
gam_model_I_D <- lapply(island_data, function(df) {gam(S_Dictyotales ~ Year + 
                                              (s(Salinity, bs = 'cr', k = 30) + 
                                              s(SST, bs = 'cr', k = 30) + 
                                              s(swh, bs = 'cr', k = 30) +  
                                              s(ssr, bs = 'cr', k = 30) + 
                                              s(NO3, bs = 'cr', k = 35) +   
                                              s(PO4, bs = 'cr', k = 30)), 
                    data = data, method = 'REML',
                    family = Tweedie(p = 1.5, link = "log"), 
                    select = TRUE, na.action = na.exclude)})

summary(gam_model_I_D)


# Función para procesar coeficientes y términos suavizados
process_gam_model <- function(model, island_name, model_name) {
  summary_model <- summary(model)
  
  # Coeficientes paramétricos
  parametric <- data.frame(
    term = rownames(summary_model$p.table),
    estimate = summary_model$p.table[, "Estimate"],
    std.error = summary_model$p.table[, "Std. Error"],
    p.value = summary_model$p.table[, "Pr(>|t|)"],
    type = "Parametric",
    Island = island_name
  )
  
  # Términos suavizados
  smooth <- data.frame(
    term = rownames(summary_model$s.table),
    estimate = summary_model$s.table[, "edf"],  # Grados de libertad efectivos
    std.error = NA,  # No hay std.error para términos suavizados
    p.value = summary_model$s.table[, "p-value"],
    type = "Smooth",
    Island = island_name
  )
  
  # Combinar ambos
  bind_rows(parametric, smooth) %>%
    mutate(
      Model = model_name,
      log_estimate = ifelse(estimate == 0, NA, log10(abs(estimate))),
      Significance = case_when(
        p.value < 0.001 ~ "***",
        p.value < 0.01 ~ "**",
        p.value < 0.05 ~ "*",
        TRUE ~ ""
      ),
      Sign = ifelse(estimate > 0, "Positive", "Negative")
    )
}

# Procesar todos los modelos de Bryopsidales
bryopsidales_data <- lapply(names(gam_model_I_B), function(island) {
  process_gam_model(gam_model_I_B[[island]], island, "Bryopsidales")
}) %>%
  bind_rows()

# Procesar todos los modelos de Ceramiales
ceramiales_data <- lapply(names(gam_model_I_C), function(island) {
  process_gam_model(gam_model_I_C[[island]], island, "Ceramiales")
}) %>%
  bind_rows()

# Procesar todos los modelos de Dictyotales
dictyotales_data <- lapply(names(gam_model_I_D), function(island) {
  process_gam_model(gam_model_I_D[[island]], island, "Dictyotales")
}) %>%
  bind_rows()

# Procesar todos los modelos de Fucales
fucales_data <- lapply(names(gam_model_I_F), function(island) {
  process_gam_model(gam_model_I_F[[island]], island, "Fucales")
}) %>%
  bind_rows()


# Combinar todos los datos
all_model_data <- bind_rows(bryopsidales_data,ceramiales_data,dictyotales_data,fucales_data)

all_model_data$term <- factor(all_model_data$term, levels = c(
  "(Intercept)", "Year", "s(Salinity)", "s(SST)", "s(swh)", "s(ssr)", "s(NO3)", "s(PO4)"
))

I_E_PLOT <- ggplot(all_model_data, aes(x = log_estimate, y = term, shape = Island, color = Model, group = interaction(Model, Island))) +
  geom_point(size = 1) +
  geom_path(size = 1, linetype = "solid", alpha = 0.7) +
  geom_errorbarh(
    aes(xmin = log10(abs(estimate - std.error)), xmax = log10(abs(estimate + std.error))),
    height = 0.2, na.rm = TRUE
  ) +
  geom_text(aes(label = Significance), hjust = -0.5, size = 4, na.rm = TRUE, color = "black") +
  geom_vline(xintercept = -1, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey50") +
  labs(
    x = "Log10(Coefficient Estimate)",
    y = NULL,
    color = "Order",
    shape = "Island"
  ) +
  #facet_wrap(~Model) +  # Separar por orden
  theme_minimal() +
  theme(legend.position = "right") +
  scale_color_manual(values = c("red", "blue", "green", "purple")) +
  scale_y_discrete(limits = rev(unique(all_model_data$term))) +
  scale_shape_manual(values = c(
    "El Hierro" = 16,
    "La Palma" = 17,
    "La Gomera" = 15,
    "Tenerife" = 3,
    "Gran Canaria" = 4,
    "Lanzarote" = 8,
    "Fuerteventura" = 5
  ))




# Subconjunto "Western Islands"
western_islands <- data %>%
  filter(Island %in% c("La Palma", "El Hierro", "La Gomera", "Tenerife")) %>%
  mutate(Region = "Western Islands")

# Subconjunto "Eastern Islands"
eastern_islands <- data %>%
  filter(Island %in% c("Gran Canaria", "Lanzarote", "Fuerteventura")) %>%
  mutate(Region = "Eastern Islands")

# Combinar ambos subconjuntos en una nueva base de datos agrupada
grouped_data <- bind_rows(western_islands, eastern_islands)

# Verificar la cantidad de filas por región
grouped_data %>%
  group_by(Region) %>%
  summarise(Count = n())

# Revisar estructura de los datos para cada región
regional_data <- split(grouped_data, grouped_data$Region)

lapply(regional_data, function(df) {
  print(head(df))
  print(nrow(df))
})


# Ajustar modelos GAM para cada región
#Bryopsidales
gam_model_R_B <- lapply(names(regional_data), function(region) {
  gam(S_Bryopsidales ~ Year + s(Salinity, bs = 'cr', k = 30) +
        s(SST, bs = 'cr', k = 30) +
        s(swh, bs = 'cr', k = 30) +
        s(ssr, bs = 'cr', k = 30) +
        s(NO3, bs = 'cr', k = 35) +
        s(PO4, bs = 'cr', k = 30),
      data = regional_data[[region]],
      family = Tweedie(p = 1.5, link = "log"),
      method = 'REML',
      select = TRUE, na.action = na.exclude)
})
lapply(gam_model_R_B, summary)


#Ceramiales
gam_model_R_C <- lapply(names(regional_data), function(region) {
  gam(S_Ceramiales ~ Year + s(Salinity, bs = 'cr', k = 30) +
        s(SST, bs = 'cr', k = 30) +
        s(swh, bs = 'cr', k = 30) +
        s(ssr, bs = 'cr', k = 30) +
        s(NO3, bs = 'cr', k = 35) +
        s(PO4, bs = 'cr', k = 30),
      data = regional_data[[region]],
      family = Tweedie(p = 1.5, link = "log"),
      method = 'REML',
      select = TRUE, na.action = na.exclude)
})
lapply(gam_model_R_C, summary)


#Dyctiotales
gam_model_R_D <- lapply(names(regional_data), function(region) {
  gam(S_Dictyotales ~ Year + s(Salinity, bs = 'cr', k = 30) +
        s(SST, bs = 'cr', k = 30) +
        s(swh, bs = 'cr', k = 30) +
        s(ssr, bs = 'cr', k = 30) +
        s(NO3, bs = 'cr', k = 35) +
        s(PO4, bs = 'cr', k = 30),
      data = regional_data[[region]],
      family = Tweedie(p = 1.5, link = "log"),
      method = 'REML',
      select = TRUE, na.action = na.exclude)
})
lapply(gam_model_R_D, summary)


#Fucales
gam_model_R_F <- lapply(names(regional_data), function(region) {
  gam(S_Fucales ~ Year + s(Salinity, bs = 'cr', k = 30) +
        s(SST, bs = 'cr', k = 30) +
        s(swh, bs = 'cr', k = 30) +
        s(ssr, bs = 'cr', k = 30) +
        s(NO3, bs = 'cr', k = 35) +
        s(PO4, bs = 'cr', k = 30),
      data = regional_data[[region]],
      family = Tweedie(p = 1.5, link = "log"),
      method = 'REML',
      select = TRUE, na.action = na.exclude)
})
lapply(gam_model_R_F, summary)


#Corrección de función de procesado de datos
process_gam_model <- function(model, region_name, model_name) {
  summary_model <- summary(model)
  
  # Manejar términos paramétricos
  parametric_terms <- if (!is.null(summary_model$p.table)) {
    data.frame(
      term = rownames(summary_model$p.table),
      estimate = summary_model$p.table[, "Estimate"],
      std.error = summary_model$p.table[, "Std. Error"],
      p.value = summary_model$p.table[, "Pr(>|t|)"],
      type = "Parametric",
      Region = region_name
    )
  } else {
    data.frame(term = character(), estimate = numeric(), std.error = numeric(), 
               p.value = numeric(), type = character(), Region = character())
  }
  
  # Manejar términos suavizados
  smooth_terms <- if (!is.null(summary_model$s.table)) {
    data.frame(
      term = rownames(summary_model$s.table),
      estimate = summary_model$s.table[, "edf"],  # Grados de libertad efectivos
      std.error = NA,
      p.value = summary_model$s.table[, "p-value"],
      type = "Smooth",
      Region = region_name
    )
  } else {
    data.frame(term = character(), estimate = numeric(), std.error = numeric(), 
               p.value = numeric(), type = character(), Region = character())
  }
  
  # Combinar términos y agregar metadatos
  coef_data <- bind_rows(parametric_terms, smooth_terms) %>%
    mutate(
      Model = model_name,
      log_estimate = ifelse(estimate == 0, NA, log10(abs(estimate))),
      Significance = case_when(
        p.value < 0.001 ~ "***",
        p.value < 0.01 ~ "**",
        p.value < 0.05 ~ "*",
        TRUE ~ ""
      ),
      Sign = ifelse(estimate > 0, "Positive", "Negative")
    )
  
  return(coef_data)
}



regional_results_B <- lapply(names(gam_model_R_B), function(region) {
  process_gam_model(gam_model_R_B[[region]], region, "Bryopsidales")
}) %>%
  bind_rows()

regional_results_C <- lapply(names(gam_model_R_C), function(region) {
  process_gam_model(gam_model_R_C[[region]], region, "Ceramiales")
}) %>%
  bind_rows()

regional_results_D <- lapply(names(gam_model_R_D), function(region) {
  process_gam_model(gam_model_R_D[[region]], region, "Dictyotales")
}) %>%
  bind_rows()

regional_results_F <- lapply(names(gam_model_R_F), function(region) {
  process_gam_model(gam_model_R_F[[region]], region, "Fucales")
}) %>%
  bind_rows()

