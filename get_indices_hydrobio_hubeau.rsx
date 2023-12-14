##Data=group
##Indices hydrobio (Hubeau)=name
##Regions=string NULL
##Departements=string NULL
##QgsProcessingParameterFeatureSource|masque|Limites géographiques|2|None|True
##Codes_indices=string "2928,5856,5910,7613,6951,7036"
##Indices_hydrobio=output vector

if (!require(hubeau))
  install.packages("hubeau")
if (!require(dplyr))
  install.packages("dplyr")
if (!require(lubridate))
  install.packages("lubridate")
if (!require(sf))
  install.packages("sf")

get_chunks <- function(x, n = NULL, max_size = 200) {
  #https://stackoverflow.com/questions/3318333/split-a-vector-into-chunks
  if (!is.null(max_size)) {
    n <- ceiling(length(x) / max_size)
  } else {
    if (is.null(n))
      stop("n or max_size should be given")
  }

  if (length(x) <= max_size) {
    list(x)
  } else {
    split(x, cut(seq_along(x), n, labels = FALSE))
  }
}

if (Regions == "NULL")
  Regions <- NULL
if (Departements == "NULL")
  Departements <- NULL

if (is.null(Regions) & is.null(Departements)) {
  params_stations <- NULL
} else {
  params_stations <- list(
    code_region = Regions,
    code_departement = Departements
  ) %>%
    (function(x) x[!sapply(x, is.null)])
}


stations_hydrobio <- hubeau::get_hydrobio_stations_hydrobio(
  params_stations
) %>%
  sf::st_as_sf(
    coords = c("coordonnee_x", "coordonnee_y"),
    crs = 2154,
    remove = FALSE
  )

if (!is.null(masque)) {
  stations_hydrobio <- stations_hydrobio %>%
    (
      function(stations) {
        oks <- sf::st_intersects(
          stations,
          masque %>%
            dplyr::summarise() %>%
            sf::st_transform(crs = 2154)
          ) %>%
          as.data.frame() %>%
          dplyr::as_tibble()

        stations %>%
          dplyr::slice(oks$row.id)
      }
    )

}

if (nrow(stations_hydrobio) > 0) {
  Indices_hydrobio <- stations_hydrobio$code_station_hydrobio %>%
  get_chunks(max_size = 100) %>%
  purrr::map_df(
    function(stations) {
      hubeau::get_hydrobio_indices(
        list(
          code_indice = Codes_indices,
          code_station_hydrobio = paste0(stations, collapse = ",")
        )
      )
    }
  ) %>%
  dplyr::distinct(
    code_station_hydrobio, coordonnee_x, coordonnee_y, code_support, libelle_support, code_prelevement, date_prelevement, code_indice, libelle_indice, resultat_indice, code_qualification, libelle_qualification
  ) %>%
  dplyr::mutate(
    date_prelevement = lubridate::as_date(date_prelevement)
  ) %>%
  dplyr::mutate(annee = lubridate::year(date_prelevement)) %>%
  dplyr::filter(!is.na(resultat_indice)) %>%
  sf::st_as_sf(
  coords = c("coordonnee_x", "coordonnee_y"),
  crs = 2154
  )

} else {
  Indices_hydrobio <- hubeau::get_hydrobio_indices(
        list(
          code_indice = Codes_indices,
          code_station_hydrobio = "03063000"
        )
      ) %>%
  dplyr::distinct(
    code_station_hydrobio, coordonnee_x, coordonnee_y, code_support, libelle_support, code_prelevement, date_prelevement, code_indice, libelle_indice, resultat_indice, code_qualification, libelle_qualification
  ) %>%
  dplyr::mutate(
    date_prelevement = lubridate::as_date(date_prelevement)
  ) %>%
  dplyr::mutate(annee = lubridate::year(date_prelevement)) %>%
  dplyr::filter(!is.na(resultat_indice)) %>%
  sf::st_as_sf(
  coords = c("coordonnee_x", "coordonnee_y"),
  crs = 2154
  ) %>%
  dplyr::slice(0)
}
