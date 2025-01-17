# Step 1: Install and Load Required Libraries
if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")

library(tidyverse)
library(caret)


# Step 2: Download the Movielens 10M Dataset
options(timeout = 120)

dl <- "ml-10M100K.zip"
if (!file.exists(dl)) {
  download.file("https://files.grouplens.org/datasets/movielens/ml-10m.zip", dl)
}



# Step 3: Unzip and Load the Data
ratings_file <- "ml-10M100K/ratings.dat"
if(!file.exists(ratings_file))
  unzip(dl, ratings_file)

movies_file <- "ml-10M100K/movies.dat"
if(!file.exists(movies_file))
  unzip(dl, movies_file)


# Step 4: Read and Process the Ratings Data
ratings <- as.data.frame(str_split(read_lines(ratings_file), fixed("::"), simplify = TRUE),
                         stringsAsFactors = FALSE)
colnames(ratings) <- c("userId", "movieId", "rating", "timestamp")
ratings <- ratings %>%
  mutate(userId = as.integer(userId),
         movieId = as.integer(movieId),
         rating = as.numeric(rating),
         timestamp = as.integer(timestamp))



# Step 5: Read and Process the Movies Data
movies <- as.data.frame(str_split(read_lines(movies_file), fixed("::"), simplify = TRUE),
                        stringsAsFactors = FALSE)
colnames(movies) <- c("movieId", "title", "genres")
movies <- movies %>%
  mutate(movieId = as.integer(movieId))


# Step 6: Merge Ratings and Movies Data
movielens <- left_join(ratings, movies, by = "movieId")




# Step 7: Create `edx` and `final_holdout_test` Sets
set.seed(1, sample.kind = "Rounding")  # Use sample.kind = "Rounding" for R 3.6 or later
# set.seed(1)  # For R 3.5 or earlier

# Split the data: 10% for final holdout test, 90% for edx
test_index <- createDataPartition(y = movielens$rating, times = 1, p = 0.1, list = FALSE)
edx <- movielens[-test_index, ]
temp <- movielens[test_index, ]



# Ensure that userId and movieId in the final holdout set are also present in the edx set
final_holdout_test <- temp %>%
  semi_join(edx, by = "movieId") %>%
  semi_join(edx, by = "userId")

# Add back rows that were removed from final holdout test set to the edx set
removed <- anti_join(temp, final_holdout_test)
edx <- rbind(edx, removed)

# Clean up
rm(dl, ratings, movies, test_index, temp, movielens, removed)



# Display Summary of `edx` and `final_holdout_test`
cat("Number of rows in edx:", nrow(edx), "\n")
cat("Number of rows in final_holdout_test:", nrow(final_holdout_test), "\n")
cat("Number of unique users in edx:", length(unique(edx$userId)), "\n")
cat("Number of unique movies in edx:", length(unique(edx$movieId)), "\n")
cat("Number of unique users in final_holdout_test:", length(unique(final_holdout_test$userId)), "\n")
cat("Number of unique movies in final_holdout_test:", length(unique(final_holdout_test$movieId)), "\n")

# Preview the edx dataset
#head(edx)
glimpse(edx)

edx %>% summarize(unique_users = length(unique(userId)),
                  unique_movies = length(unique(movieId)),
                  unique_genres = length(unique(genres)))

#RATINGS
ratings <- as.data.frame(str_split(read_lines("ml-10M100K/ratings.dat"), fixed("::"), simplify = TRUE), stringsAsFactors = FALSE)
colnames(ratings) <- c("userId", "movieId", "rating", "timestamp")
ratings <- ratings %>%
  mutate(userId = as.integer(userId),
         movieId = as.integer(movieId),
         rating = as.numeric(rating),
         timestamp = as.integer(timestamp))

# Plot 1: Histogram of Ratings Distribution
ggplot(ratings, aes(x = rating)) +
  geom_histogram(binwidth = 0.5, fill = "skyblue", color = "black") +
  labs(title = "Distribution of Movie Ratings", x = "Rating", y = "Count") +
  theme_minimal()


