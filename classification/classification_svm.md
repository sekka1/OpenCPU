## Support Vector Machine Classifier
### Overview

Per Wikipedia: Classification is the problem of identifying to which of a set
of categories a new observation belongs, on the basis of a training set of data
containing observations whose category membership is known.

Support Vector Machines are supervised learning models with associated learning
algorithms that analyze data and recognize patterns, used for classification
and regression analysis. A SVM model is a representation of the examples as
points in space, mapped so that the examples of the separate categories are
divided by a clear gap that is as wide as possible. New examples are then
mapped into that same space and predicted to belong to a category based on
which side of the gap they fall on.

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

We have 4 dimensional training data. The dimensions are "Voice Usage
(Minutes)", "Data Usage (MB)", "Support Calls" and "Payment Delay (Months)".
The data is labelled into two categories "FALSE" and "TRUE" indicating whether
it was closed.

Now let us see how this can be implemented on the Algorithms.io platform.

1. Download the [training
data](https://s3.amazonaws.com/sample_dataset.algorithms.io/customer_data_train.csv)
and the [testing
data](https://s3.amazonaws.com/sample_dataset.algorithms.io/customer_data_test.csv)

2.  [Upload](https://www.mashape.com/algorithms-io/algorithms-io#endpoint-Upload)
the files to algorithms.io.  Once uploaded, you will see a responses that look
like this
>   { "api": { "Authentication": "Success" }, "data": 3324 } # For training
>   { "api": { "Authentication": "Success" }, "data": 3325 } # For testing

3. Run classification using [Support Vector
Machines](https://www.mashape.com/algorithms-io/algorithms-io#endpoint-Support-Vector-Machine)
or do that using a this curl command

>		curl --include --request POST 'https://algorithms.p.mashape.com/jobs/swagger/<whatever>' \
>		--header 'X-Mashape-Authorization: <your Mashape header here>' \
>		-d 'method=sync' \
>		-d 'ouputType=json' \
>		-d 'train=3324' \
>		-d 'test=3325'

The output will be a json list of the predicted categories for each row in the
test data.
