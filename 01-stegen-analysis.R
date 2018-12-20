## Loading required library for this project

library("here")      # find data/script files
library("readxl")    # read xlsx files
library("readr")     # read and write text spreadsheets
library("incidence") # make epicurves
library("epitrix")   # clean labels and variables
library("dplyr")     # general data handling
library("ggplot2")   # advanced graphics
library("epitools")  # statistics for epi data
library("sf")        # shapefile handling
library("leaflet")   # interactive maps


##Loading dataset into R

path_to_data <- here("data", "stegen_raw.xlsx")


stegen <- read_excel(path_to_data)

View(stegen)



##Starting to do some preliminary exploratory analysis

dim(stegen)
names(stegen)
summary(stegen)

stegen$tiramisu
summary(stegen$tiramisu)
table(stegen$tiramisu)

table(stegen$tiramisu, useNA = "no")
table(stegen$tiramisu, useNA = "ifany")
table(stegen$tiramisu, useNA = "always")


## Doing some data cleaning before analysis

stegen_old <- stegen
new_labels <- clean_labels(names(stegen))
new_labels
names(stegen) <- new_labels

stegen$unique_key <- as.character(stegen$unique_key)
stegen$sex <- factor(stegen$sex)
stegen$ill <- factor(stegen$ill)
stegen$date_onset <- as.Date(stegen$date_onset)


stegen$sex <- recode_factor(stegen$sex, "0" = "male", "1" = "female")
stegen$ill <- recode_factor(stegen$ill, "0" = "non case", "1" = "case")

str(stegen$sex)
str(stegen$ill)

table(stegen$pork, useNA = "always")
table(stegen$salmon, useNA = "always")
table(stegen$horseradish, useNA = "always")


stegen$pork[stegen$pork == 9] <- NA
stegen$salmon[stegen$salmon == 9] <- NA
stegen$horseradish[stegen$horseradish == 9] <- NA

## Saving cleaning data into new directory

clean_dir <- here("data", "cleaned")
dir.create(clean_dir)

stegen_clean_file <- here("data", "cleaned", "stegen_clean.csv")
write_csv(stegen, path = stegen_clean_file)


stegen_clean_rds <- here("data", "cleaned", "stegen-clean.rds")
saveRDS(stegen, file = stegen_clean_rds)


## Data exploration and summary

summary(stegen$age)
summary(stegen$sex)
tapply(stegen$age, INDEX = stegen$sex, FUN = summary)
tapply(stegen$age, INDEX = stegen$sex, FUN = mean, na.rm = T)


### Using graph to explore data 

ggplot(stegen) + geom_histogram(aes(x = age), binwidth = 1)
ggplot(stegen) + geom_histogram(aes(x = age, fill = sex), binwidth = 1)

ggplot(stegen) + 
  geom_histogram(aes(x = age, fill = sex), binwidth = 1, color = "white") +
  scale_fill_manual(values = c(male = "#4775d1", female = "#cc6699")) +
  labs(title = "Age distribution by gender", x = "Age (years)", y = "Number of cases") +
  theme_light(base_family = "Times", base_size = 16) +
  theme(legend.position = c(0.8, 0.8))

## Calculating incidence using epicurves

i <- incidence(stegen$date_onset)
i
plot(i)
as.data.frame(i)


i_ill <- incidence(stegen$date_onset, group = stegen$ill)
i_ill
as.data.frame(i_ill)
plot(i_ill, color = c("non case" = "#66cc99", "case" = "#993333"))

plot(i_ill, border = "grey40", show_cases = TRUE, color = c("non case" = "#66cc99", "case" = "#993333")) + 
  labs(title = "Epicurve by case", x = "Date of onset", y = "Number of cases") +
  theme_light(base_family = "Times", base_size = 16) + # changes the overal theme
  theme(legend.position = c(x = 0.7, y = 0.8)) + # places the legend inside the plot
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1)) + # sets the dates along the x axis at a 45 degree angle
  coord_equal() # makes each case appear as a box
