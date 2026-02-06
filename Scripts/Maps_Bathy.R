library(ggplot2)    #for plotting
library(grDevices)   
library(scales)
library(gridExtra)
library(maps)              # for obtaining the map data
library(sf)                # for working with map proyections and spatial data.
library(rnaturalearth)     # for higher resolution data
library(rnaturalearthdata) # for higher resolution data
library(marmap)            # for getNOAA.bathy
library(osmdata)
library(units)
library(dplyr)
library(extrafont)

# Registrar las fuentes del sistema
#font_import(prompt = FALSE)  # Puede tardar unos minutos
#loadfonts(device = "win")    # Para sistemas Windows
#Try 1

map_data <- map_data("world")

# Plot the map using ggplot2, adding your data as points on top:
# Variabe addition on the map

ggplot() + 
  geom_tile()+
  geom_polygon(data = map_data, aes(x = long, y = lat, group = group),
               fill = "grey70", color = "grey40") +
  xlim(-50, 16) +
  ylim(10, 60) +
  theme_minimal()

#Try 2
# Upload maps data with sf

# Cargar datos de mapas con sf
world <- st_as_sf(maps::map("world", plot = FALSE, fill = TRUE))

# Crear el mapa con coordenadas geográficas
ggplot(data = world) +
  geom_sf(fill = "grey70", color = "grey40") +
  coord_sf(xlim = c(-50, 16), ylim = c(10, 60), expand = FALSE) +
  theme_minimal() +
  labs(title = "North East Atlantic Ocean")


# Descargar datos del mundo en formato sf
world <- ne_countries(scale = "medium", returnclass = "sf")

# Descargar datos de batimetría del Atlántico Norte
batimetria_w <- getNOAA.bathy(lon1 = -50, lon2 = 15, lat1 = 10, lat2 = 60, resolution = 1)

# Convertir la batimetría a un data frame
batimetria_df_w <- marmap::fortify.bathy(batimetria_w)

# Crear el mapa del atlantico norte
ggplot() +
  # Fondo con gradiente de batimetría
  geom_raster(data = batimetria_df_w, aes(x = x, y = y, fill = z)) +
  scale_fill_gradientn(
    colors = c("darkblue", "blue", "lightblue", "white"),
    values = scales::rescale(c(-4000, -3000, -2000, 0)),
    name = "Depth (m)") +
  # Líneas de contorno de batimetría (limitadas entre -6000 y -2000 m)
  geom_contour(
    data = batimetria_df_w,
    aes(x = x, y = y, z = z),
    color = "black",
    breaks = seq(0)  # Ajustar los valores aquí
  ) +
  # Polígonos del mundo
  geom_sf(data = world, fill = "grey70", color = "grey40") +
  # Límites geográficos del mapa
  coord_sf(
    xlim = c(-50, 15), # Límites de longitud
    ylim = c(10, 60),  # Límites de latitud
    expand = FALSE
  ) +
  # Títulos y etiquetas
  labs(
    title = "North East Atlantic Ocean Bathymetry",
    x = "Longitude",
    y = "Latitude"
  ) +
  # Tema del gráfico
  theme_minimal(base_size = 15) +
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    panel.border = element_rect(fill = NA, color = "black", size = 1),
    plot.title = element_text(hjust = 0.5, size = 18, face = "bold"),
    axis.title = element_text(size = 14, family = "Times New Roman"),
    axis.text = element_text(size = 12, family = "Times New Roman"),
    legend.text = element_text(size = 10, family = "Times New Roman"),
    legend.title = element_text(size = 12, family = "Times New Roman")
  )+
  geom_rect(
    aes(xmin = -18.5, xmax = -13.3, ymin = 27.4, ymax = 29.4),
    fill = NA, color = "black", linetype = "solid", size = 0.5
  )
  

# Descargar datos de batimetría para Canarias
batimetria <- getNOAA.bathy(
  lon1 = -18.5, lon2 = -13.3,
  lat1 = 27.6, lat2 = 29.4,
  resolution = 1  # Resolución en minutos
)

