# R Script for the article "Map animation on covid19 in Santa Catarina, Brazil"
# Author: Guilherme Viegas
# Linkedin: https://www.linkedin.com/in/guilherme-viegas-1b5b0495/

# Setup -------------------------------------------------------------------

# Cleaning up the environment before starting
rm(list = ls())
gc(verbose = T, full = T)

# Packages ----------------------------------------------------------------

# Loading needed packages. If not installed, It is gonna install it automatically.
if(!require(readr)) install.packages("readr")
if(!require(sp)) install.packages("sp")
if(!require(sf)) install.packages("sf")
if(!require(dplyr)) install.packages("dplyr")
if(!require(ggplot2)) install.packages("ggplot2")
if(!require(gganimate)) install.packages("gganimate")
if(!require(magick)) install.packages("magick")

# Data --------------------------------------------------------------------

# ShapeFile of the whole State of Santa Catarina
sf_file_sc <- sf::read_sf("data/sc_state_shapefile/BRUFE250GC_SIR.shp") %>%
  dplyr::filter(NM_ESTADO == "SANTA CATARINA")

# ShapeFile of the cities within Santa Catarina
sf_file_cities <- sf::read_sf("data/sc_cities_shapefile/42MUE250GC_SIR.shp") %>%
  dplyr::mutate(CD_GEOCMU=as.character(CD_GEOCMU))

# Confirmed cases of covid19 in Santa Catarina
covid19scdata <- readr::read_csv(file = "data/covid19_cases/covid19scdata.csv") %>% 
  dplyr::mutate(city_ibge_code = as.character(city_ibge_code))

# Transformations ---------------------------------------------------------

# Joining the shapefile of the cities with the confirmed cases of covid19 per city data
geodatacovid19sc <- dplyr::left_join(covid19scdata, sf_file_cities, by = c("city_ibge_code"="CD_GEOCMU"))

# Transforming it back to a shapefile
geodatacovid19sc <- geodatacovid19sc %>% 
  sf::st_as_sf(.)

# Filtering for only the cities with covid19 cases
datascsf <- geodatacovid19sc %>% 
  dplyr::filter(confirmed > 0)

# Map animation -----------------------------------------------------------

# Map plotting
gganim <- ggplot2::ggplot() +
  ggplot2::geom_sf(data = sf_file_sc, size = .05, fill = "#AAAAAA") +
  ggplot2::geom_sf(data = datascsf, aes(fill = confirmed), size = 0) +
  ggplot2::geom_text(data = datascsf, aes(x = -52.921059, y = -28.140309, label = strftime(date,"%d/%m/%Y")), size = 7) +
  ggplot2::theme_void() +
  ggplot2::labs(title = "Dissemination of covid19 in Santa Catarina",
                subtitle = "Day {frame} since the first case in the state",
                caption = "Guilherme Viegas",
                fill = "Confirmed cases of covid19") +
  ggplot2::scale_fill_continuous(guide = guide_legend(direction = "horizontal", title.position = "top")) +
  ggplot2::theme(plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
                 plot.subtitle = element_text(size = 18, hjust = 0.5),
                 plot.caption = element_text(size = 13, face = "bold"),
                 legend.title=element_text(size=16, face = "bold"),
                 legend.text=element_text(size=18, face = "bold"),
                 legend.key.size = unit(0.5, "cm"),
                 legend.position=c(.3, .2)) +
  gganimate::transition_manual(index) # Here is the whole animation gearing
# gganim

# Animating ---------------------------------------------------------------

spause = 3 # Start Pause
epause = 8 # End Pause

# Animating the ggplot
gganimated <- gganimate::animate(
  gganim, 
  nframes = max(geodatacovid19sc$index) + spause + epause, 
  fps = 1, 
  duration = max(geodatacovid19sc$index) + spause + epause, 
  start_pause = spause, 
  end_pause = epause
)
gganimated

# Converting to a magick object
covid19_sc_animation <- magick::image_read(gganimated)

# Saving the animation
magick::image_write(covid19_sc_animation, path="covid19_sc_animation.gif")

# Hope you have liked it.