# Calculate the number of ratings greater than or equal to 3
rp <- edx %>% filter(rating >= 3)

# Calculate the proportion of such ratings
proportion <- nrow(rp) / nrow(edx)
cat("Proportion of ratings >= 3:", round(proportion, 4), "\n")


#TIMESTAMP
# Load required packages
if (!require(lubridate)) install.packages("lubridate", repos = "http://cran.us.r-project.org")
library(lubridate)

# Convert the timestamp to a readable date format and extract the year
edx <- edx %>%
  mutate(RatingDate = as.POSIXct(timestamp, origin = "1970-01-01"),
         RatingYear = year(RatingDate))

# Convert the timestamp in the validation_set to RatingDate and extract RatingYear
validation_set <- validation_set %>%
  mutate(RatingDate = as.POSIXct(timestamp, origin = "1970-01-01"),
         RatingYear = year(RatingDate))

# Preview the updated edx dataset
cat("edx dataset preview:\n")
head(edx)

# Preview the updated validation_set dataset
cat("\nvalidation_set dataset preview:\n")
head(validation_set)

range(edx$RatingYear)

edx$RatingYear <-as.numeric(edx$RatingYear)
str(edx)


# Plot the histogram of RatingYear
ggplot(edx, aes(x = RatingYear)) +
  geom_histogram(binwidth = 1, fill = "skyblue", color = "black") +
  labs(title = "Distribution of Ratings by Year", x = "Year", y = "Number of Ratings") +
  theme_minimal()

#GENRES

# Separate rows with multiple genres into individual rows for each genre
edx_genres <- edx %>%
  separate_rows(genres, sep = "\\|")  # Split genres by the '|' delimiter

