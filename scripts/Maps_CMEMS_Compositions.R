suppressPackageStartupMessages({
  library(ncdf4)
  library(terra)
  library(sf)
  library(ggplot2)
  library(rnaturalearth)
  library(dplyr)
  library(scales)
})
install.packages("patchwork")
library(patchwork)
library(cowplot)

# -------------------------
# INPUTS
# -------------------------
phy_file <- "nc/cmems_mod_ibi_phy_my_0.083deg-3D_P1M-m_1752765447532.nc"
bgc_file <- "nc/cmems_mod_ibi_bgc_my_0.083deg-3D_P1M-m_1752765626313.nc"

year_min <- 1993
year_max <- 2023

out_dir <- file.path("Figs", "maps_env_format_like_bathy")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Extensión del mapa grande tipo ejemplo
ex_big <- list(xlim = c(-19, -13), ylim = c(27, 30))

# Caja Canarias para rectángulo
can_box <- list(xmin = -18.5, xmax = -13.3, ymin = 27.4, ymax = 29.4)

# -------------------------
# BASE MAP
# -------------------------
world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf") |>
  sf::st_make_valid() |>
  sf::st_transform(4326)

# -------------------------
# HELPERS
# -------------------------
info <- function(...) message(paste0("[INFO] ", sprintf(...)))
warn <- function(...) message(paste0("[WARN] ", sprintf(...)))

pick_coord_name <- function(nc, candidates) {
  all_names <- c(names(nc$dim), names(nc$var))
  hit <- candidates[tolower(candidates) %in% tolower(all_names)]
  if (length(hit) == 0) stop("No se detecta coord entre: ", paste(candidates, collapse = ", "))
  hit[1]
}

parse_cf_time <- function(time_vals, units_str) {
  if (is.null(units_str) || is.na(units_str)) return(NULL)
  if (!grepl("since", units_str, ignore.case = TRUE)) return(NULL)
  
  origin <- sub(".*since\\s+", "", units_str, ignore.case = TRUE)
  origin <- sub("\\s+.*$", "", origin)
  origin_time <- as.POSIXct(origin, tz = "UTC")
  if (is.na(origin_time)) return(NULL)
  
  if (grepl("^days", units_str, ignore.case = TRUE)) return(origin_time + time_vals * 86400)
  if (grepl("^hours", units_str, ignore.case = TRUE)) return(origin_time + time_vals * 3600)
  NULL
}

fix_lon_0360_to_180 <- function(r) {
  e <- terra::ext(r)
  # si el raster está en 0..360
  if (e[1] >= 0 && e[2] > 180) {
    r <- tryCatch(terra::rotate(r), error = function(e) r)
  }
  r
}

