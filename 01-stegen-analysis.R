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

ggplot(stegen) + 
  geom_histogram(aes(x = age), binwidth = 1)
ggplot(stegen) + 
  geom_histogram(aes(x = age, fill = sex), binwidth = 1)

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

## Looking at distribution of cases by gender using graph

ggplot(stegen) + 
  geom_histogram(aes(x = age, fill = ill), binwidth = 1) +
  scale_fill_manual("Illness", values = c("non case" = "#66cc99", "case" = "#993333")) +
  facet_wrap(~sex, ncol = 1) + # stratify the sex into a single column of panels
  labs(title = "Cases by age and gender") + 
  theme_light()


## Looking for the food that highly associated with the outbreak

stegen <- readRDS(stegen_clean_rds)
head(stegen)
names(stegen)
food <- c('tiramisu', 'wmousse', 'dmousse', 'mousse', 'beer', 'redjelly',
          'fruit_salad', 'tomato', 'mince', 'salmon', 'horseradish',
          'chickenwin', 'roastbeef', 'pork') 
food
stegen[food]


pork_table <- epitable(stegen$pork, stegen$ill)
pork_table

pork_rr <- riskratio(pork_table, correct = T, method = "wald")
pork_rr
pork_rr$measure
pork_est_ci <- pork_rr$measure[2, ]
pork_est_ci

pork_p <- pork_rr$p.value[2, "fisher.exact"]
pork_p

res <- data.frame(estimate = pork_est_ci["estimate"],
                  lower    = pork_est_ci["lower"],
                  upper    = pork_est_ci["upper"],
                  p.value  = pork_p
)
res


## Testing association between age and illness

bartlett.test(stegen$age ~ stegen$ill)
t.test(stegen$age ~ stegen$ill, var.equal = TRUE)


## Testing association between illness and gender

tab_sex_ill <- table(stegen$sex, stegen$ill)
tab_sex_ill
prop.table(tab_sex_ill)
round(100 * prop.table(tab_sex_ill))
chisq.test(tab_sex_ill)


## Writing a function for consolidating several steps into one simple step

et <- epitable(stegen$pork, stegen$ill)
rr <- riskratio(et)
estimate <- rr$measure[2,]
res <- data.frame(estimate = estimate["estimate"],
                  lower    = estimate["lower"],
                  upper    = estimate["upper"],
                  p.value  = rr$p.value[2, "fisher.exact"]
                  )
res

### The risk ratio function

srr <- function(exposure, outcome){
  et <- epitable(exposure, outcome)
  rr <- riskratio(et)
  estimate <- rr$measure[2,]
  res <- data.frame(estimate = estimate["estimate"],
                    lower    = estimate["lower"],
                    upper    = estimate["upper"], 
                    p.value  = rr$p.value[2, "fisher.exact"]
                    )
  return(res)
  
}


## Testing the new function that just created

pork_rr <- srr(stegen$pork, stegen$ill)
pork_rr
fruit_rr <- srr(stegen$fruit_salad, stegen$ill)
fruit_rr
bind_rows(pork = pork_rr, fruit = fruit_rr, .id = "exposure")


## Calculating all the risk ratio for all the potential cause using lapply and srr function 

all_rr <- lapply(stegen[food], FUN = srr, outcome = stegen$ill)
head(all_rr)

all_food_df <- bind_rows(all_rr, .id = "exposure")
all_food_df
all_food_df <- arrange(all_food_df, desc(estimate))
all_food_df

## Plotting the data farme using ggplot2

all_food_df$exposure <- factor(all_food_df$exposure, unique(all_food_df$exposure))

p <- ggplot(all_food_df, aes(x = estimate, y = exposure, color = p.value)) +
  geom_point() +
  geom_errorbarh(aes(xmin = lower, xmax = upper)) +
  geom_vline(xintercept = 1, linetype = 2) + 
  scale_x_log10() + 
  scale_color_viridis_c(trans = "log10") + 
  labs(x = "Risk Ratio (log scale)", 
       y = "Exposure",
       title = "Risk Ratio for gastroenteritis in Stegen, Germany")
p

#Plotting a basic spatial overview of cases

ggplot(stegen) +
  geom_point(aes(x = longitude, y = latitude, color = ill)) +
  scale_color_manual("Illness", values = c("non case" = "#66cc99", "case" = "#993333")) +
  coord_map()

stegen_shp <- read_sf(here("data", "stegen-map", "stegen_households.shp"))

ggplot(stegen) +
  geom_sf(data = stegen_shp) +
  geom_point(aes(x = longitude, y = latitude, color = ill)) + 
  scale_color_manual("Illness", values = c("non case" = "#66cc99", "case" = "#993333")) 


## Interactive maps

stegen_sub <- stegen[!is.na(stegen$longitude),]
lmap <- leaflet()
lmap <- addTiles(lmap)
lmap <- setView(lmap, lng = 7.963, lat = 47.982, zoom = 15)
lmap <- addPolygons(lmap, data = st_transform(stegen_shp,'+proj=longlat +ellps=GRS80'))
lmap <- addCircleMarkers(lmap, 
                         label = ~ill, 
                         color = ~ifelse(ill == "case", "#993333", "#66cc99"), 
                         stroke = FALSE,
                         fillOpacity = 0.8,
                         data = stegen_sub)
lmap
