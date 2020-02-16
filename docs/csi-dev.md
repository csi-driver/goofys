# goofys CSI driver development guide

 - Clone repo
```console
$ mkdir -p $GOPATH/src/sigs.k8s.io
$ git clone https://github.com/csi-driver/goofys-csi-driver $GOPATH/src/sigs.k8s.io
```

 - Build goofys driver
```console
$ cd $GOPATH/src/sigs.k8s.io/goofys-csi-driver
$ make goofys
```

 - Run verification before sending PR
```console
$ make verify
```

 - Build continer image and push to dockerhub
```console
export REGISTRY_NAME=<dockerhub-alias>
make push-latest
```

### Test locally using csc tool
Install `csc` tool according to https://github.com/rexray/gocsi/tree/master/csc:
```console
$ mkdir -p $GOPATH/src/github.com
$ cd $GOPATH/src/github.com
$ git clone https://github.com/rexray/gocsi.git
$ cd rexray/gocsi/csc
$ make build
```

#### Start CSI driver locally
```console
$ cd $GOPATH/src/sigs.k8s.io/goofys-csi-driver
$ ./_output/goofysplugin --endpoint tcp://127.0.0.1:10000 --nodeid CSINode -v=5 &
```
> Before running CSI driver, create "/etc/kubernetes/azure.json" file under testing server(it's better copy `azure.json` file from a k8s cluster with service principle configured correctly) and set `AZURE_CREDENTIAL_FILE` as following:
```
export set AZURE_CREDENTIAL_FILE=/etc/kubernetes/azure.json
```

#### 1. Get plugin info
```console
$ csc identity plugin-info --endpoint tcp://127.0.0.1:10000
"goofys.csi.azure.com"        "v0.1.0"
```

#### 2. Create an goofys volume
```console
$ csc controller new --endpoint tcp://127.0.0.1:10000 --cap 1,block CSIVolumeName  --req-bytes 2147483648 --params skuname=Standard_LRS
"andy-mg1160alpha3#fuse4ef4b1d0c53d41bc88f#csivolumename"       2147483648      "skuname"="Standard_LRS"
```

#### 3. Stage volume
```console
mkdir /tmp/staging-target-path
csc node stage --endpoint tcp://127.0.0.1:10000 --cap 1,block --staging-target-path /tmp/staging-target-path "andy-mg1160alpha3#fuse4ef4b1d0c53d41bc88f#csivolumename"
```

#### 4. Publish volume
```console
mkdir /tmp/target-path
csc node publish --endpoint tcp://127.0.0.1:10000 --cap 1,block --staging-target-path /tmp/staging-target-path --target-path /tmp/target-path "andy-mg1160alpha3#fuse4ef4b1d0c53d41bc88f#csivolumename"
```

#### 5. Unpublish volume
```console
csc node unpublish --endpoint tcp://127.0.0.1:10000 --target-path /tmp/target-path "andy-mg1160alpha3#fuse4ef4b1d0c53d41bc88f#csivolumename"
```

#### 6. Unstage volume
```console
csc node unstage --endpoint tcp://127.0.0.1:10000 --staging-target-path /tmp/staging-target-path "andy-mg1160alpha3#fuse4ef4b1d0c53d41bc88f#csivolumename"
```

#### 7. Delete goofys volume
```console
$ csc controller del --endpoint tcp://127.0.0.1:10000 CSIVolumeID
CSIVolumeID
```

#### 8. Validate volume capabilities
```console
$ csc controller validate-volume-capabilities --endpoint tcp://127.0.0.1:10000 --cap 1,block CSIVolumeID
CSIVolumeID  true
```

#### 9. Get NodeID
```console
$ csc node get-info --endpoint tcp://127.0.0.1:10000
CSINode
```

#### 10. Create snapshot
```console
$  csc controller create-snapshot
```

#### 11. Delete snapshot
```console
$  csc controller delete-snapshot
```