# Lee una variable y devuelve un SpatRaster 2D lon-lat con media temporal (y depth fijo si existe)
read_var_mean_raster <- function(nc_path, varname, year_min, year_max) {
  nc <- ncdf4::nc_open(nc_path)
  on.exit(ncdf4::nc_close(nc), add = TRUE)
  
  v <- nc$var[[varname]]
  if (is.null(v)) stop("Variable no encontrada: ", varname)
  
  # coord names robustos
  lon_name <- pick_coord_name(nc, c("lon", "longitude", "nav_lon", "x"))
  lat_name <- pick_coord_name(nc, c("lat", "latitude", "nav_lat", "y"))
  
  lon <- ncdf4::ncvar_get(nc, lon_name)
  lat <- ncdf4::ncvar_get(nc, lat_name)
  
  dims <- v$dim
  dim_names <- tolower(sapply(dims, `[[`, "name"))
  dim_lens  <- sapply(dims, `[[`, "len")
  
  i_depth <- which(dim_names %in% c("depth", "deptht", "depthu", "depthv", "lev", "level"))
  i_time  <- which(dim_names %in% c("time", "time_counter", "t"))
  
  # start/count dinámicos
  start <- rep(1, length(dim_names))
  count <- dim_lens
  
  # depth: superficie por defecto, fondo solo si var se llama bottomt
  if (length(i_depth) == 1) {
    depth_index <- 1
    if (tolower(varname) == "bottomt") depth_index <- dim_lens[i_depth]
    start[i_depth] <- depth_index
    count[i_depth] <- 1
  }
  
  # tiempo: filtra 1993-2023 si se puede, si no usa todo
  if (length(i_time) == 1) {
    tname <- dims[[i_time]]$name
    tvals <- ncdf4::ncvar_get(nc, tname)
    tunits <- ncdf4::ncatt_get(nc, tname, "units")$value
    tt <- parse_cf_time(tvals, tunits)
    
    if (is.null(tt)) {
      t_keep <- seq_len(dim_lens[i_time])
    } else {
      yrs <- as.integer(format(tt, "%Y"))
      t_keep <- which(yrs >= year_min & yrs <= year_max)
      if (length(t_keep) == 0) t_keep <- seq_len(dim_lens[i_time])
    }
    
    mats <- vector("list", length(t_keep))
    for (k in seq_along(t_keep)) {
      start_k <- start
      count_k <- count
      start_k[i_time] <- t_keep[k]
      count_k[i_time] <- 1
      mats[[k]] <- ncdf4::ncvar_get(nc, varname, start = start_k, count = count_k)
    }
    
    acc <- mats[[1]]
    if (length(mats) > 1) {
      for (k in 2:length(mats)) acc <- acc + mats[[k]]
    }
    mean2d <- acc / length(mats)
    
  } else {
    mean2d <- ncdf4::ncvar_get(nc, varname, start = start, count = count)
  }
  
  # Crear raster desde matriz y asignar extent
  r <- terra::rast(t(mean2d))
  terra::ext(r) <- terra::ext(min(lon), max(lon), min(lat), max(lat))
  terra::crs(r) <- "EPSG:4326"
  
  # Si el archivo viene con longitudes 0..360, rota a -180..180
  r <- tryCatch(terra::rotate(r), error = function(e) r)
  
  # Ajuste si lat viene descendente
  if (lat[1] > lat[length(lat)]) r <- terra::flip(r, "vertical")
  
  # EXTRA: asegurar -180..180 (si rotate no aplica por alguna razón)
  r <- fix_lon_0360_to_180(r)
  
  r
}


# Rellena NAs en el mar para evitar gaps visuales
fill_ocean_gaps <- function(r) {
  # approxNA solo rellena NAs a partir de vecinos, no crea valores donde no hay soporte
  r2 <- tryCatch(terra::approxNA(r, method = "bilinear"), error = function(e) NULL)
  if (is.null(r2)) return(r)
  r2
}

fill_na_ocean_2d <- function(r, land_sf, iters = 20, w = 7) {
  stopifnot(inherits(r, "SpatRaster"))
  
  # máscara de tierra en la misma grilla del raster
  land_v <- terra::vect(land_sf)
  land_mask <- terra::rasterize(land_v, r, field = 1, background = 0)
  
  # nunca rellenar sobre tierra
  r2 <- r
  r2[land_mask == 1] <- NA
  
  for (i in seq_len(iters)) {
    na_before <- sum(is.na(terra::values(r2)))
    if (na_before == 0) break
    
    r_fill <- terra::focal(
      r2,
      w = matrix(1, w, w),
      fun = function(x, ...) mean(x, na.rm = TRUE),
      na.policy = "only",
      fillvalue = NA
    )
    
    r2 <- terra::cover(r2, r_fill)
    
    na_after <- sum(is.na(terra::values(r2)))
    if (na_after == na_before) break
  }
  
  # mantener tierra como NA (aunque luego la tapes con geom_sf)
  r2[land_mask == 1] <- NA
  r2
}

