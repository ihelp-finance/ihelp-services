# iHelp Protocol Services

[![release](https://github.com/ihelp-finance/ihelp-services/actions/workflows/release.yml/badge.svg)](https://github.com/ihelp-finance/ihelp-services/actions/workflows/release.yml)

This repo is the starting point for deploying the entire iHelp Protocol and run in either development or production modes.

Pull down the services from their respective repos:
```
./servicePrep.sh
```

Use the provided environment template to set your network parameters. NOTE - the default parameters should be enough to run yarn chain on localhost, but in order for the liquidity pools to work for the swapper, please provide the TEST_FORK url env variable with your providers rpc address (i.e. infura):
```
cp env/env.template env/.env
vim env/.env
```

### Development Mode

Use nvm to install and use node v16:
```
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
nvm install v16
nvm use v16
```

Install the contract dependencies and start the local chain:
```
cd ihelp-contracts
yarn install
yarn chain
```

In a separate terminal, deploy the contracts to the local chain:
```
yarn deploy
```

Start the dapp in local mode (docker):
```
cd ../ihelp-app

# install docker (if not installed already)
# curl -fsSL https://get.docker.com -o get-docker.sh
# sh get-docker.sh
# on mac or windows, you can also use Docker Desktop

# create the starter db so there is some data in the database for dev purposes
cd modules/postgresql
tar xzvf starter_db.tgz
cd ../../

# start the docker container
./start.sh

# inside the docker container install the node modules
yarn install
cd client
yarn install
cd ../

# start the server and client apps
npm start
```

After starting the service, you can access the app at http://localhost:8000.

### Production Mode

Build the various services docker containers:
```
./serviceBuildAll.sh
```

Deploy on a desired network on a specific listener port:
```
./deploy.sh kovan 30000
```

The service should be available on http://localhost:30000 of the deployed worker node running the router service.