# Summarize the total number of ratings and average rating for each genre
genre_summary <- edx_genres %>%
  group_by(genres) %>%
  summarize(
    Ratings_Sum = n(),
    Average_Rating = mean(rating, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(desc(Ratings_Sum))


# Plot the results using a bar chart
library(ggplot2)
ggplot(genre_summary, aes(x = reorder(genres, -Ratings_Sum), y = Ratings_Sum)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  coord_flip() +
  labs(
    title = "Total Number of Ratings per Genre",
    x = "Genre",
    y = "Number of Ratings"
  ) +
  theme_minimal()


# Load required libraries
if (!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
library(tidyverse)

# Calculate Ratings Sum and Average Rating per Genre, then sort by Average Rating
genre_summary <- edx_genres %>%
  group_by(genres) %>%
  summarize(
    Ratings_Sum = n(),
    Average_Rating = mean(rating, na.rm = TRUE),  # Calculate the average rating
    .groups = 'drop'
  ) %>%
  arrange(desc(Average_Rating))  # Arrange by Average Rating in descending order


# Plot the genres by average rating using a bar chart
library(ggplot2)
ggplot(genre_summary, aes(x = reorder(genres, Average_Rating), y = Average_Rating)) +
  geom_bar(stat = "identity", fill = "lightgreen") +
  coord_flip() +
  labs(
    title = "Average Rating by Genre",
    x = "Genre",
    y = "Average Rating"
  ) +
  theme_minimal()


#MOVIES

# Calculate the number of ratings for each movie
top_movies <- edx %>%
  group_by(movieId, title) %>%
  summarize(num_ratings = n()) %>%
  arrange(desc(num_ratings)) %>%
  slice_head(n = 50)  # Select the top 50 movies

# Display the top 50 movies in a table
top_movies %>%
  col.names = c("Movie ID", "Title", "Number of Ratings")

# Plot the top 50 movies using a bar chart
ggplot(top_movies, aes(x = reorder(title, -num_ratings), y = num_ratings)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  coord_flip() +  # Flip the axes for better readability
  labs(title = "Top 50 Most-Rated Movies", x = "Movie Title", y = "Number of Ratings") +
  theme_minimal()



# Install and load necessary packages
if (!require("stringr")) install.packages("stringr")
if (!require("dplyr")) install.packages("dplyr")
library(stringr)
library(dplyr)

# Feature Engineering: Extract Year from Movie Title
edx <- edx %>%
  mutate(release_year = as.numeric(str_extract(title, "\\(\\d{4}\\)"))) %>%
  # Handle NAs introduced during year extraction
  mutate(release_year = ifelse(is.na(release_year), 0, release_year)) # Replace NAs with 0

# Generate a table summarizing the most frequent years of movie releases
year_summary <- edx %>%
  count(release_year) %>%
  arrange(desc(n)) %>%
  head(10)

# Display the table
# Use colnames() to assign new column names
colnames(year_summary) <- c("Release Year", "Number of Movies")
print(year_summary)

# Insights: Top 10 most frequent movie release years
cat("Insight: The top 10 most frequent years of movie releases indicate popular eras of filmmaking.")

# Split edx Data into Training and Validation Sets
set.seed(1, sample.kind = "Rounding")
index <- createDataPartition(edx$rating, p = 0.8, list = FALSE)
train_set <- edx[index, ]
validation_set <- edx[-index, ]


# Summary of Training and Validation Sets
training_summary <- data.frame(
  Set = c("Training", "Validation"),
  Rows = c(nrow(train_set), nrow(validation_set)),
  Unique_Users = c(length(unique(train_set$userId)), length(unique(validation_set$userId))),
  Unique_Movies = c(length(unique(train_set$movieId)), length(unique(validation_set$movieId)))
)

# Display the table
print(training_summary)


# Train Models on Training Set

mean_rating <- mean(train_set$rating)
baseline_rmse <- sqrt(mean((validation_set$rating - mean_rating)^2))
cat("Baseline RMSE:", baseline_rmse)

cat("\nThe baseline model achieved an RMSE of", round(baseline_rmse, 4),
    ", which serves as a benchmark for evaluating more complex models.")


# Regularized Movie + User Effects Model with Cross-Validation
lambdas <- seq(4, 6, 0.1)
rmses <- sapply(lambdas, function(lambda) {

  # Calculate movie effects (b_i)
  movie_avgs <- train_set %>%
    group_by(movieId) %>%
    summarize(b_i = sum(rating - mean_rating) / (n() + lambda))

  # Calculate user effects (b_u)
  user_avgs <- train_set %>%
    left_join(movie_avgs, by = "movieId") %>%
    group_by(userId) %>%
    summarize(b_u = sum(rating - mean_rating - b_i) / (n() + lambda))

  # Predict ratings on the validation set
  predictions <- validation_set %>%
    left_join(movie_avgs, by = "movieId") %>%
    left_join(user_avgs, by = "userId") %>%
    mutate(pred = mean_rating + b_i + b_u) %>%
    pull(pred)

  return(sqrt(mean((validation_set$rating - predictions)^2)))
})



#Final Model Evaluation on final_holdout_test


# Train the final model on the entire edx dataset
mean_rating <- mean(edx$rating)

movie_avgs <- edx %>%
  group_by(movieId) %>%
  summarize(b_i = sum(rating - mean_rating) / (n() + lambda))

user_avgs <- edx %>%
  left_join(movie_avgs, by = "movieId") %>%
  group_by(userId) %>%
  summarize(b_u = sum(rating - mean_rating - b_i) / (n() + lambda))

# Predict on the final_holdout_test set
final_predictions <- final_holdout_test %>%
  left_join(movie_avgs, by = "movieId") %>%
  left_join(user_avgs, by = "userId") %>%
  mutate(pred = mean_rating + b_i + b_u) %>%
  pull(pred)

final_rmse <- sqrt(mean((final_holdout_test$rating - final_predictions)^2))
cat("Final RMSE on holdout test set:", final_rmse)


cat("The final model achieved an RMSE of", round(final_rmse, 4),
    "on the final holdout test set, indicating good generalization performance.")
