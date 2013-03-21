## Compare Classifiers
### Overview

This "algorithm" compares the accuracy and performance of 5 different
classification algorithms. The algorithms that will be compared are

* Multinomial Logistic Regression
* Neural Network with 1 hidden layer
* Decision Tree
* Random Forest
* Support Vector Machine

The idea is that you start out with a common training and test set that will be
used to train each of these algorithms. Predictions are generated using each of
these algorithms and the results are compared with the *pre-labelled* test set.
Note that unlike the individual algorithms, the test set needs to be labelled.

### Customer Churn Example

Let us say that we are a mobile service provider and we wish to determine which
algorithm performs the best to predict whether a customer will close their
account in the next 6 months based on their usage patterns. Assume that we have
historical (training) data about how they used our service, and they are
labeled based on whether the account was closed or not. The data looks like:

<table>
<tr><td>Voice Usage (Minutes)</td><td>Data Usage (MB)</td><td>Support Calls</td><td>Payment Delay (Months)</td><td>Closed</td></tr>
<tr><td>3.20</td><td>22.85</td><td>0</td><td>1</td><td>FALSE</td></tr>
<tr><td>36.42</td><td>67.40</td><td>2</td><td>1</td><td>TRUE</td></tr>
<tr><td>5.44</td><td>148.13</td><td>1</td><td>0</td><td>FALSE</td></tr>
</table>

This is 4 dimensional training data, the dimensions being "Voice Usage
(Minutes)", "Data Usage (MB)", "Support Calls" and "Payment Delay (Months)").
The variable we're interested in (the dependent variable) is "Closed", which
indicates whether the account was closed or not. It takes the values "FALSE"
and "TRUE".

Now let us say that we have a test set. These are records for which we have
access to the 4 dimensions mentioned above and want to predict the dependent
variable (whether or not the account will close).

Here is a step by step tutorial on how to 

1. Download the [training
data](https://s3.amazonaws.com/sample_dataset.algorithms.io/customer_data_train.csv)
and the [testing
data](https://s3.amazonaws.com/sample_dataset.algorithms.io/customer_data_test.csv)

2.  Upload the training file to to algorithms.io. You can do this using curl as follows:

> curl -i -X POST 'http://v1.api.algorithms.io/dataset' 
>      -H 'authToken: <YOUR AUTHORIZATION TOKEN>'  
>      -F theFile=@customer_data_train.csv

The response will look like

>   { "api": { "Authentication": "Success" }, "data": 3481 }

indicating that the training data was uploaded to dataset 3481.

Next upload the test file.

> curl -i -X POST 'http://v1.api.algorithms.io/dataset' 
>      -H 'authToken: <YOUR AUTHORIZATION TOKEN>'  
>      -F theFile=@customer_data_test.csv

The response will look like

>   { "api": { "Authentication": "Success" }, "data": 3482 }

indicating that the training data was uploaded to dataset 3482.

3. Run classifier aganist the two uploaded datasets.

> curl -X POST \
> -d 'method=sync' \
> -d 'outputType=json' \
> -d 'datasources=[]' \
> -d 'train={"datatype":"datasource","value":"3481"}' \
> -d 'test={"datatype":"datasource","value":"3482"}' \
> -d 'dependentVariable={"datatype":"string","value":"closed"}' \
> -H 'authToken: <YOUR AUTHORIZATION TOKEN>'  
> http://pod3.staging.v1.api.algorithms.io/jobs/swagger/50

4. Interpreting the results

The output will be a json object with three 'parallel' arrays. The first has
the algorithms that were compared. The second shows the success rate for
predictions as compared with the labelled values in the test set. The third has
the time it took per record for each algorithm.

> {
>   "algos" : [
>       "MultinomialLogisticRegression",
>       "DecisionTree",
>       "NeuralNet",
>       "RandomForest",
>       "SVM"
>   ],
>   "success" : [
>       0.9403974,
>       0.9635762,
>       0.9403974,
>       0.9735099,
>       0.9503311
>   ],
>   "timePerRecord" : [
>       0.0005463576,
>       0.0002218543,
>       0.0006854305,
>       0.003135762,
>       0.000513245
>   ]
> }
