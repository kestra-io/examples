# Data Orchestration with Kestra

This repository will:
1. Help you **get started** with Kestra
2. Provide examples of how to **use Kestra**
3. Provide examples of how to **integrate** Kestra with Infrastructure as Code tools, Modern Data Stack products, and public cloud provider services
4. Share **best practices** for managing data workflows across environments so that moving from development to production is as easy as possible without sacrificing security or reliability

## Getting started video explaining key concepts

Link to the video: https://youtu.be/yuV_rgnpXU8

## How to install Kestra

Download the Docker Compose file:

```sh
curl -o docker-compose.yml https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
```

Start Kestra:

```sh
docker-compose up
```

![install.png](images/install.png)


## How to use Kestra

Here is a Hello-World example:

```yaml
id: hello  
namespace: prod
tasks:
  - id: hello-world
    type: io.kestra.core.tasks.log.Log
    message: Hello world!
```

## How to run Bash and Python tasks

Here is an example of a Bash task:

```yaml
id: hello  
namespace: prod
tasks:  
  - id: bash-task
    type: io.kestra.core.tasks.scripts.Bash
    description: create a CSV file
    commands:
      - echo "order_id,total_amount" > output.csv
      - echo "1,100" >> output.csv
      - echo "2,200" >> output.csv
      - echo "3,300" >> output.csv
  
  - id: python-task
    type: io.kestra.core.tasks.scripts.Python
    description: Get the current Bitcoin price
    inputFiles:
      main.py: |
        import requests
        
        url = "https://api.coindesk.com/v1/bpi/currentprice/BTC.json"
        response = requests.get(url)
        data = response.json()
        price = data['bpi']['USD']['rate']
        print(price)
    requirements:
      - requests
    runner: DOCKER
    dockerOptions:
      image: python:3.11-slim
      pullImage: true # set to false if you have it already
```        

### Custom Docker image per task 

If you prefer to run the Python or Bash task in a (_potentially custom_) Docker container:

```yaml
  - id: python-container-cli
    type: io.kestra.core.tasks.scripts.Bash
    commands:
      - python main.py
    runner: DOCKER
    dockerOptions:
      image: your_custom_pulled_image:latest
      pullImage: false
```

Using `dockerOptions` you can also configure credentials to remote Docker registries.


### Docker image with `requirements.txt` installed at runtime 


```yaml
  - id: python-container
    type: io.kestra.core.tasks.scripts.Python
    inputFiles:
      main.py: |
        import pandas as pd
        import requests
        
        print(pd.__version__)
        print(requests.__version__)
    requirements:
      - requests
      - pandas
    runner: DOCKER
    dockerOptions:
      image: python:3.11-slim
```


## How to integrate Kestra with IaC: CI/CD with Terraform

Coming soon.
