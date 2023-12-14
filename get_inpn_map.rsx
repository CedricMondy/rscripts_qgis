##Data=group
##Carte INPN (Open Obs)=name
##Nom_latin_espece=string
##QgsProcessingParameterFeatureSource|masque|Limites géographiques|2|None|True
##Carte_INPN=output vector

taxref <- vroom::vroom(
    "C:/QGIS-CUSTOM/DATA/JOINTURE-CSV/TAXREFv16.txt",
    delim = "\t"
  )

if (! Nom_latin_espece %in% taxref$LB_NOM)
  stop("Nom d'espece non trouve dans TAXREF")

cd_ref <- taxref %>%
  dplyr::filter(LB_NOM == Nom_latin_espece) %>%
  dplyr::pull(CD_REF)

Carte_INPN <- sf::st_read(
  paste0("https://odata-inpn.mnhn.fr/geometries/grids/taxon/", cd_ref)
) %>%
  sf::st_transform(crs = 2154)

if (!is.null(masque)) {
  Carte_INPN <- Carte_INPN %>%
    (
      function(observations) {
        oks <- sf::st_intersects(
          observations,
          masque %>%
            dplyr::summarise() %>%
            sf::st_transform(crs = 2154)
          ) %>%
          as.data.frame() %>%
          dplyr::as_tibble()

        observations %>%
          dplyr::slice(oks$row.id)
      }
    )

}
