# Anomaly Detection

- **[Overview](#Overview)**
  - **[Description](#Description)**
  - **[Use Cases](#use_cases)**
- **[Tutorial](#Tutorial)**
  - **[Input](#Input_Parameters)**
  - **[Execution](#Execution)**
  - **[Output](#Output_Parameters)**
  
## <a id="Overview">Overview</a>

#### <a id="Description">Description</a>
Anomaly detection refers to detecting patterns in a given data set that do not conform to an established normal behavior.  Among the main techniques used, unsupervised anomaly detection ones detect anomalies in an unlabeled test data set under the assumption that the majority of the instances in the data set are normal by looking for instances that seem to fit least to the remainder of the data set.

#### <a id="use_cases">Use Cases</a>####
- **Fraud Detection:** Identity potential fraudulent transactions
- **Intrusion Detection:** Detect network attacks and system vulnerabilities and defects

## <a id="Tutorial">Tutorial</a>
In this tutorial, we will demonstrate how to use Algorithms.io's platform to do this
## Suspicious Purchases

Let's get started.

#### <a id="Input_Parameters">Input</a>

First let's take a look at the purchase records
	
	"transaction","mins.after.midnight","amount","category"
	C5N5VRR6,1224,205.35,super market
	FUUYJ3VU,903,11.40,drug store
	2P4CP25Z,1037,46.0,restaurant
	ARFH5ILQ,226,74.90,clothing store
	7AYQPRY8,57,18.80,grocery
		..
		..
		..
	
Each row represent a purchase with an record id, the time of day it's made as minutes paste midnight, amount and category.  You can get a copy of this [sample dataset](https://s3.amazonaws.com/sample_dataset.algorithms.io/anomaly-sample.csv), and then [upload](http://catalog.algorithms.io/dashboard) this to algorithms.io.  

You can also use curl calls for these uploading like this:

	curl -i -H "authToken: YOUR_TOKEN" -H "friendly_name:anomaly-sample" -H "friendly_description:Sample data for anomaly detection" -H "version:1" -F theFile=@purchase-samples.csv http://v1.api.algorithms.io/dataset
	
Once uploaded, you will see a response that looks like this.  Note down the data set reference from response messages.

	{
		"api": {
    		"Authentication": "Success"
    	},
    	"data": <input>
	}
	
	
#### <a id="Execution">Execution</a>	
Now you are ready to rock!  Start the anomaly detection either by submitting [here](http://www.algorithms.io/dashboard/algodoc/id/52) or use a curl command like this 

	curl -X POST -d 'method=sync' -d 'outputType=json' -d 'dataset=3802' -d 'top=10' -H 'authToken: YOUR_TOKEN' http://v1.api.algorithms.io/jobs/swagger/52

In this example, a request is made to find top 10 anomalies in the dataset 3802
			
#### <a id="Output_Parameters">Output and Analysis</a>

Finally the output data will look like this.  Every purchase will be given an outlier score (as shown in the second column).  The higher it is, the more so transaction is identified as an outlier.   
In this example, you can see that the most anomalous transaction with a score 246868.9 is a clothing purchase of amount $980.50 made at 9:30am

transaction | score | mins after midnight | amount | category
------ | ------------- | ------------ | --------- | ---------
XKTVEQAX | 246868.9 |  570 | 980.50 | clothing store
TLB6M1RP | 211073.3 | 1372 | 337.90 |       air fare
9MIAFTY3 | 206267.6 | 1412 |  19.20 |        grocery
RYZXT0MK | 205615.8 | 1412 |  47.40 |   super market
74H47IQ7 | 204239.0 | 1407 |  72.80 |        grocery
7NFT06SA | 199549.6 | 1386 |  47.00 |        grocery
2H1WLHS1 | 190440.8 | 1346 | 105.60 |     car rental
G1LLSBWA | 187814.1 | 1335 |  55.50 |        grocery
Z24S9BZ5 | 182469.4 |  471 | 666.00 |       air fare
9KLANP8Q | 180514.2 | 1298 |  21.85 |     drug store


