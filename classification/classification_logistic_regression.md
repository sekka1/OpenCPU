# Logistic Regression Classifier
## Overview
### Description
[Logistic regression](http://en.wikipedia.org/wiki/Logistic_regression) is a
simple classification algorithm. It works by identifying an n-1 dimensional
hyperplane that separates an n dimensional space into two classes (which are on
either side of the plane).

It compares as follows with other classification algorithms

#### Advantages:
* Fast and efficient.
* Easy to interpret. The output can be thought of as the probability of an
  observation beloging in a particular class.

#### Disadvantages:
* Only works for 2 classes. Multi-class problems (with k classes) need to be
  modeled as k separate models each of which can differenciate between one
  class and everything else.
* Only works if the classes are linearly separable. Real world problems tend to
  be non-linear.

### Use Cases
General purpose classification

## Tags
supervised learning, classification, logistic regression, high performance, binary classifier

## Tutorial
### Customer Churn Example

Let us say that we are a mobile service provider and we wish to predict whether
a customer will close their account in the next 6 months based on their usage
patterns. Assume that we have historical (training) data about how they used
our service, and they are labeled based on whether the account was closed or
not.

#### Input

Sample data for this example can be download here: [training
data](https://s3.amazonaws.com/sample_dataset.algorithms.io/customer_data_train.csv)
, [testing
data](https://s3.amazonaws.com/sample_dataset.algorithms.io/customer_data_test.csv).

The data is formatted as a plain text CSV file with 5 columns. Here is what the
data looks like:

<table border="1">
<tr><td>Voice Usage (Minutes)</td><td>Data Usage (MB)</td><td>Support Calls</td><td>Payment Delay (Months)</td><td>Closed</td></tr>
<tr><td>3.20</td><td>22.85</td><td>0</td><td>1</td><td>FALSE</td></tr>
<tr><td>36.42</td><td>67.40</td><td>2</td><td>1</td><td>TRUE</td></tr>
<tr><td>5.44</td><td>148.13</td><td>1</td><td>0</td><td>FALSE</td></tr>
</table>

There are 4 predictive variables (input dimensions): "Voice Usage (Minutes)",
"Data Usage (MB)", "Support Calls" and "Payment Delay (Months)".  The the
dependent variable (the one we're trying to predict) is "Closed", which
indicates whether the account was closed. It takes the values "FALSE" and
"TRUE". Note that the "Closed" column must be present in the training data. 

The test set contains records for which we have access to the 4 dimensions
mentioned above and want to predict the dependent variable "Closed". If the
dependent variable is is present in the test data, it is ignored.

The data can now be uploaded to the algorithms.io system.

Upload the training data to to algorithms.io. You can do this using curl as follows:

> curl -i -X POST 'http://v1.api.algorithms.io/dataset' 
>      -H 'authToken: <YOUR AUTHORIZATION TOKEN>'  
>      -F theFile=@customer\_data\_train.csv

The response will look like

>   { "api": { "Authentication": "Success" }, "data": 3481 }

indicating that the training data was uploaded to dataset 3481.

Next upload the test data.

> curl -i -X POST 'http://v1.api.algorithms.io/dataset' 
>      -H 'authToken: <YOUR AUTHORIZATION TOKEN>'  
>      -F theFile=@customer\_data\_test.csv

The response will look like

>   { "api": { "Authentication": "Success" }, "data": 3482 }

indicating that the test data was uploaded to dataset 3482.

#### Execution
Run classifier aganist the two uploaded datasets.

> curl -X POST \
> -d 'method=sync' \
> -d 'outputType=json' \
> -d 'datasources=[]' \
> -d 'train={"datatype":"datasource","value":"3481"}' \
> -d 'test={"datatype":"datasource","value":"3482"}' \
> -d 'dependentVariable={"datatype":"string","value":"closed"}' \
> -H 'authToken: <YOUR AUTHORIZATION TOKEN>'  
> http://pod3.staging.v1.api.algorithms.io/jobs/swagger/43

#### Output

The output will be a json list of the predicted categories for each record in
the test data. In this case, it will look like

> [ "TRUE", "TRUE", "FALSE", ... ]

This indicates that the algorithm predicts that the first two accounts in the
test set will close, whereas the third one will not.
