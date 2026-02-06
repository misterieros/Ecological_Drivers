
for layer in QgsProject.instance().mapLayers().values():
    print(layer.name(Book1))

biodiversidad = QgsProject.instance().mapLayersByName("Book1")[0]
ambiental = QgsProject.instance().mapLayersByName("Datos_Canarias")[0]
