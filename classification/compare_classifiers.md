# Compare Classifiers
- **[Overview](#Overview)**
  - **[Description](#Description)**
  - **[Use Cases](#UseCases)**
- **[Tutorial](#Tutorial)**
  - **[Input](#Input)**
  - **[Execution](#Execution)**
  - **[Output](#Output)**

## <a id="Overview">Overview</a>
#### <a id="Description">Description</a>
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

#### <a id="UseCases">Use Cases</a>
Comparing classifiers with sample data prior to using one in production

## <a id="Tutorial">Tutorial</a>

### Customer Churn Example

Let us say that we are a mobile service provider and we wish to predict whether
a customer will close their account in the next 6 months based on their usage
patterns. Assume that we have historical (training) data about how they used
our service, and they are labeled based on whether the account was closed or
not. Before we decide on which classification algorithm to use, we might want
to compare the accuracy and processing time for the various available
classification algorithms with a small sample set.

#### <a id="Input">Input</a>

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

		curl -i -X POST 'http://v1.api.algorithms.io/dataset' 
				-H 'authToken: YOUR\_AUTHORIZATION\_TOKEN'  
				-F theFile=@customer\_data\_train.csv

The response will look like

		{ "api": { "Authentication": "Success" }, "data": 3481 }

indicating that the training data was uploaded to dataset 3481.

Next upload the test data.

		curl -i -X POST 'http://v1.api.algorithms.io/dataset' 
				-H 'authToken: YOUR\_AUTHORIZATION\_TOKEN'  
				-F theFile=@customer\_data\_test.csv

The response will look like

		{ "api": { "Authentication": "Success" }, "data": 3482 }

indicating that the test data was uploaded to dataset 3482.

#### <a id="Execution">Execution</a>
Run classifier aganist the two uploaded datasets.

		curl -X POST 
				-d 'method=sync' 
				-d 'outputType=json' 
				-d 'datasources=[]' 
				-d 'train="3481"' 
				-d 'test="3482"' 
				-d 'dependentVariable="closed"' 
				-H 'authToken: YOUR\_AUTHORIZATION\_TOKEN'  
				http://v1.api.algorithms.io/jobs/swagger/50

#### <a id="Output">Output</a>

The output will be a json list of the predicted categories for each record in
the test data. In this case, it will look like

		[ "TRUE", "TRUE", "FALSE", ... ]

This indicates that the algorithm predicts that the first two accounts in the
test set will close, whereas the third one will not.
