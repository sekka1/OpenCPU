set.seed(1);
numUsers <- 1000;

usage_minutes <- rlnorm(numUsers, 2, 1);
usage_data <- rlnorm(numUsers, 4, 1);
support_calls <- rpois(numUsers, 2);
payment_delay <- floor(rlnorm(numUsers, 0.2, 0.4));
pain <- usage_minutes + usage_data ^ 0.5 + support_calls ^ 3 + payment_delay * usage_minutes * usage_data;
error <- rnorm(numUsers, 0, quantile(pain, 0.2));
closed <- pain + error > quantile(pain, 0.9);
data <- data.frame(usage_minutes, usage_data, support_calls, payment_delay, closed);

trainSelect <- sample(c(T,F), size=numUsers, prob=c(0.7, 1-0.7), replace=T);
train <- data[trainSelect,];
test <- data[!trainSelect,]; # !(names(train) %in% 'closed')];
write.csv(train, 'customer_data_train.csv');
write.csv(test, 'customer_data_test.csv');
