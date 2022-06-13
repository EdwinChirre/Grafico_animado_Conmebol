##########################################################
# CAMINO A LA CLASIFICACION DEL MUNDIAL
#########################################################

library(ggplot2) #Para los graficos
library(dplyr) #para la manipulacion de los datos
library(tidyverse) #para la manipulacion de datos
library(rvest) #para scrappear
library('data.table') #para data table


rm(list = ls())


# Scrapping  --------------------------------------------------------------

url_wiki <- "https://es.wikipedia.org/wiki/Clasificaci%C3%B3n_de_Conmebol_para_la_Copa_Mundial_de_F%C3%BAtbol_de_2022"

tablas_suda <- url_wiki %>% 
  read_html() %>% 
  html_nodes("table") %>% 
  #  .[2] %>% #agrego porque se que es la segunda tabla de la lista
  html_table(fill = TRUE) 



# Tabla de posiciones -----------------------------------------------------


posicion <- as.data.frame(tablas_suda[13])

# Dando el nombre a las columnas
colnames(posicion) <- c("Seleccion",paste0("Fecha",seq(1,18,1)))

# Estructurando la tabla

library('data.table')

dt_posicion <- melt(posicion, id = "Seleccion")


# Tabla de puntos por fechas ----------------------------------------------

# Primera ronda

ptos_1 <- as.data.frame(tablas_suda[14])

ptos_1$FechaFin <- paste0("Fecha",rep(1:9, each=5))

ptos_1$score <- substr(ptos_1$Resultado,1,3)

ptos_1 <- ptos_1 %>% separate(score, c('Local', 'Visita'), sep=":")

ptos_1$Local <- as.numeric(ptos_1$Local)
ptos_1$Visita <- as.numeric(ptos_1$Visita)

ptos_1$pto_local <- ifelse(
  is.na(ptos_1$Local) == T,0,
  ifelse(ptos_1$Local == ptos_1$Visita,1,
         ifelse(ptos_1$Local > ptos_1$Visita,3,0
         )))


ptos_1$pto_visita <- ifelse(
  is.na(ptos_1$Visita) == T,0,
  ifelse(ptos_1$Local == ptos_1$Visita,1,
         ifelse(ptos_1$Visita > ptos_1$Local,3,0
         )))


ptos_1_local <- ptos_1[,c(8,3,11)]
ptos_1_visita <- ptos_1[,c(8,7,12)]

colnames(ptos_1_local) <- c("Fecha","Seleccion","Puntos")
colnames(ptos_1_visita) <- c("Fecha","Seleccion","Puntos")

ptos_1 <- rbind(ptos_1_local,ptos_1_visita)

# La segunda ronda

ptos_2 <- as.data.frame(tablas_suda[15])

ptos_2$FechaFin <- paste0("Fecha",rep(10:18, each=5))

ptos_2$score <- substr(ptos_2$Resultado,1,3)

ptos_2 <- ptos_2 %>% separate(score, c('Local', 'Visita'), sep=":")

ptos_2$Local <- as.numeric(ptos_2$Local)
ptos_2$Visita <- as.numeric(ptos_2$Visita)

ptos_2$pto_local <- ifelse(
  is.na(ptos_2$Local) == T,0,
  ifelse(ptos_2$Local == ptos_2$Visita,1,
         ifelse(ptos_2$Local > ptos_2$Visita,3,0
         )))


ptos_2$pto_visita <- ifelse(
  is.na(ptos_2$Visita) == T,0,
  ifelse(ptos_2$Local == ptos_2$Visita,1,
         ifelse(ptos_2$Visita > ptos_2$Local,3,0
         )))


ptos_2_local <- ptos_2[,c(8,3,11)]
ptos_2_visita <- ptos_2[,c(8,7,12)]

colnames(ptos_2_local) <- c("Fecha","Seleccion","Puntos")
colnames(ptos_2_visita) <- c("Fecha","Seleccion","Puntos")

ptos_2 <- rbind(ptos_2_local,ptos_2_visita)

# Uniendo ronda 1 y ronda 2

df_ptos <- rbind(ptos_1,ptos_2)

df_ptos$fecha_num <- as.numeric(substr(df_ptos$Fecha,6,length(df_ptos$Fecha)))

df_ptos <- arrange(df_ptos,(fecha_num),Seleccion)

#Corrigiendo la tabla por la reprogramacion de la fecha 5 y 6 

df_part1 <- df_ptos[1:40,]
df_part2 <- df_ptos[61:90,]
df_part3 <- df_ptos[51:60,]
df_part4 <- df_ptos[91:110,]
df_part5 <- df_ptos[41:50,]
df_part6 <- df_ptos[111:nrow(df_ptos),]

df_ptos <- rbind(df_part1,df_part2,df_part3,df_part4,df_part5,df_part6)

df_ptos$num_partido <- paste0("Fecha",rep(1:18, each=10))


#Se hace una tabla para generar los puntos acumulados por fechas
df_ptos_final <- df_ptos %>% dplyr::group_by(Seleccion) %>% 
  dplyr::mutate(ptos = cumsum(Puntos)) %>% 
  arrange(-ptos)

df_ptos_final <- df_ptos_final[,c(5,2,6)]

