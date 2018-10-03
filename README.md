# Sample Project

Create a script in either Ruby or Python that performs the following functions:
1.    Accept a single argument from the command line and store it in a variable named region_filter. If the value of region_filter contains any characters other than a-z, 0-9, or -, exit with an error stating that the provided region must contain only those allowed characters.
2.    Programmatically create three directories: incoming, ec2_by_region, ec2_filtered
3.    Retrieve the AmazonAWS IP ranges file at  https://ip-ranges.amazonaws.com/ip-ranges.json
4.    Save the retrieved file into the incoming directory as ip-ranges.json
5.    Parse the ip-ranges.json file and extract all objects that belong to the EC2 service
6.    For each extracted object, insert a new key/value pair. Use "id" as the key and generate a UUID as the value.
7.    For each object's ip_prefix value, increment the second number in the dotted quad by 10, for example, 10.11.12.0/24 results in 10.21.12.0/24
8.    For each region, create a JSON file in the ec2_by_region directory named region.json and store the modified objects (from steps 5, 6, and 7) for that region into the JSON file. For example, the modified objects assigned to the us-east-1 region would be stored in ec2_by_region/us-east-1.json
9.    For the region specified in region_filter (from step 1), create a file in the ec2_filtered directory for each modified object (from steps 5, 6, and 7) that belongs to the region and write the object to the file. The filename should be the object's UUID with a json extension, for example ec2_filtered/bb38da8d-e7a2-4592-9497-3c607fdde815.json

Use any gems or modules you'd like.
Please provide whatever Ruby or Python files you create in a zipped file.

Extra credit: For the modified objects (from steps 5, 6, and 7) belonging to the region specified in region_filter, create a new JSON formatted file in the ec2_by_region directory named extra_credit.json and fill it with an array of consolidated adjoining networks, for example, if the list contains 10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24, store a single value of 10.0.0.0/22 in place of these four records.