read_var_mean_raster_fill_depth <- function(nc_path, varname, year_min, year_max) {
  nc <- ncdf4::nc_open(nc_path)
  on.exit(ncdf4::nc_close(nc), add = TRUE)
  
  v <- nc$var[[varname]]
  if (is.null(v)) stop("Variable no encontrada: ", varname)
  
  # coords robustas
  lon_name <- pick_coord_name(nc, c("lon","longitude","nav_lon","x"))
  lat_name <- pick_coord_name(nc, c("lat","latitude","nav_lat","y"))
  lon <- ncdf4::ncvar_get(nc, lon_name)
  lat <- ncdf4::ncvar_get(nc, lat_name)
  
  dims <- v$dim
  dim_names <- tolower(sapply(dims, `[[`, "name"))
  dim_lens  <- sapply(dims, `[[`, "len")
  
  i_depth <- which(dim_names %in% c("depth","deptht","depthu","depthv","lev","level"))
  i_time  <- which(dim_names %in% c("time","time_counter","t"))
  
  # start/count dinámicos (para reads)
  start <- rep(1, length(dim_names))
  count <- dim_lens
  
  # profundidad base: superficie por defecto, fondo si bottomT
  depth_base <- NA_integer_
  if (length(i_depth) == 1) {
    depth_base <- 1L
    if (tolower(varname) == "bottomt") depth_base <- dim_lens[i_depth]
  }
  
  # tiempos a promediar
  t_keep <- NULL
  if (length(i_time) == 1) {
    tname <- dims[[i_time]]$name
    tvals <- ncdf4::ncvar_get(nc, tname)
    tunits <- ncdf4::ncatt_get(nc, tname, "units")$value
    tt <- parse_cf_time(tvals, tunits)
    
    if (is.null(tt)) {
      t_keep <- seq_len(dim_lens[i_time])
    } else {
      yrs <- as.integer(format(tt, "%Y"))
      t_keep <- which(yrs >= year_min & yrs <= year_max)
      if (length(t_keep) == 0) t_keep <- seq_len(dim_lens[i_time])
    }
  } else {
    # sin time: una sola “pseudo capa”
    t_keep <- NA_integer_
  }
  
  # --------
  # 1) CAPA BASE (surface o bottom) promediada en tiempo
  # --------
  read_one <- function(depth_idx = NULL, time_idx = NULL) {
    start_k <- start
    count_k <- count
    
    if (!is.null(depth_idx) && length(i_depth) == 1) {
      start_k[i_depth] <- depth_idx
      count_k[i_depth] <- 1
    }
    if (!is.null(time_idx) && length(i_time) == 1) {
      start_k[i_time] <- time_idx
      count_k[i_time] <- 1
    }
    
    ncdf4::ncvar_get(nc, varname, start = start_k, count = count_k)
  }
  
  if (length(i_time) == 1) {
    mats <- vector("list", length(t_keep))
    for (k in seq_along(t_keep)) mats[[k]] <- read_one(depth_base, t_keep[k])
    acc <- mats[[1]]
    if (length(mats) > 1) for (k in 2:length(mats)) acc <- acc + mats[[k]]
    base2d <- acc / length(mats)
  } else {
    base2d <- read_one(depth_base, NULL)
  }
  
  # --------
  # 2) CAPA “FILL” = media vertical (solo si existe depth), también promediada en tiempo
  # --------
  fill2d <- NULL
  if (length(i_depth) == 1) {
    nD <- dim_lens[i_depth]
    
    # media en tiempo para cada depth y luego media en depth
    # (iterando depth para evitar reventar RAM)
    fill_acc <- NULL
    fill_n   <- 0L
    
    for (d in seq_len(nD)) {
      if (length(i_time) == 1) {
        mats_d <- vector("list", length(t_keep))
        for (k in seq_along(t_keep)) mats_d[[k]] <- read_one(d, t_keep[k])
        acc_d <- mats_d[[1]]
        if (length(mats_d) > 1) for (k in 2:length(mats_d)) acc_d <- acc_d + mats_d[[k]]
        mean_d <- acc_d / length(mats_d)
      } else {
        mean_d <- read_one(d, NULL)
      }
      
      if (is.null(fill_acc)) fill_acc <- mean_d else fill_acc <- fill_acc + mean_d
      fill_n <- fill_n + 1L
    }
    
    fill2d <- fill_acc / fill_n
    
    # rellenar NAs solo donde base2d es NA
    na_idx <- is.na(base2d) & !is.na(fill2d)
    base2d[na_idx] <- fill2d[na_idx]
  }
  
  # --------
  # 3) raster final
  # --------
  r <- terra::rast(t(base2d))
  terra::ext(r) <- terra::ext(min(lon), max(lon), min(lat), max(lat))
  terra::crs(r) <- "EPSG:4326"
  
  r <- tryCatch(terra::rotate(r), error = function(e) r)
  if (lat[1] > lat[length(lat)]) r <- terra::flip(r, "vertical")
  r <- fix_lon_0360_to_180(r)
  
  r
}

