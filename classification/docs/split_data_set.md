# Split Data Set
- **[Overview](#Overview)**
  - **[Description](#Description)**
  - **[Use Cases](#UseCases)**
- **[Input](#Input)**
- **[Execution](#Execution)**
- **[Output](#Output)**

## <a id="Overview">Overview</a>
#### <a id="Description">Description</a>
This algorithm splits one dataset into two using random sampling. The
approximate fraction of records that should go into the first output dataset
can be controlled usnig an input variable. The remaining records are written to
the second output dataset.

#### <a id="UseCases">Use Cases</a>
The Split Data Set algorithm can be used for splitting one sample dataset into
train and test sets.

#### <a id="Input">Input</a>

First input your complete dataset into the system. This can be done using curl as follows:
		curl -i -X POST 'http://v1.api.algorithms.io/dataset' 
				-H 'authToken: YOUR\_AUTHORIZATION\_TOKEN'  
				-F theFile=@data.csv

The response will look like
		{ "api": { "Authentication": "Success" }, "data": 3481 }
indicating that the data was uploaded to dataset 3482.

#### <a id="Execution">Execution</a>
Run Split Data Set aganist the uploaded dataset.

		curl -X POST 
				-d 'method=sync' 
				-d 'outputType=json' 
				-d 'data="3481"' 
				-d 'fraction="0.5"' 
				-H 'authToken: YOUR\_AUTHORIZATION\_TOKEN'  
				http://v1.api.algorithms.io/jobs/swagger/50

#### <a id="Output">Output</a>

The output will be a json list of two elements, which are the dataset ids of the two generated datasources.

		[ "3482", "3483" ]
