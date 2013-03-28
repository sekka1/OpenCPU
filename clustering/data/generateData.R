set.seed(1);
numCustomers <- 1000;
age = as.integer(runif(numCustomers,13,60))
income = rlnorm(numCustomers, 4, .5) * 1000
voice.minutes <- as.integer(rlnorm(numCustomers,4,1.5))
data.usage <- as.integer(rlnorm(numCustomers,4,1.5))
data <- data.frame(age, income, voice.minutes, data.usage);
write.csv(data, file='customer_data.csv')