plot_like_example <- function(
    r, var_title, xlim, ylim, world_sf, out_png,
    show_axes = TRUE, show_title = TRUE
) {
  
  r <- fix_lon_0360_to_180(r)
  
  # Recortar primero al bbox objetivo para evitar basura fuera
  target_ex <- terra::ext(xlim[1], xlim[2], ylim[1], ylim[2])
  r <- tryCatch(terra::crop(r, target_ex), error = function(e) NULL)
  if (is.null(r) || terra::ncell(r) == 0) {
    warn("Crop vacío para %s, se omite", var_title)
    return(NULL)
  }
  
  # Rellenar huecos del mar
  r <- fill_na_ocean_2d(r, land_sf = world_sf, iters = 20, w = 7)
  
  # CLAVE: recortar márgenes NA para que el dominio sea el coloreado
  r <- tryCatch(terra::trim(r, values = NA), error = function(e) r)
  
  ex_r <- terra::ext(r)
  xlim_r <- c(ex_r[1], ex_r[2])
  ylim_r <- c(ex_r[3], ex_r[4])
  
  df <- as.data.frame(r, xy = TRUE, na.rm = FALSE)
  names(df) <- c("lon", "lat", "value")
  
  base_theme <- theme_minimal(base_size = 10) +
    theme(
      panel.background = element_rect(fill = "white", color = NA),
      panel.border = element_rect(fill = NA, color = "black", linewidth = 0.6),
      
      plot.title = element_text(hjust = 0.5, size = 11, face = "bold"),
      
      axis.title = element_text(size = 10),
      axis.text  = element_text(size = 9),
      axis.ticks = element_line(linewidth = 0.3),
      
      legend.position = "bottom",
      legend.text = element_text(size = 8),
      
      plot.margin = margin(2, 2, 2, 2)
    )
  
  p_base <- ggplot() +
    geom_raster(data = df, aes(x = lon, y = lat, fill = value)) +
    geom_sf(data = world_sf, fill = "grey70", color = "grey40", linewidth = 0.25) +
    coord_sf(xlim = xlim_r, ylim = ylim_r, expand = FALSE, crs = sf::st_crs(4326)) +
    scale_fill_gradientn(
      colors = c("darkblue", "blue", "lightblue", "white"),
      na.value = "white",
      guide = guide_colorbar(
        title = NULL,
        direction = "horizontal",
        barwidth = unit(70, "pt"),
        barheight = unit(7, "pt"),
        ticks = TRUE
      )
    ) +
    labs(title = var_title, x = "Longitude", y = "Latitude", fill = NULL) +
    base_theme
  
  if (!show_axes) {
    p_base <- p_base + theme(
      axis.title = element_blank(),
      axis.text  = element_blank(),
      axis.ticks = element_blank()
    )
  }
  
  if (!show_title) {
    p_base <- p_base + theme(plot.title = element_blank())
  }
  
  # Mapa sin leyenda
  p_map <- p_base + theme(legend.position = "none")
  
  # Sacar leyenda horizontal con tamaño consistente
  leg <- cowplot::get_legend(p_base)
  
  # Ensamblar panel final: mapa arriba, leyenda abajo
  p_out <- cowplot::plot_grid(
    p_map,
    leg,
    ncol = 1,
    rel_heights = c(1, 0.18)
  )
  
  ggsave(out_png, p_out, width = 5.6, height = 3.8, dpi = 300)
  return(p_out)
}