# Convertir los datos de batimetría a un data frame manualmente
batimetria_matrix <- as.data.frame(as.table(as.matrix(batimetria)))
colnames(batimetria_matrix) <- c("x", "y", "z")
batimetria_df <- batimetria_matrix %>% mutate(z = as.numeric(z))

# Filtrar los datos de batimetría para incluir solo valores por debajo del nivel del mar
batimetria_df <- batimetria_df %>% filter(z <= 0)

# Definir etiquetas para las islas
labels <- data.frame(
  name = c("El Hierro", "La Palma", "La Gomera", "Tenerife", "Gran Canaria", "Fuerteventura", "Lanzarote"),
  lon = c(-18.1, -17.8, -17.2, -16.5, -15.5, -14.4, -13.7),
  lat = c(27.7, 28.7, 28.1, 28.3, 28.1, 28.5, 29.0)
)

# Definir el área de interés (Islas Canarias)
bbox <- c(-18.5, 27.6, -13.3, 29.4)

# Descargar datos de líneas de costa desde OpenStreetMap
coastline <- opq(bbox = bbox) %>%
  add_osm_feature(key = "natural", value = "coastline") %>%
  osmdata_sf()

# Verificar y corregir geometrías inválidas
coastline_valid <- st_make_valid(coastline$osm_lines)

# Filtrar las geometrías válidas
geometry_types <- st_geometry_type(coastline_valid)
coastline_valid_filtered <- coastline_valid[geometry_types %in% c("LINESTRING", "MULTILINESTRING"), ]

# Cerrar las líneas y convertirlas a polígonos
coastline_closed <- lapply(st_geometry(coastline_valid_filtered), function(geom) {
  coords <- st_coordinates(geom)
  if (nrow(coords) >= 4) {
    if (!all(coords[1, ] == coords[nrow(coords), ])) {
      closed_geom <- rbind(coords, coords[1, ])
      st_polygon(list(closed_geom))
    } else {
      st_cast(geom, "POLYGON")
    }
  } else {
    NULL
  }
})
coastline_closed <- do.call(st_sfc, coastline_closed)
coastline_closed <- st_sf(geometry = coastline_closed, crs = 4326)
coastline_closed_valid <- coastline_closed[st_is_valid(coastline_closed), ]
coastline_polygons <- coastline_closed_valid[st_area(coastline_closed_valid) > units::set_units(0, "m^2"), ]

# Crear el mapa combinado con las islas en color fijo y batimetría en gradiente ajustado
ggplot() +
  # Fondo con gradiente de batimetría (solo valores negativos)
  geom_raster(data = batimetria_df, aes(x = x, y = y, fill = z)) +
  scale_fill_gradientn(
    colors = c("darkblue", "blue", "lightblue", "white"),
    values = scales::rescale(c(-4000, -3000, -2000, 0)),
    name = "Depth (m)",
    limits = c(-4500, 0)  # Limitar el rango del gradiente a valores negativos
  ) +
  # Polígonos de las islas con color fijo
  geom_sf(data = coastline_polygons, fill = "grey70", color = "grey40") +
  # Líneas de contorno de batimetría
  geom_contour(data = batimetria_df, aes(x = x, y = y, z = z), color = "black", breaks = seq(-4000, 0, by = 500)) +
  # Etiquetas de las islas
  geom_text(data = labels, aes(x = lon, y = lat, label = name), size = 3, color = "white", fontface = "bold") +
  # Tema y ajustes
  labs(
    title = "Canary Islands Bathymetry",
    x = "Longitud",
    y = "Latitud"
  ) +
  coord_sf(xlim = c(-18.5, -13.3), ylim = c(27.6, 29.4), expand = FALSE) +
  theme_minimal(base_size = 15) +
  theme(
    element_text
    panel.background = element_rect(fill = "white", color = NA),
    panel.border = element_rect(fill = NA, color = "black", size = 1),
    plot.title = element_text(hjust = 0.5, size = 18, face = "bold")
  )

# Mostrar el gráfico
CIB


# Cargar librería necesaria
library(patchwork)

# Combinar los gráficos en una disposición de 1 columna y 2 filas
combined_plot <- NEAB / CIB

# Mostrar el gráfico combinado
combined_plot

