# === CARGA DE PAQUETES NECESARIOS ===
library(ncdf4)
library(raster)
library(dplyr)
library(tidyr)
library(readxl)
library(vegan)
library(lme4)
library(mgcv)
library(ggplot2)
library(purrr)
library(gratia)

# === 1. PARÁMETROS GENERALES ===
prof_superficie <- 0.5  # profundidad deseada (m)

# Coordenadas representativas por isla
islas_coords <- data.frame(
  Isla = c("Lanzarote", "Fuerteventura", "Gran Canaria", "Tenerife", "La Gomera", "La Palma", "El Hierro"),
  Lon = c(-13.6, -13.9, -15.4, -16.6, -17.1, -17.8, -18.0),
  Lat = c(29.0, 28.4, 27.9, 28.3, 28.1, 28.6, 27.8)
)

# === 2. RUTAS A LOS ARCHIVOS ===
file_phy <- "D:/Investigación/Macroalgas/cmems_mod_ibi_phy_my_0.083deg-3D_P1M-m_1752765447532.nc"
file_bgc <- "D:/Investigación/Macroalgas/cmems_mod_ibi_bgc_my_0.083deg-3D_P1M-m_1752765626313.nc"

# === 3. FUNCIÓN PARA EXTRAER UNA VARIABLE DE UN .nc ===
extraer_variable <- function(nc_file, varname, profundidad = 0.5) {
  nc <- nc_open(nc_file)
  on.exit(nc_close(nc))
  
  # Extraer ejes
  lon <- ncvar_get(nc, "longitude")
  lat <- ncvar_get(nc, "latitude")
  depth <- ncvar_get(nc, "depth")
  time <- ncvar_get(nc, "time")
  
  # Calcular fechas
  time_units <- ncatt_get(nc, "time", "units")$value
  time_origin <- as.Date(sub(".*since ", "", time_units))
  fechas <- time_origin + time
  
  # Índice más cercano a la profundidad deseada
  i_dep <- which.min(abs(depth - profundidad))
  
  # Obtener la variable (asumimos estructura [lon, lat, depth, time])
  var <- ncvar_get(nc, varname)  # array 4D
  
  # Comprobación de dimensiones
  dims <- dim(var)
  if (length(dims) != 4) stop("La variable no es 4D.")
  
  # Extraer rasters por tiempo
  data_list <- lapply(seq_along(fechas), function(i) {
    capa <- var[ , , i_dep, i]
    r <- raster(t(capa), xmn = min(lon), xmx = max(lon),
                ymn = min(lat), ymx = max(lat),
                crs = CRS("+proj=longlat +datum=WGS84"))
    r <- flip(r, direction = 'y')
    names(r) <- as.character(fechas[i])
    return(r)
  })
  
  stack(data_list)
}

# === 4. EXTRAER VARIABLES AMBIENTALES ===
sst_stack <- extraer_variable(file_phy, "thetao")   # temperatura superficial
sss_stack <- extraer_variable(file_phy, "so")       # salinidad

no3_stack <- extraer_variable(file_bgc, "no3")
po4_stack <- extraer_variable(file_bgc, "po4")

# === 5. EXTRAER DATOS POR ISLA ===
extraer_por_isla <- function(r_stack, nombre_var) {
  df <- data.frame()
  for (i in 1:nrow(islas_coords)) {
    # Usamos raster::extract explícitamente
    valores <- raster::extract(r_stack, islas_coords[i, c("Lon", "Lat")])
    if (!is.null(valores)) {
      fechas <- as.Date(names(r_stack))
      df_temp <- data.frame(
        Fecha = fechas,
        Isla = islas_coords$Isla[i],
        Valor = as.numeric(valores)
      )
      names(df_temp)[3] <- nombre_var
      df <- rbind(df, df_temp)
    }
  }
  return(df)
}
df_sst <- extraer_por_isla(sst_stack, "SST")
df_sss <- extraer_por_isla(sss_stack, "SSS")
df_no3 <- extraer_por_isla(no3_stack, "NO3")
df_po4 <- extraer_por_isla(po4_stack, "PO4")

# Unir todos los datos ambientales por Fecha e Isla
library(dplyr)
df_env <- df_sst %>%
  left_join(df_sss, by = c("Fecha", "Isla")) %>%
  left_join(df_swh, by = c("Fecha", "Isla")) %>%
  left_join(df_ssr, by = c("Fecha", "Isla")) %>%
  left_join(df_no3, by = c("Fecha", "Isla")) %>%
  left_join(df_po4, by = c("Fecha", "Isla"))

# === 6. UNIR VARIABLES AMBIENTALES ===
df_amb <- reduce(list(df_sst, df_sss, df_slotst, df_no3, df_po4), full_join, by = c("Isla", "Fecha")) %>%
  mutate(Year = format(Fecha, "%Y")) %>%
  group_by(Isla, Year) %>%
  summarise(across(SST:PO4, ~mean(.x, na.rm = TRUE)), .groups = "drop")

write.csv(df_amb, "variables_ambientales_por_isla_y_anio.csv", row.names = FALSE)

# === 7. CARGA DE REGISTROS BIOLÓGICOS ===
ruta_excel <- "D:/Investigación/Macroalgas/Registros_Biota.xlsx"
registros <- read_excel(ruta_excel, sheet = "Data")

# === 8. MÉTRICAS DE DIVERSIDAD ===
registros_filtrados <- registros %>%
  filter(!is.na(Specie), !is.na(Isla), !is.na(Year))

diversidad <- registros_filtrados %>%
  group_by(Isla, Year) %>%
  summarise(
    riqueza = n_distinct(Specie),
    shannon = diversity(table(Specie[!is.na(Specie)])), .groups = "drop"
  )

# === 9. UNIÓN Y MODELADO ===
variables_ambientales <- read.csv("variables_ambientales_por_isla_y_anio.csv")

datos_modelo <- inner_join(diversidad, variables_ambientales, by = c("Isla", "Year"))

# === 10. MODELOS ===

# GLMM
modelo_glmm <- lmer(shannon ~ SST + SSS + NO3 + PO4 + SLOTST + (1 | Isla) + (1 | Year), data = datos_modelo)
summary(modelo_glmm)

# GAM
modelo_gam <- gam(shannon ~ s(SST) + s(NO3) + s(Year, bs = "re") + s(Isla, bs = "re"), data = datos_modelo)
summary(modelo_gam)

# === 11. VISUALIZACIÓN ===
ggplot(datos_modelo, aes(x = as.numeric(Year), y = shannon, color = Isla)) +
  geom_line() +
  geom_point() +
  theme_minimal() +
  labs(title = "Índice de Shannon por Isla y Año", x = "Año", y = "Shannon")

# Efectos parciales del GAM
draw(modelo_gam)
