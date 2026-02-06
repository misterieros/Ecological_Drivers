#Packages
library(ggplot2)
library(dplyr)
library(tidyr)
library(forcats)
library(hrbrthemes)
library(viridis)
library(readxl)
library(vegan)
library(cluster)
library(tidyverse)
library(officer)
library(rvg)
library(export)
library(purrr)
library(here)


data_frame <- read_excel("E:/Investigación/TFM/Algas_EROS.xlsx") %>% 
  mutate(Island=factor(Island, levels = c("El Hierro", "La Palma", "La Gomera","Tenerife", "Gran Canaria", "Lanzarote", "Fuerteventura")))

#PCA
# Seleccionar las variables de respuesta (Bryopsidales, Ceramiales, Dictyotales, Fucales)
variables_respuesta <- data_frame %>%
  select(Bryopsidales, Ceramiales, Dictyotales, Fucales) 


# Seleccionar las variables independientes (todo lo demás)
variables_independientes <- data_frame %>%
  select(-Bryopsidales, -Ceramiales, -Dictyotales, -Fucales)
variables_independientes_num <- variables_independientes %>%
  select_if(is.numeric)


# Puedes revisar el resultado para asegurarte de que están bien separadas
#head(variables_respuesta)
#head(variables_independientes)

# Normalizar las variables independientes
variables_independientes_scaled <- scale(variables_independientes_num)

# También puedes normalizar las variables de respuesta si lo deseas, aunque no es estrictamente necesario
variables_respuesta_scaled <- scale(variables_respuesta)

# Realizar el PCA considerando las variables independientes como predictores de las respuestas
# Aquí estamos usando las variables independientes para hacer un PCA sobre las variables respuesta

# Concatenar las variables respuesta y las independientes escaladas
datos_pca <- cbind(variables_independientes_scaled, variables_respuesta_scaled)

# Aplicar PCA
pca_resultado <- prcomp(datos_pca, center = TRUE, scale. = TRUE)

# Resumen del PCA para ver la proporción de varianza explicada
#summary(pca_resultado)

pca_df <- as.data.frame(pca_resultado$x)

varianza_explicada <- summary(pca_resultado)$importance[2,]

loadings <- pca_resultado$rotation

#Convertir las cargas a un data frame (ya lo hiciste pero vamos a corregir un pequeño error de sintaxis)
loadings_df <- as.data.frame(loadings)

# Extraer los primeros dos componentes principales (PC1 y PC2)
pca_df <- as.data.frame(pca_resultado$x)

# Crear la visualización base con los puntos (primeros dos componentes principales)
ggplot(pca_df, aes(x = PC1, y = PC2)) +
  geom_point(aes(color = data_frame$Island), size = 1, alpha = 0.7) +  # Puntos coloreados por isla
  labs(title = "PCA", x = "PC1", y = "PC2") +
  theme_minimal()+

# Añadir las flechas para las cargas de las variables
  geom_segment(data = loadings_df, 
                  aes(x = 0, y = 0, xend = 10*PC1, yend = 10*PC2), 
                  arrow = arrow(type = "open", length = unit(0.1, "inches")), 
                  color = "black", size = 0.01) + # Flechas 
  geom_text(data = loadings_df,
            aes(x = 12*PC1, y = 12*PC2, label = rownames(loadings_df)),
            size = 4, box.padding = 0.5, point.padding = 0.5, 
            segment.color = "black", segment.size = 0.5)+
  labs(color="Islands")
