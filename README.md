# iHelp Protocol Services

[![release](https://github.com/ihelp-finance/ihelp-services/actions/workflows/release.yml/badge.svg)](https://github.com/ihelp-finance/ihelp-services/actions/workflows/release.yml)

This repo is the starting point for deploying the entire iHelp Protocol and run in either development or production modes.

Pull down the services from their respective repos:
```
./servicePrep.sh
```

Build the various services docker containers:
```
./serviceBuildAll.sh
```

Deploy on a desired network on a specific listener port:
```
./deploy.sh rinkeby 30000
```

The service should be available on http://localhost:30000 of the deployed worker node running the router service.