names(df_ptos_final)[names(df_ptos_final) == 'ptos'] <- 'Puntos'
names(df_ptos_final)[names(df_ptos_final) == 'num_partido'] <- 'Fecha'


# Uniendo ambas tablas ----------------------------------------------------
# tabla de posiciones y puntos acumulados


head(df_ptos_final)
head(dt_posicion)

colnames(dt_posicion) <- c("Seleccion","Fecha","Posicion")

df_final <- left_join(dt_posicion,df_ptos_final, by =c("Seleccion","Fecha"))

# labels <- c()
# for (i in 1:length(df_final$Seleccion)){
#   
#   img.name <- df_final$Seleccion[i]
#   
#   labels <- c(labels, paste0(paste0("Imagenes/",df_final$Seleccion[i],".png")))
#   
# }
# 
# labels

# library(magick)
# a <- image_read(labels[5])
# 
# df_final$imagen <- labels



# Agregar emoji de banderas -----------------------------------------------

# Primero se agrega el codigo de pais

#install.packages("countrycode") #para colocar el codigo de pais
#devtools::install_github('rensa/ggflags') #para instalar los emojis de banderas
library(ggflags) # para colocar el codigo de pais
library(countrycode)  #para instalar los emojis de banderas


# añadimos una columna más a la tabla dt_ultimos con el cod pais en mimnuscula

df_final$code<-tolower(countrycode(ifelse(df_final$Seleccion == "Brasil","Brazil",
                                          ifelse(df_final$Seleccion == "Perú","Peru",df_final$Seleccion)),origin = 'country.name', destination = 'iso2c'))




library(magick) # para leer imagen
logo_qatar <- image_read("Imagenes/logo_mundial_qatar.png")
#logo_qatar <- image_scale(logo_qatar, "x90")



# Generar la imagen en movimiento -----------------------------------------

library(ggimage) #agregar foto en el grafico
library(scales) 
library(cowplot) #para el tema (theme)
library(tictoc)
library(gganimate)
library(janitor)



staticplot = 
  ggplot(df_final,aes(Posicion, group = Seleccion,country = code,
                      fill = as.factor(Seleccion), color = as.factor(Seleccion))) +
  geom_tile(aes(y = Puntos/2,
                height = Puntos,
                width = 0.9), alpha = 0.8, color = NA) +
  geom_text(aes(y = 0, label = paste(Posicion,Seleccion, " ")), vjust = 0.2, hjust = 1,size = 5.5) +
  geom_text(aes(y=Puntos+2.8,label = as.character(Puntos), hjust=0),size = 7) +
  ggflags::geom_flag(aes(y = Puntos + 0.3), size = 12)+
   
  
  coord_flip(clip = "off", expand = FALSE) +
  scale_y_continuous(labels = scales::comma) +
  # ggimage::geom_image(aes(x = Puntos, Image = file.path("Imagenes/", paste0(Seleccion,'.png'))), y = 0,
  #            size = 0.01, hjust = 1,
  #            inherit.aes = FALSE) +
  # 

  scale_x_reverse() +
  guides(color = "none", fill = "none") +
  theme_cowplot(8)+
  theme(axis.line=element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        legend.position="none",
        panel.background=element_rect(fill = '#fff7e6'),#element_blank(),
        
        panel.border=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),
        panel.grid.major.x = element_line( size=.1, color="white" ),
        panel.grid.minor.x = element_line( size=.1, color="white" ),
        #bold,italic x2
        plot.title=element_text(size=26, hjust=1.6, face="plain", colour="black", vjust=6),
        #plot.subtitle=element_text(size=22, hjust=1.2, vjust = -70, face="bold", color="gray"),
        plot.subtitle=element_text(size=23, hjust=0.5, vjust = 4.5, face="bold", color="gray"),
        plot.caption =element_text(size=12, hjust=-2, face="italic", color="dark gray"),
        plot.background=element_rect(fill = '#fff7e6'), #element_blank(),
        plot.margin = margin(2,2, 2, 4, "cm"))


anim = staticplot + 
  
  annotation_raster(logo_qatar, xmin = 0.5, xmax = 2.8, ymin = 40, ymax = 55) +
  
  #draw_image(logo_conmebol,x = 1.3, y = 0.4) +
  transition_states(as.numeric(substr(Fecha,6,length(Fecha))),
                    transition_length = 4, state_length = 1) +
  ease_aes("cubic-in-out") +
  #view_follow(fixed_x = TRUE)  +
  labs(title = 'La lucha por un cupo para Qatar',
       subtitle  =  "Jornada : {closest_state}",
       caption  = "Elaboración: Edwin Chirre | Fuente: Wikipedia | Hecho en R")

anim



# Guardando en gif y mp4 --------------------------------------------------

# Guardar en formato gif
animate(anim, 100, fps = 6.5,  #width = 600, height = 500,
        renderer = gifski_renderer("evol_posiciones_conmebol.gif"))


# Guardarlo como video en mp4

#install.packages("av")
library(av)

# Guarar en formato mp4 (video)
animate(anim, 100, fps = 6.5,  #width = 600, height = 500,
        renderer = av_renderer('evol_posiciones_conmebol.mp4')) 