plot_panel_4x5 <- function(r, title, world_sf, base_size = 11) {

  # Dominio = área coloreada
  r <- tryCatch(terra::trim(r, values = NA), error = function(e) r)

  ex <- terra::ext(r)
  df <- as.data.frame(r, xy = TRUE, na.rm = FALSE)
  names(df) <- c("lon", "lat", "value")

  p <- ggplot() +
    geom_raster(data = df, aes(lon, lat, fill = value)) +
    geom_sf(data = world_sf, fill = "grey70", color = "grey40", linewidth = 0.25) +
    coord_sf(
      xlim = c(ex[1], ex[2]),
      ylim = c(ex[3], ex[4]),
      expand = FALSE,
      crs = st_crs(4326)
    ) +
    scale_fill_gradientn(
      colors = c("darkblue", "blue", "lightblue", "white"),
      na.value = "white",
      guide = guide_colorbar(
        direction = "horizontal",
        title = NULL,
        barheight = unit(0.28, "cm"),
        barwidth  = unit(5.8, "cm"),
        ticks = TRUE
      )
    ) +
    labs(title = title, x = "Longitude", y = "Latitude") +
    theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = base_size + 1),
      axis.title = element_text(size = base_size),
      axis.text  = element_text(size = base_size - 1),
      axis.ticks = element_line(linewidth = 0.25),

      panel.grid = element_blank(),
      panel.border = element_rect(color = "black", fill = NA, linewidth = 0.6),

      legend.position = "bottom",
      legend.text = element_text(size = base_size - 2),

      plot.margin = margin(3, 3, 3, 3)
    )

  # Separar mapa y leyenda con alturas fijas
  p_map <- p + theme(legend.position = "none")
  leg   <- cowplot::get_legend(p)

  cowplot::plot_grid(
    p_map, leg,
    ncol = 1,
    rel_heights = c(1, 0.22)
  )
}

ompose_20_panels_4x5 <- function(panels_20,
                                 out_png,
                                 title = "Climatological mean (1993–2023)",
                                 width = 22,
                                 height = 18,
                                 dpi = 300) {
  
  stopifnot(length(panels_20) == 20)
  
  grid <- cowplot::plot_grid(
    plotlist = panels_20,
    ncol = 4,
    align = "hv"
  )
  
  title_row <- cowplot::ggdraw() +
    cowplot::draw_label(title, x = 0, hjust = 0, size = 18)
  
  p_final <- cowplot::plot_grid(
    title_row, grid,
    ncol = 1,
    rel_heights = c(0.06, 1)
  )
  
  ggsave(out_png, p_final, width = width, height = height, dpi = dpi)
  p_final
}

process_file_all_vars_pretty <- function(nc_path, tag) {
  nc <- ncdf4::nc_open(nc_path)
  varnames <- names(nc$var)
  ncdf4::nc_close(nc)
  
  info("[%s] Variables: %d", tag, length(varnames))
  
  out_plots <- list()
  
  for (v in varnames) {
    info("[%s] %s", tag, v)
    
    r <- tryCatch(
      read_var_mean_raster_fill_depth(
        nc_path = nc_path,
        varname = v,
        year_min = year_min,
        year_max = year_max
      ),
      error = function(e) {
        warn("[%s] fallo leyendo %s: %s", tag, v, e$message)
        NULL
      }
    )
    if (is.null(r)) next
    
    out_png <- file.path(
      out_dir,
      paste0("map_", tag, "_", gsub("[^A-Za-z0-9_]+", "_", v), ".png")
    )
    
    p <- plot_like_example(
      r,
      var_title = paste0(tag, ": ", v),
      xlim = ex_big$xlim,
      ylim = ex_big$ylim,
      world_sf = world,
      out_png = out_png,
      show_axes = TRUE,
      show_title = TRUE
    )
    
    out_plots[[paste0(tag, "__", v)]] <- p
  }
  
  out_plots
}

# -------------------------
# RUN
# -------------------------
stopifnot(file.exists(phy_file))
stopifnot(file.exists(bgc_file))

# 1) Generar paneles (mapa + leyenda debajo) por archivo
plots_phy <- process_file_all_vars_pretty(phy_file, "PHY")
plots_bgc <- process_file_all_vars_pretty(bgc_file, "BGC")

# 2) Unir
plots_all <- c(plots_phy, plots_bgc)

# 3) Orden: primero PHY, luego BGC
phy_names <- names(plots_all)[grepl("^PHY__", names(plots_all))]
bgc_names <- names(plots_all)[grepl("^BGC__", names(plots_all))]

# Opcional: orden alfabético dentro de cada grupo (más estable)
phy_names <- sort(phy_names)
bgc_names <- sort(bgc_names)

panel_names <- c(phy_names, bgc_names)

# 4) Tomar solo los paneles en el orden deseado
panels_20 <- plots_all[panel_names]

# Seguridad: deben ser 20
stopifnot(length(panels_20) == 20)

# 5) Composición final 4x5
p_final <- compose_20_panels_4x5(
  panels_20 = panels_20,
  out_png = file.path(out_dir, "ALL_VARIABLES_4x5.png"),
  width = 22,
  height = 18,
  dpi = 300
)
