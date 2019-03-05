library(tidyverse) #which includes dplyr
library(cluster)

#Read data from source - Header is not present, and empty data is marked as "", seperated by ","
#Data_0 <- read.table("C:/Users/driku/OneDrive/Documents/JCU/Subjects/Foundation for data science - MA580003/Capstone Project/TV/TV.csv", header = FALSE, na.strings = "", sep = ";")
Data_0 <- read.table("https://data.gov.au/dataset/559708e5-480e-4f94-8429-c49571e82761/resource/93a615e5-935e-4713-a4b0-379e3f6dedc9/download/tmpvhqhjztv20180202.csv", header = TRUE, na.strings = "", sep = ",")

nrow(Data_0) #[1] 3381

#Improted columns:
#1) Submit_ID, 2) Brand_Reg, 3) Model_No, 4) Family Name, 5) SoldIn, 6) Country, 
#7) screensize, 8) Scrren_Area, 9) Screen_Tech, 10)Pasv_stnd_power, 
#11) Act_stnd_power, 12) Avg_mode_power, 13) STar, 14) SRI, 15) CEC, 
#16) SubmitStatus, 17) ExpDate, 18) GrandDate, 19) Product Class, 
#20) Availability Status, 21) Star2, 22) Product Website, 
#23) Representative Brand URL, 24) Star Rating Index
#25) Star Image Large, 26) Star Iimage Small, 27) Power Supply, 
#28) Tuner Type, 29) What Test Standard was used, 30) Registration Number

#Explore data file
colnames(Data_0) #Revealed 31 columns
sapply(Data_0, class) #


#Wrangle Data to an acceptable tabular format
# Select only the relavant columns that will be analised. The rest of the columns do not contribute to the analyses. 
Data_1 <- select(Data_0, Brand_Reg, Screen_Tech, screensize, Act_stnd_power, Avg_mode_power, Star.Rating.Index )
rm(Data_0)

#Before we start data conversion, get rid of any records with empty values
Data_2 <- na.omit(Data_1)
nrow(Data_2) # [1] 2962
rm(Data_1)

#Assign names to variables
names(Data_2) <- c("Brand", "Technology", "Screensize", "Standby_PWR", "Active_PWR", "Energy_Rating_Index")

#Convert the diagnoal screensize dimensions from cm to inches and round up (dropping decimals, so user can better identify with screen sizes.)
Data_2$Screensize <- trunc(round((Data_2$Screensize / 2.54)))  # 1 inch = 2.54cm

#Rescale and translate Energy_Rating_Index to the consumer 5 star rating system of [1,6]
Star_min <- 1
Star_max <- 6
Data_2$Energy_Rating_Index <- ((Star_max-Star_min) * (Data_2$Energy_Rating_Index - min(Data_2$Energy_Rating_Index)) / (max(Data_2$Energy_Rating_Index) - min(Data_2$Energy_Rating_Index))) + Star_min
Data_2$Energy_Rating_Index <- trunc(round(Data_2$Energy_Rating_Index))

#Rename "SAMSUNG ELECTRONICS" to "SAMSUNG"
Data_2$Brand <- as.character(Data_2$Brand)
Data_2$Brand[Data_2$Brand == "SAMSUNG ELECTRONICS"] <- "SAMSUNG"


#Assign variable types
Data_2$Brand <- as.factor(Data_2$Brand) 
Data_2$Screensize <- as.numeric(as.character(Data_2$Screensize))
Data_2$Technology <- as.factor(Data_2$Technology) 
Data_2$Standby_PWR <- as.double(as.character(Data_2$Standby_PWR))
Data_2$Active_PWR <- as.double(as.character(Data_2$Active_PWR)) 
Data_2$Energy_Rating_Index <- as.double(as.character(Data_2$Energy_Rating_Index)) 

#...and round off to 2 decimals
Data_2$Screensize <- round(Data_2$Screensize, 2)
Data_2$Standby_PWR <- round(Data_2$Standby_PWR, 2)
Data_2$Active_PWR <- round(Data_2$Active_PWR, 2)
Data_2$Energy_Rating_Index <- round(Data_2$Energy_Rating_Index, 2)

#Summerize the resultant data frame.
summary(Data_2)

########################################################################################################
#Spearman

#Find the Gower dissimilarity matrix
Dist <- daisy(Data_2, metric = "gower")
Dist <- as.matrix(Dist)
dim <- ncol(Dist)  # used to define axis in image
image(1:dim, 1:dim, Dist, axes = FALSE, xlab="", ylab="", col = rainbow(100))
heatmap(Dist, Rowv=TRUE, Colv="Rowv", symm = TRUE)

#Heatmap

################################################################
#General info of top 10 registered brands
#Data_2 %>% 
#  group_by(Brand) %>% 
#  summarise(N = n(), mean(Screensize), sd(Screensize), mean(Energy_Rating_Index), sd(Energy_Rating_Index)) %>% 
#  arrange(desc(N)) %>% 
#  head(10)

#Info re. top 10 Screensizes registered
Data_2 %>% 
  group_by(Screensize) %>% 
  summarise(N = n(), mean(Active_PWR), mean(Energy_Rating_Index)) %>% 
  arrange(desc(N)) %>% 
  head(10)

