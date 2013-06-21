limit <- function(vec, lower=-Inf, upper=Inf) { vec[vec < lower] = lower; vec[vec > upper] = upper; vec; }
dereference <- function(vec) { sapply(vec, function(x) {scores[x]}); }

schools <- c('Stanford', 'CMU', 'MIT', 'Berkeley', 'Harvard', 'CalTech', 'UMD');
positions <- c('Intern', 'Developer', 'Manager', 'Architect', 'VP', 'BOA', 'BOD', 'Officer');
ranks <- c('Junior', 'RankUnknown', 'Senior', 'Principal');
departments <- c('Technical Support', 'QA', 'Marketing', 'Development', 'Finance', 'Sales', 'Professional Services', 'DeptUnknown');
companies <- c('IBM', 'HP', 'Cisco', 'Microsoft', 'Google', 'Apple', 'Facebook', 'Startup1', 'Startup2', 'Startup3');
scores <- list();

scores <- c(
sapply(schools, function(x) {which(x == schools)}),
sapply(positions, function(x) {scores[x] = which(x == positions)}),
sapply(ranks, function(x) {scores[x] = which(x == ranks)}),
sapply(departments, function(x) {scores[x] = which(x == departments)}),
sapply(companies, function(x) {scores[x] = which(x == companies)}))

#set.seed(1);
numUsers <- 1000;

school <- sample(schools, numUsers, replace=T)
startups <- rpois(numUsers, 1);
experience <- floor(rlnorm(numUsers, 2, 1));
position <- sample(positions, numUsers, replace=T)
rank <- sample(ranks, numUsers, replace=T)
department <- sample(departments, numUsers, replace=T)
company <- sample(companies, numUsers, replace=T)
score <- 10 * dereference(school) + 2 * ((startups - mean(startups))^ 2) + (experience - mean(experience))/10 + dereference(position) ^2 + 2 * dereference(rank) + dereference(department) / 2 + dereference(company) / 3
error <- rnorm(numUsers, 0, quantile(score, 0.2));
score <- score + error
data <- data.frame(school, startups, experience, position, rank, department, company, score)

trainSelect <- sample(c(T,F), size=numUsers, prob=c(0.7, 1-0.7), replace=T);
train <- data[trainSelect,];
test <- data[!trainSelect,]; # !(names(train) %in% 'closed')];
write.csv(train, 'founder_train.csv');
write.csv(test, 'founder_test.csv');

