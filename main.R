library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)
library(ggplot2)
library(RColorBrewer)

#Taking Data from API
datasets_url_champ <- "https://api.football-data.org/v2/competitions/2000/matches"
token <- "b2dbe56c7a2c44d7a44abc8b72c177c4"
response_champ <- GET(datasets_url_champ, add_headers("X-Auth-Token" = token))

datasets_champ <- content(response_champ, as = "text")
datasets_champ <- fromJSON(datasets_champ)

#Cleaning Data
matches <- datasets_champ$matches

data <- data.frame(stage = matches$stage, group = matches$group,
 scoreHT1 = matches$score$halfTime$homeTeam,
 scoreHT2 = matches$score$halfTime$awayTeam,
 scoreFT1 = matches$score$fullTime$homeTeam - matches$score$halfTime$homeTeam,
 scoreFT2 = matches$score$fullTime$awayTeam - matches$score$halfTime$awayTeam)

data2 <- data.frame(mutate(data, goalsHT = scoreHT1 + scoreHT2,
                           goalsFT = scoreFT1 + scoreFT2)) 
preclean_data <- filter(data2, stage == "GROUP_STAGE") 
clean_data <- preclean_data[c("group", "goalsHT", "goalsFT")] %>%
  group_by(group) %>%
  summarise(first_half = sum(goalsHT), second_half = sum(goalsFT), total = sum(goalsHT + goalsFT)) 
the_cleanest_data <- gather(clean_data, "time", "goals", 2:3)

#Visualization
axes <- ggplot(
  data = the_cleanest_data,
  mapping = aes(x = group, y = goals, group = time, fill = time))

axes + geom_bar(stat = "identity", position = "stack") +
  geom_label(aes(label = goals), position = "stack", vjust = 1.5, label.size = 0.5) +
  theme_classic() + scale_fill_brewer(palette = 11) +
  labs(title = "Total number of goals scored in each group in FIFA 2018 World Cup group stage") +
  geom_hline(yintercept = mean(clean_data$total), color = "black", size = 0.8)