#Info re. the different technologies that was registered. 
Data_2 %>% 
  group_by(Technology) %>% 
  summarise(N = n(), mean(Screensize), mean(Active_PWR), mean(Energy_Rating_Index)) %>% 
  arrange(desc(N))

#Info re. what Brand registered how many of what size screen
Data_2 %>% 
  group_by(Brand, Technology, Screensize) %>% 
  summarise(N = n()) %>% 
  arrange(desc(N)) %>% 
  head(10)

###########################################GGPLOT#####################################################
library(forcats)
ggplot(data=Data_2, aes(x=fct_infreq(Brand), fill = Data_2$Technology)) + geom_bar() + coord_flip()

#Bar chart plot - Top 10 registered brands
Data_2 %>% 
  group_by(Brand) %>% 
  summarise(N = n()) %>% 
  arrange(desc(N)) %>% 
  head(20) %>% 
  ggplot(aes(x = reorder(Brand, N), y = N)) + geom_bar(stat = "identity") + coord_flip()

#Scatter plot and regression - Screensize(diagonal - inches) vs. Active Power(W)
ggplot(data = Data_2) + 
  geom_point(mapping = aes(x = Screensize, y = Active_PWR, color = Technology)) + 
  geom_smooth(mapping = aes(x = Screensize, y = Active_PWR, color = Technology), method = "lm", se = FALSE) + 
  xlab("Screensize (diagonal - inches)") + 
  ylab("Active Power(W)") + 
  ggtitle("Scatterplot - Screensize vs. Active Power ")

#Scatterplot and regression - Screensize(diagonal - inches) vs. Standby Power(W)
ggplot(data = Data_2) + 
  geom_point(mapping = aes(x = Screensize, y = Standby_PWR, color = Technology)) + 
  geom_smooth(mapping = aes(x = Screensize, y = Standby_PWR, color = Technology), method = "lm", se = FALSE) + 
  xlab("Screensize (diagonal - inches)") + 
  ylab("Standby Power(W)") + 
  ggtitle("Scatterplot - Screensize vs. Standby Power ")

#Scatterplot and regression - Screensize(diagonal - inches) vs. Energy Rating Index
ggplot(data = Data_2) + 
  geom_point(mapping = aes(x = Screensize, y = Energy_Rating_Index, color = Technology)) + 
  geom_smooth(mapping = aes(x = Screensize, y = Energy_Rating_Index, color = Technology), method = "lm", se = FALSE) + 
  xlab("Screensize (diagonal - inches)") + 
  ylab("Energy Rating Index") + 
  ggtitle("Scatterplot - Screensize vs. Energy Rating Index ")

#Scatterplot and regression - Energy Rating Index vs. Standby Power(W)
ggplot(data = Data_2) + 
  geom_point(mapping = aes(x = Standby_PWR, y = Energy_Rating_Index, color = Technology)) + 
  geom_smooth(mapping = aes(x = Standby_PWR, y = Energy_Rating_Index, color = Technology), method = "lm", se = FALSE) + 
  xlab("Standby Power(W)") + 
  ylab("Energy Rating Index") + 
  ggtitle("Scatterplot - Energy Rating Index vs. Standby Power")

#Scatterplot and regression - Energy Rating Index vs. Active Power(W)
ggplot(data = Data_2) + 
  geom_point(mapping = aes(x = Active_PWR, y = Energy_Rating_Index, color = Technology)) + 
  geom_smooth(mapping = aes(x = Active_PWR, y = Energy_Rating_Index, color = Technology), method = "lm", se = FALSE) + 
  xlab("Active Power(W)") + 
  ylab("Energy Rating Index") + 
  ggtitle("Scatterplot - Energy Rating Index vs. Active Power")

#Scatterplot and regression - Stanby Power(W) vs. Active Power(W)
ggplot(data = Data_2) + 
  geom_point(mapping = aes(x = Active_PWR, y = Standby_PWR, color = Technology)) + 
  geom_smooth(mapping = aes(x = Active_PWR, y = Standby_PWR, color = Technology), method = "lm", se = FALSE) + 
  xlab("Active Power(W)") + 
  ylab("Standby Power (W)") + 
  ggtitle("Scatterplot - Standby Power vs. Active Power")

#Boxplot - Technology vs. Energy Rating Index
ggplot(data = Data_2, mapping = aes(x = Technology, y = Energy_Rating_Index)) +
  geom_boxplot(outlier.color = "red", outlier.shape = 3) + 
  geom_jitter(width = 0.1, alpha = 0.05, color = "blue") + 
  xlab("Technology") + 
  ylab("Energy Rating Index") + 
  ggtitle("Boxplot - Technology vs. Energy Rating Index")

#Boxplot - Technology vs. Active Power (W)
ggplot(data = Data_2, mapping = aes(x = Technology, y = Active_PWR)) + 
  geom_boxplot(outlier.color = "red", outlier.shape = 3) + 
  geom_jitter(width = 0.1, alpha = 0.05, color = "blue") + 
  xlab("Technology") + 
  ylab("Active Power (W)") + 
  ggtitle("Boxplot - Technology vs. Active Power")
###################################################################################################################
