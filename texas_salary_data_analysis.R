# Importing necessary libraries
library(RSelenium)
library(rvest)
library(tidyverse)
library(netstat)
library(data.table)
library(gridExtra)
library(scales)  
library(treemap) 
library(plotly) 


#===================================================== Web Scrapping =============================================================

# At the start of your script
try({rD$server$stop()}, silent = TRUE) # Try to stop any existing server


# Start RSelenium server with Firefox
rD <- rsDriver(
  browser = "firefox",  # Use Firefox
  chromever = NULL,     # Not needed for Firefox
  verbose = FALSE,     # Reduce console output
  port = free_port(),
  phantomver = NULL
)

# Setting up the remote driver
remDr <- rD$client

url <- "https://salaries.texastribune.org/search/?q=Department+of+public+sefty"

# Navigate to the desired URL
remDr$navigate(url)

# Wait for the page to load
Sys.sleep(5)  # Adjust sleep time as necessary

# Locating the table
data_table <- remDr$findElement(using = 'id', 'pagination-table')

# Defining the list to store all the records
all_data <- list()

# Initialize a condition to control the loop
cond <- TRUE

while (cond == TRUE) {
  # get the page source
  data_table_html <- data_table$getPageSource()
  
  # get page in text format
  page <- read_html(data_table_html %>% unlist())
  
  # Extract the table from the HTML
  df <- html_table(page)[[1]]
  
  # concatenate the data
  all_data <- rbindlist(list(all_data, df))
  
  Sys.sleep(0.2)  # Wait for the next page to load
  
  # Check if there is a next button and click it
  tryCatch(
    {
      # go to next table
      next_button <- remDr$findElement(using = "xpath", '//a[@aria-label="Next Page"]')
      next_button$clickElement()
    },
    error = function(e) {
      print("Script Complete!")
      cond <<- FALSE
    }
  )
  
  # Check if the condition to continue is still true
  if (cond == FALSE) {
    break
  }
  
}

# When done: Closing browser and server
remDr$close()
rD$server$stop()
rm(rD)
gc()

#========================================= End of Web Scrapping ========================================



#========================================= Data Cleaning ================================================

# Convert the list to a data frame
df <- data.frame(all_data)

# Rename the columns
colnames(df) <- c("name", "job_title", "department", "salary")


# Check duplicates
df <- df %>% distinct()

# Remove rows with NA values
df <- df %>% drop_na()

# Check na values
na_count <- sapply(df, function(x) sum(is.na(x)))

# Print NA count
print(na_count)

## Insights : 2 duplicates found and removed, no NA values found

# Convert salary to numeric
# remove "$" and "," from salary column and convert to numeric
df$salary <- as.numeric(gsub("[\\$,]", "", df$salary))

# Checking distinct names
dim(distinct(df["name"]))

## Insights : Name is not unique, means there are multiple employees with the same name, but they have different job titles and salaries.

# Checking distinct job titles
distinct(df["department"])

## Insights : There are 27 department.

unique(df["department"])

## Insights: "Comptroller of Public Accounts, State Energy Conservation Office" has most data 2211


#=============================================== End of Data Cleaning =================================================



#=============================================== Data Analysis ========================================================

# Summary of the data
summary(df)

# 1. Department Distribution head count
# Calculate headcount and percentage
dept_headcount <- df %>%
  group_by(department) %>%
  summarise(count = n()) %>%
  mutate(percentage = round(count / nrow(df) * 100, 1)) %>%
  arrange(desc(count))

# Visualize (Treemap for many departments)
treemap(dept_headcount,
        index = "department",
        vSize = "count",
        vColor = "percentage",
        title = "Employee Distribution by Department",
        palette = "Blues")

# Insight:
cat("Top 3 Departments:", paste(head(dept_headcount$department, 3), collapse = ", "), 
    "\nAccount for", sum(head(dept_headcount$percentage, 3)), "% of data.")



# 2.  Salary Cost Allocation by Department

# Total salary cost per department
dept_cost <- df %>%
  group_by(department) %>%
  summarise(total_salary = sum(salary)) %>%
  arrange(desc(total_salary))

# Waterfall chart (using ggplot2)
ggplot(dept_cost, aes(x = reorder(department, -total_salary), y = total_salary)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  scale_y_continuous(labels = dollar_format()) +
  labs(title = "Total Salary Cost by Department", x = "", y = "Total Salary ($)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Insight:
cat("Highest-cost department:", dept_cost$department[1], 
    "spends", dollar(dept_cost$total_salary[1]), "annually.")


# 3. Pay Equity: Boxplot by Department

# Boxplot (log scale for readability)
ggplot(df, aes(x = reorder(department, salary, FUN = median), y = salary)) +
  geom_boxplot(fill = "lightblue") +
  scale_y_log10(labels = dollar_format()) +
  coord_flip() +  # Flip for readability
  labs(title = "Salary Distribution by Department (Log Scale)", x = "", y = "Salary ($)")

# Insight:
cat("Teacher Retirement System has wide pay ranges")


# 4. Outlier detection 
# Flag outliers (>2 SD from department mean)
outliers <- df %>%
  group_by(department) %>%
  mutate(
    dept_mean = mean(salary),
    dept_sd = sd(salary),
    is_outlier = abs(salary - dept_mean) > 2 * dept_sd
  ) %>%
  filter(is_outlier) %>%
  select(name, department, salary, dept_mean)

# Print outliers
print(outliers)

# Insight:
cat("Found", nrow(outliers), "outliers. Check if they are justified (e.g., executives).")



# 5. Top/ Buttom earners
# Top 1% earners
top_1_percent <- df %>%
  arrange(desc(salary)) %>%
  slice_head(prop = 0.01)

# Bottom 10% earners
bottom_10_percent <- df %>%
  arrange(salary) %>%
  slice_head(prop = 0.1)

# Summary
cat("Top 1% earners make >", dollar(min(top_1_percent$salary)), 
    "\nBottom 10% earners make <", dollar(max(bottom_10_percent$salary)))

# 6.  visualized top earners
p <- ggplot(top_1_percent, aes(x = reorder(name, -salary), y = salary / 1000, 
                               fill = department,
                               text = paste("Name:", name, 
                                            "<br>Department:", department, 
                                            "<br>Salary:", dollar(salary)))) +
  geom_bar(stat = "identity") +
  labs(title = "Top 1% Earners (Hover for Details)", x = "", y = "Salary ($1000)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Convert to interactive plot
ggplotly(p, tooltip = "text")
# Insight:
cat("Top earners are from diverse departments, with salaries > $", 
    dollar(min(top_1_percent$salary)), ".")
#================================================= End of Data Analysis ===================================================


#================================================= Save Cleaned Data ====================================================

# Save cleaned data in CSV format
write.csv(df, "texas_salary_data.csv", row.names = FALSE)
