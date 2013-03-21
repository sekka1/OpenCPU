## Support Vector Machine Classifier
### Overview

[Support Vector Machines](http://en.wikipedia.org/wiki/Support_vector_machine)
are supervised learning models with associated learning algorithms that analyze
data and recognize patterns, used for classification and regression analysis. A
SVM model is a representation of the examples as points in space, mapped so
that the examples of the separate categories are divided by a clear gap that is
as wide as possible. New examples are then mapped into that same space and
predicted to belong to a category based on which side of the gap they fall on.

### Customer Churn Example

Let us say that we are a mobile service provider and we wish to predict whether
a customer will close their account in the next 6 months based on their usage
patterns. Assume that we have historical (training) data about how they used
our service, and they are labeled based on whether the account was closed or
not. The data looks like:

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
> http://pod3.staging.v1.api.algorithms.io/jobs/swagger/49

4. Interpreting the results

The output will be a json list of the predicted categories for each record in
the test data. In this case, it will look like

> [ "TRUE", "TRUE", "FALSE", ... ]

This indicates that the algorithm predicts that the first two accounts in the
test set will close, whereas the third one will not.
