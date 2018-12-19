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



##Starting to do some exploratory analysis

dim(stegen)
names(stegen)
summary(stegen)

stegen$tiramisu
summary(stegen$tiramisu)
table(stegen$tiramisu)

table(stegen$tiramisu, useNA = "no")
table(stegen$tiramisu, useNA = "ifany")
table(stegen$tiramisu, useNA = "always")
