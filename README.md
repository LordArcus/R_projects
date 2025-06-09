# This is small data analysis project where i have done web scraping, data cleaning and data analysis

Data source: https://salaries.texastribune.org/search/?q=Department+of+public+sefty

web scraping reference : https://youtu.be/Dkm1d4uMp34?si=VngpPnkiW3um3Uhe

There are 3 stages in this project:

1. Web scraping:
    Used Rvest and Rselenium to fetch data of 5000 employee from website. Basically, using Rselenium i've created virtual client that automated firefox browser to search for given website and pressed next to read next page (we had 200 page).
     Whereas, using Rvest i've read each page as table and stored on the list until the page ended.

2. Data cleaning:
   Firstly stored data into dataframe. Then, check for null values but there's none. Afterward, i have dropped 2 duplicates. Also, Changed names of columns to meaningful and smaller words. Moreover, Changed the format of "salary" to numeric
    so that we could perform mathematical operations such as mean and median. I have found there are multiple person with same name but with different department and salary. So names in this data are not unique. 

3. Data analysis:

   - There were 27 departments, 4998 employees and their salary ranges from $113k to almost $400k

   - Top 3 Departments: Texas Department of Transportation, Comptroller of Public Accounts, Judiciary Section, Department of Public Safety 
      Account for 60.5 % of data.

   - Highest-cost department: Texas Department of Transportation spends $184,122,183 annually.
  
   - Teacher Retirement System has wide pay ranges ($113K to almost $400k annually)
  
   - Identified 207 employees (4.1% of our workforce) whose salaries significantly deviate from their department norms.
  
   - Top 1% earners make > $261,253  and Bottom 10% earners make < $114,550
  

Key Insights:
  - Top earners or buttom earners might leave if they’re underpaid compared to other companies so adjust their pay if needed. 
  - There is wide pay range for Teacher Retirement system. So, further analysis is needed to explain fairness. Adjustment is needed in salary if unfair. This will increase morale and interest of employee.
  - Those outliars needs to be checked (might be overpaid or underpaid)
